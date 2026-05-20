import { randomUUID, randomBytes } from 'node:crypto';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import type { Role, User } from '@prisma/client';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { env } from '../../config/env';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';
import { sendVerificationEmail } from '../../config/email';

const ACCESS_TTL = '15m';
const REFRESH_TTL_SECONDS = 7 * 24 * 3600; // 7 jours
const MAX_FAILED_ATTEMPTS = 5;
const LOCK_TTL_SECONDS = 30 * 60; // 30 minutes

const ROLE_MAP: Record<'police' | 'citizen' | 'admin', Role> = {
  police: 'POLICE',
  citizen: 'CITOYEN',
  admin: 'ADMIN',
};

const PNC_DOMAIN = '@pnc.cg';

interface RefreshPayload {
  sub: string;
  jti: string;
}

function failKey(email: string): string {
  return `auth:fail:${email}`;
}
function lockKey(email: string): string {
  return `auth:lock:${email}`;
}
function refreshKey(userId: string, jti: string): string {
  return `refresh:${userId}:${jti}`;
}

function signAccessToken(user: User): string {
  return jwt.sign({ sub: user.id, role: user.role }, env.JWT_SECRET, {
    expiresIn: ACCESS_TTL,
  });
}

async function issueRefreshToken(userId: string): Promise<string> {
  const jti = randomUUID();
  const token = jwt.sign({ sub: userId, jti }, env.JWT_REFRESH_SECRET, {
    expiresIn: REFRESH_TTL_SECONDS,
  });
  await redis.set(refreshKey(userId, jti), '1', 'EX', REFRESH_TTL_SECONDS);
  return token;
}

function publicUser(user: User): {
  id: string;
  role: Role;
  name: string;
  badgeNumber: string | null;
  email: string;
  telephone: string | null;
  actif: boolean;
  mustChangePassword: boolean;
  emailVerified: boolean;
} {
  return {
    id: user.id,
    role: user.role,
    name: user.name,
    badgeNumber: user.badgeNumber,
    email: user.email,
    telephone: user.telephone,
    actif: user.actif,
    mustChangePassword: user.mustChangePassword,
    emailVerified: user.emailVerified,
  };
}

export async function login(
  email: string,
  pin: string,
  role: 'police' | 'citizen' | 'admin',
  ip: string | null,
): Promise<{ token: string; refreshToken: string; user: ReturnType<typeof publicUser> }> {
  // 0. Domaine @pnc.cg obligatoire pour les agents.
  if (role === 'police' && !email.toLowerCase().endsWith(PNC_DOMAIN)) {
    throw AppError.unauthorized(
      `Les comptes agents doivent utiliser une adresse ${PNC_DOMAIN}`,
      'INVALID_OFFICER_DOMAIN',
    );
  }

  // 1. Vérrou de compte (sans toucher la base).
  if (await redis.exists(lockKey(email))) {
    throw AppError.tooManyRequests(
      'Compte temporairement bloqué (trop de tentatives). Réessayez dans 30 minutes.',
      'ACCOUNT_LOCKED',
    );
  }

  const expectedRole = ROLE_MAP[role];
  const user = await prisma.user.findUnique({ where: { email } });

  const credentialsValid =
    user !== null &&
    user.actif &&
    user.role === expectedRole &&
    (await bcrypt.compare(pin, user.pinHash));

  if (!credentialsValid) {
    const attempts = await redis.incr(failKey(email));
    if (attempts === 1) {
      await redis.expire(failKey(email), LOCK_TTL_SECONDS);
    }
    if (attempts >= MAX_FAILED_ATTEMPTS) {
      await redis.set(lockKey(email), '1', 'EX', LOCK_TTL_SECONDS);
      await redis.del(failKey(email));
      throw AppError.tooManyRequests(
        'Compte bloqué 30 minutes après 5 tentatives échouées.',
        'ACCOUNT_LOCKED',
      );
    }
    throw AppError.unauthorized('Email, PIN ou rôle invalide', 'INVALID_CREDENTIALS');
  }

  await redis.del(failKey(email));

  // Email non vérifié : bloquer uniquement les CITOYEN (les agents sont créés par l'admin)
  if (user.role === 'CITOYEN' && !user.emailVerified) {
    throw AppError.forbidden(
      'Veuillez vérifier votre adresse email avant de vous connecter. '
      + 'Consultez votre boîte mail et cliquez sur le lien d\'activation.',
      'EMAIL_NOT_VERIFIED',
    );
  }

  const token = signAccessToken(user);
  const refreshToken = await issueRefreshToken(user.id);

  await audit(prisma, { userId: user.id, action: 'LOGIN', ip });

  return { token, refreshToken, user: publicUser(user) };
}

export async function refresh(
  refreshToken: string,
): Promise<{ token: string; refreshToken: string }> {
  let payload: RefreshPayload;
  try {
    payload = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET) as RefreshPayload;
  } catch {
    throw AppError.unauthorized('Refresh token invalide ou expiré', 'INVALID_REFRESH');
  }

  const exists = await redis.exists(refreshKey(payload.sub, payload.jti));
  if (!exists) {
    throw AppError.unauthorized('Refresh token révoqué', 'INVALID_REFRESH');
  }

  const user = await prisma.user.findUnique({ where: { id: payload.sub } });
  if (!user || !user.actif) {
    throw AppError.unauthorized('Compte introuvable ou désactivé', 'ACCOUNT_INACTIVE');
  }

  // Rotation : on révoque l'ancien refresh et on en émet un nouveau.
  await redis.del(refreshKey(payload.sub, payload.jti));
  const token = signAccessToken(user);
  const newRefresh = await issueRefreshToken(user.id);
  return { token, refreshToken: newRefresh };
}

export async function logout(refreshToken: string): Promise<void> {
  try {
    const payload = jwt.verify(
      refreshToken,
      env.JWT_REFRESH_SECRET,
    ) as RefreshPayload;
    await redis.del(refreshKey(payload.sub, payload.jti));
  } catch {
    // Token déjà invalide / expiré : logout idempotent.
  }
}

// Révoque TOUS les refresh tokens d'un utilisateur (ex : agent désactivé).
export async function revokeAllRefreshTokens(userId: string): Promise<void> {
  const keys = await redis.keys(`refresh:${userId}:*`);
  if (keys.length > 0) {
    await redis.del(...keys);
  }
}

// Inscription citoyen — auto-inscription publique (rôle CITOYEN uniquement).
export async function register(
  name: string,
  email: string,
  telephone: string,
  pin: string,
  ip: string | null,
): Promise<{
  token: string;
  refreshToken: string;
  user: ReturnType<typeof publicUser>;
  // En mode stub (pas de SMTP), le lien de vérification est retourné en clair
  // pour faciliter les tests. En production ce champ est absent.
  verificationUrl?: string;
}> {
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    throw AppError.conflict(
      'Un compte existe déjà avec cet email.',
      'EMAIL_ALREADY_USED',
    );
  }

  const pinHash = await bcrypt.hash(pin, 12);
  const emailVerificationToken = randomBytes(32).toString('hex');

  const user = await prisma.user.create({
    data: {
      email,
      name,
      telephone,
      pinHash,
      role: 'CITOYEN',
      emailVerified: false,
      emailVerificationToken,
    },
  });

  // Envoyer le mail de vérification (non bloquant)
  void sendVerificationEmail(email, name, emailVerificationToken).catch((err) => {
    console.error('[email] Échec envoi vérification :', err);
  });

  // Émettre les tokens JWT (l'accès au dashboard est bloqué par emailVerified=false)
  const token = signAccessToken(user);
  const refreshToken = await issueRefreshToken(user.id);

  await audit(prisma, { userId: user.id, action: 'REGISTER', ip });

  // En mode développement (pas de SMTP), inclure le lien dans la réponse API
  const isStub = !process.env['SMTP_HOST'];
  const verificationUrl = isStub
    ? `${env.BASE_URL}/api/auth/verify-email?token=${emailVerificationToken}`
    : undefined;

  return { token, refreshToken, user: publicUser(user), verificationUrl };
}

// Vérification de l'email via token
export async function verifyEmail(token: string): Promise<void> {
  const user = await prisma.user.findUnique({
    where: { emailVerificationToken: token },
  });
  if (!user) {
    throw AppError.badRequest(
      'Lien de vérification invalide ou déjà utilisé.',
      'INVALID_VERIFICATION_TOKEN',
    );
  }
  await prisma.user.update({
    where: { id: user.id },
    data: { emailVerified: true, emailVerificationToken: null },
  });
  await audit(prisma, { userId: user.id, action: 'EMAIL_VERIFIED', ip: null });
}

// Renvoi du mail de vérification
export async function resendVerification(
  email: string,
  ip: string | null,
): Promise<{ verificationUrl?: string }> {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || user.role !== 'CITOYEN' || user.emailVerified) return {};

  // Générer un nouveau token
  const emailVerificationToken = randomBytes(32).toString('hex');
  await prisma.user.update({
    where: { id: user.id },
    data: { emailVerificationToken },
  });

  void sendVerificationEmail(email, user.name, emailVerificationToken).catch(
    (err) => console.error('[email] Échec renvoi :', err),
  );

  await audit(prisma, { userId: user.id, action: 'VERIFICATION_RESENT', ip });

  const isStub = !process.env['SMTP_HOST'];
  return isStub
    ? { verificationUrl: `${env.BASE_URL}/api/auth/verify-email?token=${emailVerificationToken}` }
    : {};
}

export async function getMe(userId: string): Promise<ReturnType<typeof publicUser>> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
  }
  return publicUser(user);
}

// Changement de mot de passe (obligatoire au 1er login ou volontaire).
export async function changePassword(
  userId: string,
  currentPassword: string,
  newPassword: string,
  ip: string | null,
): Promise<ReturnType<typeof publicUser>> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const valid = await bcrypt.compare(currentPassword, user.pinHash);
  if (!valid) {
    throw AppError.unauthorized('Mot de passe actuel incorrect', 'INVALID_CREDENTIALS');
  }

  const pinHash = await bcrypt.hash(newPassword, 12);
  const updated = await prisma.user.update({
    where: { id: userId },
    data: { pinHash, mustChangePassword: false },
  });

  // Révoque tous les refresh tokens : force une nouvelle session propre.
  await revokeAllRefreshTokens(userId);

  await audit(prisma, { userId, action: 'PASSWORD_CHANGED', ip });

  return publicUser(updated);
}

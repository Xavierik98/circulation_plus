import { randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import type { Role, User } from '@prisma/client';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { env } from '../../config/env';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';
import { sendVerificationEmail, sendPasswordResetEmail } from '../../config/email';

const ACCESS_TTL = '15m';
const REFRESH_TTL_SECONDS = 7 * 24 * 3600; // 7 jours
const MAX_FAILED_ATTEMPTS = 3;
const LOCK_TTL_SECONDS = 15 * 60; // 15 minutes

// ── IP-level brute-force protection ───────────────────────────────────────────
const MAX_IP_FAILED_ATTEMPTS = 10;   // 10 failed logins from same IP → block
const IP_LOCK_TTL_SECONDS    = 30 * 60; // 30 minutes

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
function ipFailKey(ip: string): string {
  return `ip:fail:${ip}`;
}
function ipLockKey(ip: string): string {
  return `ip:lock:${ip}`;
}
function refreshKey(userId: string, jti: string): string {
  return `refresh:${userId}:${jti}`;
}

// ── Token de vérification email (JWT signé, valable 24 h — norme OWASP) ──────
const EMAIL_VERIFY_TTL = '24h';

function signEmailVerificationToken(userId: string): string {
  return jwt.sign(
    { sub: userId, purpose: 'email-verify' },
    env.JWT_SECRET,
    { expiresIn: EMAIL_VERIFY_TTL },
  );
}

/**
 * Vérifie et décode le token email.
 * Lève AppError avec code TOKEN_EXPIRED si expiré, INVALID_VERIFICATION_TOKEN sinon.
 */
function decodeEmailVerificationToken(token: string): string {
  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as { sub: string; purpose: string };
    if (payload.purpose !== 'email-verify') throw new Error('wrong purpose');
    return payload.sub; // userId
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      throw AppError.badRequest(
        'Le lien de vérification a expiré (validité : 24 h). '
        + 'Demandez un nouveau lien depuis l\'application.',
        'TOKEN_EXPIRED',
      );
    }
    throw AppError.badRequest(
      'Lien de vérification invalide ou déjà utilisé.',
      'INVALID_VERIFICATION_TOKEN',
    );
  }
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
  photoUrl: string | null;
  actif: boolean;
  mustChangePassword: boolean;
  emailVerified: boolean;
  gradeId: string | null;
  departementId: string | null;
  niveauHierarchique: string;
  commissariatId: string | null;
} {
  return {
    id: user.id,
    role: user.role,
    name: user.name,
    badgeNumber: user.badgeNumber,
    email: user.email,
    telephone: user.telephone,
    photoUrl: user.photoUrl ?? null,
    actif: user.actif,
    mustChangePassword: user.mustChangePassword,
    emailVerified: user.emailVerified,
    gradeId:            user.gradeId      ?? null,
    departementId:      user.departementId ?? null,
    niveauHierarchique: user.niveauHierarchique ?? 'AGENT',
    commissariatId:     user.commissariatId ?? null,
  };
}

export async function login(
  email: string,
  pin: string,
  role: 'police' | 'citizen' | 'admin',
  ip: string | null,
  userAgent?: string | null,
  lat?: number | null,
  lng?: number | null,
): Promise<{ token: string; refreshToken: string; user: ReturnType<typeof publicUser> }> {
  // 0. Domaine @pnc.cg obligatoire pour les agents.
  if (role === 'police' && !email.toLowerCase().endsWith(PNC_DOMAIN)) {
    throw AppError.unauthorized(
      `Les comptes agents doivent utiliser une adresse ${PNC_DOMAIN}`,
      'INVALID_OFFICER_DOMAIN',
    );
  }

  // 0b. Blocage IP (protection OWASP — credential stuffing / distributed brute-force).
  if (ip && await redis.exists(ipLockKey(ip))) {
    throw AppError.tooManyRequests(
      'Trop de tentatives échouées depuis votre réseau. Réessayez dans 30 minutes.',
      'IP_BLOCKED',
    );
  }

  // 1. Vérrou de compte (sans toucher la base).
  if (await redis.exists(lockKey(email))) {
    throw AppError.tooManyRequests(
      'Compte temporairement bloqué (trop de tentatives). Réessayez dans 15 minutes.',
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
    // Per-account brute force
    const attempts = await redis.incr(failKey(email));
    if (attempts === 1) {
      await redis.expire(failKey(email), LOCK_TTL_SECONDS);
    }
    if (attempts >= MAX_FAILED_ATTEMPTS) {
      await redis.set(lockKey(email), '1', 'EX', LOCK_TTL_SECONDS);
      await redis.del(failKey(email));
      throw AppError.tooManyRequests(
        'Compte bloqué 15 minutes après 3 tentatives échouées.',
        'ACCOUNT_LOCKED',
      );
    }

    // Per-IP brute force (credential stuffing protection)
    if (ip) {
      const ipAttempts = await redis.incr(ipFailKey(ip));
      if (ipAttempts === 1) {
        await redis.expire(ipFailKey(ip), IP_LOCK_TTL_SECONDS);
      }
      if (ipAttempts >= MAX_IP_FAILED_ATTEMPTS) {
        await redis.set(ipLockKey(ip), '1', 'EX', IP_LOCK_TTL_SECONDS);
        await redis.del(ipFailKey(ip));
        throw AppError.tooManyRequests(
          'IP bloquée 30 minutes — trop de tentatives échouées.',
          'IP_BLOCKED',
        );
      }
    }

    throw AppError.unauthorized('Email, PIN ou rôle invalide', 'INVALID_CREDENTIALS');
  }

  // On success: clear both email and IP fail counters
  await redis.del(failKey(email));
  if (ip) await redis.del(ipFailKey(ip));

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

  // Mise à jour GPS pour les agents (lastLat/Lng/SeenAt) si coordonnées fournies.
  if (lat != null && lng != null && user.role === 'POLICE') {
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLat: lat, lastLng: lng, lastSeenAt: new Date() },
    });
  }

  await audit(prisma, {
    userId: user.id,
    action: 'LOGIN',
    ip,
    userAgent: userAgent ?? null,
    details: {
      role: user.role,
      grade: (user as Record<string, unknown>)['grade'] ?? null,
      ...(lat != null && lng != null ? { lat, lng } : {}),
    },
  });

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

export async function logout(
  refreshToken: string,
  ip?: string | null,
  userAgent?: string | null,
): Promise<void> {
  try {
    const payload = jwt.verify(
      refreshToken,
      env.JWT_REFRESH_SECRET,
    ) as RefreshPayload;
    await redis.del(refreshKey(payload.sub, payload.jti));
    // Audit de déconnexion : heure + IP + User-Agent enregistrés
    await audit(prisma, {
      userId: payload.sub,
      action: 'LOGOUT',
      ip: ip ?? null,
      userAgent: userAgent ?? null,
    });
  } catch {
    // Token déjà invalide / expiré : logout idempotent.
  }
}

// Révoque TOUS les refresh tokens d'un utilisateur (ex : agent désactivé).
// Utilise SCAN au lieu de KEYS pour éviter de bloquer l'event loop Redis (O(N) global).
export async function revokeAllRefreshTokens(userId: string): Promise<void> {
  const pattern = `refresh:${userId}:*`;
  let cursor = '0';
  do {
    const [next, keys] = await redis.scan(cursor, 'MATCH', pattern, 'COUNT', '100');
    cursor = next;
    if (keys.length > 0) {
      await redis.del(...(keys as string[]));
    }
  } while (cursor !== '0');
}

// Inscription citoyen — auto-inscription publique (rôle CITOYEN uniquement).
export async function register(
  name: string,
  email: string,
  telephone: string | undefined,
  pin: string,
  ip: string | null,
  userAgent?: string | null,
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

  const pinHash = await bcrypt.hash(pin, 10);

  // En développement : email auto-vérifié → connexion immédiate sans lien.
  // En production : emailVerified=false → le citoyen doit cliquer sur le lien (24 h).
  const isDev = env.NODE_ENV !== 'production';

  // Créer d'abord l'utilisateur (on a besoin de son id pour signer le token)
  const user = await prisma.user.create({
    data: {
      email,
      name,
      telephone,
      pinHash,
      role: 'CITOYEN',
      emailVerified: isDev, // true en dev → connexion immédiate
      emailVerificationToken: null,
    },
  });

  // Générer le token JWT de vérification (signé, expire dans 24 h)
  const emailVerificationToken = signEmailVerificationToken(user.id);

  if (!isDev) {
    // Stocker le token dans la base (utilisé pour la révocation "déjà utilisé")
    await prisma.user.update({
      where: { id: user.id },
      data: { emailVerificationToken },
    });
  }

  // Émettre les tokens d'accès JWT
  const token = signAccessToken(user);
  const refreshToken = await issueRefreshToken(user.id);

  await audit(prisma, { userId: user.id, action: 'REGISTER', ip, userAgent: userAgent ?? null });

  const rawUrl = `${env.BASE_URL}/api/auth/verify-email?token=${encodeURIComponent(emailVerificationToken)}`;

  // Envoi de l'email en arrière-plan — ne bloque pas la réponse au client.
  setImmediate(() => {
    sendVerificationEmail(email, name, emailVerificationToken)
      .then(() => console.info(`[email] ✅ Mail envoyé à ${email}`))
      .catch((err: unknown) => console.warn(`[email] ⚠️ Échec envoi à ${email} :`, (err as Error).message));
  });

  // En mode stub (pas de SMTP), on retourne l'URL pour que le client puisse
  // vérifier manuellement ou afficher un message adapté.
  const verificationUrl = isDev ? undefined : rawUrl;

  return { token, refreshToken, user: publicUser(user), verificationUrl };
}

// Vérification de l'email via token JWT (expiration 24 h, OWASP)
export async function verifyEmail(token: string): Promise<void> {
  // 1. Décoder et vérifier la signature + expiration (lève TOKEN_EXPIRED si expiré)
  const userId = decodeEmailVerificationToken(token);

  // 2. Retrouver l'utilisateur et vérifier que le token n'a pas déjà été consommé
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw AppError.badRequest('Compte introuvable.', 'INVALID_VERIFICATION_TOKEN');
  }
  if (user.emailVerified) {
    // Déjà vérifié : idempotent (pas d'erreur, la page HTML dira succès)
    return;
  }
  if (user.emailVerificationToken !== token) {
    // Token révoqué (un renvoi plus récent a remplacé ce token)
    throw AppError.badRequest(
      'Ce lien a été remplacé par un lien plus récent.',
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

  // Générer un nouveau token JWT (24 h) — révoque implicitement l'ancien
  const emailVerificationToken = signEmailVerificationToken(user.id);
  await prisma.user.update({
    where: { id: user.id },
    data: { emailVerificationToken },
  });

  await audit(prisma, { userId: user.id, action: 'VERIFICATION_RESENT', ip });

  const rawUrl = `${env.BASE_URL}/api/auth/verify-email?token=${encodeURIComponent(emailVerificationToken)}`;
  let verificationUrl: string | undefined;

  try {
    await sendVerificationEmail(email, user.name, emailVerificationToken);
    if (env.NODE_ENV !== 'production') {
      verificationUrl = rawUrl;
    }
  } catch (err) {
    console.error('[email] Échec renvoi vérification :', err);
    verificationUrl = rawUrl;
  }

  return { verificationUrl };
}

export async function getMe(userId: string): Promise<ReturnType<typeof publicUser>> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
  }
  return publicUser(user);
}

// Mise à jour du profil (nom, téléphone).
export async function updateProfile(
  userId: string,
  name?: string,
  telephone?: string,
): Promise<ReturnType<typeof publicUser>> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const data: { name?: string; telephone?: string } = {};
  if (name !== undefined && name.trim().length > 0) data.name = name.trim();
  if (telephone !== undefined) data.telephone = telephone.trim();

  const updated = await prisma.user.update({ where: { id: userId }, data });
  return publicUser(updated);
}

// Upload de photo de profil (base64). Stockée sur R2 ou stub local.
export async function uploadProfilePhoto(
  userId: string,
  imageBase64: string,
  mimeType: string,
  adapters: import('../../adapters/types').Adapters,
): Promise<{ photoUrl: string }> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');

  const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (!allowed.includes(mimeType)) {
    throw AppError.badRequest('Format non supporté. Utilisez JPEG, PNG ou WebP.', 'INVALID_MIME_TYPE');
  }

  // Limiter à 2 Mo
  const bytes = Buffer.from(imageBase64, 'base64');
  if (bytes.length > 2 * 1024 * 1024) {
    throw AppError.badRequest('L\'image ne doit pas dépasser 2 Mo.', 'IMAGE_TOO_LARGE');
  }

  const ext = mimeType === 'image/png' ? 'png' : mimeType === 'image/webp' ? 'webp' : 'jpg';
  const key = `avatars/${userId}.${ext}`;

  await adapters.storage.upload(key, bytes, mimeType);
  const photoUrl = await adapters.storage.signedUrl(key, 365 * 24 * 3600); // 1 an

  await prisma.user.update({ where: { id: userId }, data: { photoUrl } });

  return { photoUrl };
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

// ── Récupération de mot de passe ─────────────────────────────────────────────
const RESET_TTL_SECONDS = 3600; // 1 heure

function resetKey(token: string): string {
  return `reset:${token}`;
}

// Étape 1 : génère un token de réinitialisation, envoie l'email ou SMS.
// Anti-enumeration : retourne toujours succès même si l'identifiant n'existe pas.
// identifier = email ou numéro de téléphone.
export async function forgotPassword(identifier: string): Promise<void> {
  const clean = identifier.toLowerCase().trim();
  const isPhone = /^[+\d\s()-]{7,}$/.test(clean) && !clean.includes('@');

  let user = null;
  if (isPhone) {
    // Recherche par téléphone (findFirst car telephone n'est pas unique)
    user = await prisma.user.findFirst({
      where: { telephone: { contains: clean.replace(/\s/g, '') }, actif: true },
    });
  } else {
    user = await prisma.user.findUnique({ where: { email: clean } });
  }
  if (!user || !user.actif) return; // silencieux — anti-enumeration

  const token = randomUUID();
  await redis.set(resetKey(token), user.id, 'EX', RESET_TTL_SECONDS);

  try {
    await sendPasswordResetEmail(user.email, user.name, token);
  } catch {
    // Email non bloquant — le token est déjà en Redis
  }
}

// Enregistrement du token FCM pour les notifications push.
export async function registerFcmToken(userId: string, fcmToken: string): Promise<void> {
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });
}

// Révocation du token FCM (déconnexion ou refus de notifs).
export async function revokeFcmToken(userId: string): Promise<void> {
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken: null },
  });
}

// Étape 2 : valide le token, change le mot de passe.
export async function resetPassword(token: string, newPassword: string): Promise<void> {
  const userId = await redis.get(resetKey(token));
  if (!userId) {
    throw AppError.badRequest('Lien expiré ou invalide. Recommencez.', 'RESET_TOKEN_INVALID');
  }

  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user || !user.actif) {
    throw AppError.notFound('Compte introuvable', 'USER_NOT_FOUND');
  }

  const pinHash = await bcrypt.hash(newPassword, 12);
  await prisma.user.update({
    where: { id: userId },
    data: { pinHash, mustChangePassword: false },
  });

  // Invalider le token + révoquer toutes les sessions
  await redis.del(resetKey(token));
  await revokeAllRefreshTokens(userId);

  await audit(prisma, { userId, action: 'PASSWORD_RESET', ip: null });
}

// ── Administration : débloquer une IP bannie ──────────────────────────────────
export async function unblockIp(
  ip: string,
  adminUserId: string,
): Promise<{ unblocked: boolean; wasBlocked: boolean }> {
  const lockK = ipLockKey(ip);
  const failK = ipFailKey(ip);
  const wasLocked  = (await redis.exists(lockK)) === 1;
  const hadFails   = (await redis.exists(failK)) === 1;
  if (wasLocked || hadFails) {
    await redis.del(lockK, failK);
  }
  await audit(prisma, {
    userId: adminUserId,
    action: 'ADMIN_UNBLOCK_IP',
    ip,
  });
  return { unblocked: true, wasBlocked: wasLocked };
}

// ── Administration : lister les IPs actuellement bloquées ────────────────────
export async function listBlockedIps(): Promise<
  Array<{ ip: string; ttlSeconds: number }>
> {
  // Scan des clés ip:lock:* dans Redis
  const keys: string[] = [];
  let cursor = '0';
  do {
    const [next, batch] = await redis.scan(cursor, 'MATCH', 'ip:lock:*', 'COUNT', 100);
    keys.push(...batch);
    cursor = next;
  } while (cursor !== '0');

  const result: Array<{ ip: string; ttlSeconds: number }> = [];
  for (const key of keys) {
    const ttl = await redis.ttl(key);
    const ip = key.replace('ip:lock:', '');
    result.push({ ip, ttlSeconds: ttl });
  }
  return result.sort((a, b) => b.ttlSeconds - a.ttlSeconds);
}

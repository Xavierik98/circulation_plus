import { randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import type { Role, User } from '@prisma/client';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { env } from '../../config/env';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';

const ACCESS_TTL = '15m';
const REFRESH_TTL_SECONDS = 7 * 24 * 3600; // 7 jours
const MAX_FAILED_ATTEMPTS = 5;
const LOCK_TTL_SECONDS = 30 * 60; // 30 minutes

const ROLE_MAP: Record<'police' | 'citizen' | 'admin', Role> = {
  police: 'POLICE',
  citizen: 'CITOYEN',
  admin: 'ADMIN',
};

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
} {
  return {
    id: user.id,
    role: user.role,
    name: user.name,
    badgeNumber: user.badgeNumber,
    email: user.email,
    telephone: user.telephone,
    actif: user.actif,
  };
}

export async function login(
  email: string,
  pin: string,
  role: 'police' | 'citizen' | 'admin',
  ip: string | null,
): Promise<{ token: string; refreshToken: string; user: ReturnType<typeof publicUser> }> {
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

export async function getMe(userId: string): Promise<ReturnType<typeof publicUser>> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
  }
  return publicUser(user);
}

import type { FastifyRequest } from 'fastify';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { prisma } from '../../config/database';
import { AppError } from '../errors/AppError';

export interface AccessTokenPayload {
  sub: string;
  role: string;
}

// preHandler : vérifie le JWT d'accès, charge l'utilisateur, refuse les comptes
// désactivés et injecte `request.user`.
export async function authenticate(request: FastifyRequest): Promise<void> {
  const header = request.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    throw AppError.unauthorized('Token d’authentification manquant', 'NO_TOKEN');
  }

  const token = header.slice('Bearer '.length).trim();

  let payload: AccessTokenPayload;
  try {
    payload = jwt.verify(token, env.JWT_SECRET) as AccessTokenPayload;
  } catch {
    throw AppError.unauthorized('Token invalide ou expiré', 'INVALID_TOKEN');
  }

  const user = await prisma.user.findUnique({ where: { id: payload.sub } });
  if (!user || !user.actif) {
    throw AppError.unauthorized('Compte introuvable ou désactivé', 'ACCOUNT_INACTIVE');
  }

  request.user = {
    id: user.id,
    role: user.role,
    name: user.name,
    badgeNumber: user.badgeNumber,
  };
}

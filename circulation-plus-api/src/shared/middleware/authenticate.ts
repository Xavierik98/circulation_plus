import type { FastifyRequest } from 'fastify';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { prisma } from '../../config/database';
import { AppError } from '../errors/AppError';

export interface AccessTokenPayload {
  sub: string;
  role: string;
}

// Routes accessibles même lorsque mustChangePassword = true.
// Tout autre endpoint retourne MUST_CHANGE_PASSWORD (403) pour forcer le changement.
const CHANGE_PASSWORD_ALLOWLIST = [
  '/api/auth/me',
  '/api/auth/change-password',
  '/api/auth/logout',
  '/api/auth/fcm-token',
];

// preHandler : vérifie le JWT d'accès, charge l'utilisateur, refuse les comptes
// désactivés et injecte `request.user` avec les infos hiérarchiques complètes.
export async function authenticate(request: FastifyRequest): Promise<void> {
  const header = request.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    throw AppError.unauthorized("Token d'authentification manquant", 'NO_TOKEN');
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
    mustChangePassword: user.mustChangePassword,
    niveauHierarchique: user.niveauHierarchique,
    commissariatId: user.commissariatId,
    departement: user.departement,
  };

  // Sécurité : forcer le changement de mot de passe avant tout accès.
  // Seules les routes de l'allowlist sont accessibles (consulter profil, changer MDP, déconnexion).
  if (user.mustChangePassword) {
    const url = request.url.split('?')[0] ?? '';
    const allowed = CHANGE_PASSWORD_ALLOWLIST.some((p) => url.startsWith(p));
    if (!allowed) {
      throw AppError.forbidden(
        "Vous devez changer votre mot de passe avant d'acceder a l'application. "
        + 'Rendez-vous sur /api/auth/change-password.',
        'MUST_CHANGE_PASSWORD',
      );
    }
  }
}

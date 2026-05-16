import type { FastifyRequest } from 'fastify';
import type { Role } from '@prisma/client';
import { AppError } from '../errors/AppError';

// Fabrique de preHandler : exige que `request.user` ait l'un des rôles autorisés.
// La sécurité au niveau ligne (RLS) reste appliquée dans chaque service.
export function authorize(...roles: Role[]) {
  return async function authorizeHandler(request: FastifyRequest): Promise<void> {
    if (!request.user) {
      throw AppError.unauthorized('Authentification requise', 'NO_TOKEN');
    }
    if (!roles.includes(request.user.role)) {
      throw AppError.forbidden(
        'Accès refusé : rôle insuffisant pour cette ressource',
        'FORBIDDEN',
      );
    }
  };
}

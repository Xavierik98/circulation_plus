import type { Role, NiveauHierarchique } from '@prisma/client';
import type { Adapters } from '../adapters/types';

export interface AuthUser {
  id: string;
  role: Role;
  name: string;
  badgeNumber: string | null;
  mustChangePassword: boolean;
  niveauHierarchique: NiveauHierarchique;
  commissariatId: string | null;
  departementId: string | null;
  directionNationaleId: string | null;
  directionDepartementaleId: string | null;
}

declare module 'fastify' {
  interface FastifyRequest {
    user?: AuthUser;
  }

  interface FastifyInstance {
    adapters: Adapters;
  }
}

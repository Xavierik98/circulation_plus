import type { Role, NiveauHierarchique, Departement } from '@prisma/client';
import type { Adapters } from '../adapters/types';

export interface AuthUser {
  id: string;
  role: Role;
  name: string;
  badgeNumber: string | null;
  mustChangePassword: boolean;
  niveauHierarchique: NiveauHierarchique;
  commissariatId: string | null;
  departement: Departement | null;
}

declare module 'fastify' {
  interface FastifyRequest {
    user?: AuthUser;
  }

  interface FastifyInstance {
    adapters: Adapters;
  }
}

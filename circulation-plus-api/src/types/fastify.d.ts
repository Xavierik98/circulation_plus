import type { Role } from '@prisma/client';
import type { Adapters } from '../adapters/types';

export interface AuthUser {
  id: string;
  role: Role;
  name: string;
  badgeNumber: string | null;
}

declare module 'fastify' {
  interface FastifyRequest {
    user?: AuthUser;
  }

  interface FastifyInstance {
    adapters: Adapters;
  }
}

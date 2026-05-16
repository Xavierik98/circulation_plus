import { PrismaClient } from '@prisma/client';
import { isProduction } from './env';

// Singleton Prisma — réutilisé en dev (hot reload) et en tests.
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: isProduction ? ['error'] : ['error', 'warn'],
  });

if (!isProduction) {
  globalForPrisma.prisma = prisma;
}

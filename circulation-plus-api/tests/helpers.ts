import bcrypt from 'bcryptjs';
import type { Role } from '@prisma/client';
import { buildApp } from '../src/app';
import { prisma } from '../src/config/database';

export async function makeApp() {
  const app = await buildApp();
  await app.ready();
  return app;
}

export async function createUser(params: {
  email: string;
  pin?: string;
  role: Role;
  name?: string;
  badgeNumber?: string;
  telephone?: string;
}) {
  const pinHash = await bcrypt.hash(params.pin ?? '0000', 12);
  return prisma.user.create({
    data: {
      email: params.email,
      pinHash,
      role: params.role,
      name: params.name ?? params.email,
      badgeNumber: params.badgeNumber ?? null,
      telephone: params.telephone ?? null,
    },
  });
}

export async function createInfractionType(params?: {
  code?: string;
  montantBase?: number;
  convocationObligatoire?: boolean;
}) {
  return prisma.infractionType.create({
    data: {
      code: params?.code ?? 'TEST-1',
      libelle: 'Infraction de test',
      montantBase: params?.montantBase ?? 15000,
      convocationObligatoire: params?.convocationObligatoire ?? false,
    },
  });
}

type InjectableApp = Awaited<ReturnType<typeof makeApp>>;

export async function login(
  app: InjectableApp,
  email: string,
  pin: string,
  role: 'police' | 'citizen' | 'admin',
): Promise<{ token: string; refreshToken: string; status: number; body: any }> {
  const res = await app.inject({
    method: 'POST',
    url: '/api/auth/login',
    payload: { email, pin, role },
  });
  const body = res.json();
  return {
    status: res.statusCode,
    body,
    token: body?.data?.token ?? '',
    refreshToken: body?.data?.refreshToken ?? '',
  };
}

export function authHeader(token: string): { authorization: string } {
  return { authorization: `Bearer ${token}` };
}

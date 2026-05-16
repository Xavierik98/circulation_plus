import bcrypt from 'bcryptjs';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';
import { revokeAllRefreshTokens } from '../auth/auth.service';
import type { CreateOfficerBody, UpdateOfficerBody } from './officers.schema';

const PIN_ROUNDS = 12;

export interface OfficerWithStats {
  id: string;
  email: string;
  name: string;
  badgeNumber: string | null;
  telephone: string | null;
  actif: boolean;
  createdAt: Date;
  totalFines: number;
  montantCollecte: number;
}

// Liste paginée des agents avec leurs statistiques (nb de fines, montant collecté).
export async function listOfficers(params: {
  page: number;
  limit: number;
  search?: string;
}): Promise<{ items: OfficerWithStats[]; total: number }> {
  const where: Prisma.UserWhereInput = { role: 'POLICE' };
  if (params.search) {
    where.OR = [
      { name: { contains: params.search, mode: 'insensitive' } },
      { email: { contains: params.search, mode: 'insensitive' } },
      { badgeNumber: { contains: params.search, mode: 'insensitive' } },
    ];
  }

  const [officers, total] = await Promise.all([
    prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (params.page - 1) * params.limit,
      take: params.limit,
    }),
    prisma.user.count({ where }),
  ]);

  const items = await Promise.all(
    officers.map(async (officer): Promise<OfficerWithStats> => {
      const [totalFines, collected] = await Promise.all([
        prisma.fine.count({ where: { officerId: officer.id } }),
        prisma.fine.aggregate({
          where: { officerId: officer.id, status: 'PAID' },
          _sum: { montantTotal: true },
        }),
      ]);
      return {
        id: officer.id,
        email: officer.email,
        name: officer.name,
        badgeNumber: officer.badgeNumber,
        telephone: officer.telephone,
        actif: officer.actif,
        createdAt: officer.createdAt,
        totalFines,
        montantCollecte: collected._sum.montantTotal ?? 0,
      };
    }),
  );

  return { items, total };
}

export async function createOfficer(body: CreateOfficerBody, actorId: string) {
  const existing = await prisma.user.findFirst({
    where: { OR: [{ email: body.email }, { badgeNumber: body.badgeNumber }] },
  });
  if (existing) {
    throw AppError.conflict(
      'Un agent avec cet email ou ce matricule existe déjà',
      'OFFICER_EXISTS',
    );
  }

  const pinHash = await bcrypt.hash(body.pin, PIN_ROUNDS);
  const officer = await prisma.user.create({
    data: {
      email: body.email,
      pinHash,
      name: body.name,
      badgeNumber: body.badgeNumber,
      telephone: body.telephone,
      role: 'POLICE',
    },
  });

  await audit(prisma, {
    userId: actorId,
    action: 'OFFICER_CREATED',
    details: { officerId: officer.id, badgeNumber: officer.badgeNumber },
  });

  return {
    id: officer.id,
    email: officer.email,
    name: officer.name,
    badgeNumber: officer.badgeNumber,
    telephone: officer.telephone,
    actif: officer.actif,
  };
}

export async function updateOfficer(
  id: string,
  body: UpdateOfficerBody,
  actorId: string,
) {
  const officer = await prisma.user.findUnique({ where: { id } });
  if (!officer || officer.role !== 'POLICE') {
    throw AppError.notFound('Agent introuvable', 'OFFICER_NOT_FOUND');
  }

  const data: Prisma.UserUpdateInput = {};
  if (body.email !== undefined) data.email = body.email;
  if (body.name !== undefined) data.name = body.name;
  if (body.badgeNumber !== undefined) data.badgeNumber = body.badgeNumber;
  if (body.telephone !== undefined) data.telephone = body.telephone;
  if (body.actif !== undefined) data.actif = body.actif;
  if (body.pin !== undefined) data.pinHash = await bcrypt.hash(body.pin, PIN_ROUNDS);

  const updated = await prisma.user.update({ where: { id }, data });

  // Désactivation => révocation de TOUS les refresh tokens de cet agent.
  if (body.actif === false) {
    await revokeAllRefreshTokens(id);
  }

  await audit(prisma, {
    userId: actorId,
    action: 'OFFICER_MODIFIED',
    details: { officerId: id, changes: Object.keys(body) },
  });

  return {
    id: updated.id,
    email: updated.email,
    name: updated.name,
    badgeNumber: updated.badgeNumber,
    telephone: updated.telephone,
    actif: updated.actif,
  };
}

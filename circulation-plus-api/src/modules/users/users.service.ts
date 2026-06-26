import type { Role, Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';

// ── Types ────────────────────────────────────────────────────────────────────

export interface UserListItem {
  id: string;
  email: string;
  name: string;
  role: Role;
  actif: boolean;
  telephone: string | null;
  createdAt: Date;
  // Champs POLICE uniquement
  badgeNumber: string | null;
  // Champs CITOYEN uniquement
  totalAmendes: number;
}

export interface UserDetail extends UserListItem {
  mustChangePassword: boolean;
  emailVerified: boolean;
  photoUrl: string | null;
  lastSeenAt: Date | null;
}

export interface ListUsersParams {
  role?: Role;
  actif?: boolean;
  search?: string;
  page: number;
  limit: number;
}

// ── Liste paginée ─────────────────────────────────────────────────────────────

export async function listUsers(
  params: ListUsersParams,
): Promise<{ items: UserListItem[]; total: number }> {
  const where: Prisma.UserWhereInput = {};

  if (params.role !== undefined) {
    where.role = params.role;
  }
  if (params.actif !== undefined) {
    where.actif = params.actif;
  }
  if (params.search) {
    where.OR = [
      { email:  { contains: params.search, mode: 'insensitive' } },
      { name:   { contains: params.search, mode: 'insensitive' } },
    ];
  }

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (params.page - 1) * params.limit,
      take: params.limit,
      select: {
        id:          true,
        email:       true,
        name:        true,
        role:        true,
        actif:       true,
        telephone:   true,
        badgeNumber: true,
        createdAt:   true,
      },
    }),
    prisma.user.count({ where }),
  ]);

  // Comptage des amendes CITOYEN en batch
  const citizenIds = users
    .filter((u) => u.role === 'CITOYEN')
    .map((u) => u.id);

  const amendesCounts: Record<string, number> = {};
  if (citizenIds.length > 0) {
    const counts = await prisma.fine.groupBy({
      by: ['citizenId'],
      where: { citizenId: { in: citizenIds } },
      _count: { _all: true },
    });
    for (const row of counts) {
      if (row.citizenId) amendesCounts[row.citizenId] = row._count._all;
    }
  }

  const items: UserListItem[] = users.map((u) => ({
    id:           u.id,
    email:        u.email,
    name:         u.name,
    role:         u.role,
    actif:        u.actif,
    telephone:    u.telephone,
    badgeNumber:  u.badgeNumber,
    createdAt:    u.createdAt,
    totalAmendes: amendesCounts[u.id] ?? 0,
  }));

  return { items, total };
}

// ── Détail d'un utilisateur ───────────────────────────────────────────────────

export async function getUserById(id: string): Promise<UserDetail> {
  // findUnique sans select : on charge le User complet pour accéder à tous ses champs
  // (même pattern que officers.service.ts — le client Prisma généré localement est
  // obsolète, les champs existent bien dans le schéma et en production).
  const user = await prisma.user.findUnique({ where: { id } });

  if (!user) {
    throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  let totalAmendes = 0;
  if (user.role === 'CITOYEN') {
    totalAmendes = await prisma.fine.count({ where: { citizenId: id } });
  }

  return {
    id:                 user.id,
    email:              user.email,
    name:               user.name,
    role:               user.role,
    actif:              user.actif,
    telephone:          user.telephone,
    badgeNumber:        user.badgeNumber,
    mustChangePassword: user.mustChangePassword,
    emailVerified:      user.emailVerified,
    photoUrl:           user.photoUrl,
    lastSeenAt:         user.lastSeenAt,
    createdAt:          user.createdAt,
    totalAmendes,
  };
}

// ── Activer / Suspendre un compte ─────────────────────────────────────────────

export async function setUserStatus(
  id: string,
  actif: boolean,
  actorId: string,
): Promise<{ id: string; actif: boolean }> {
  const user = await prisma.user.findUnique({ where: { id } });
  if (!user) {
    throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  if (user.actif === actif) {
    const msg = actif ? 'Ce compte est déjà actif' : 'Ce compte est déjà suspendu';
    throw AppError.badRequest(msg, actif ? 'ALREADY_ACTIVE' : 'ALREADY_SUSPENDED');
  }

  await prisma.user.update({ where: { id }, data: { actif } });

  // Révoquer les refresh tokens si suspension
  if (!actif) {
    await prisma.auditLog.create({
      data: {
        userId:  actorId,
        action:  'USER_SUSPENDED',
        details: { targetUserId: id, role: user.role, name: user.name },
      },
    });
  } else {
    await audit(prisma, {
      userId:  actorId,
      action:  'USER_ACTIVATED',
      details: { targetUserId: id, role: user.role, name: user.name },
    });
  }

  return { id, actif };
}

// ── Suppression d'un utilisateur ──────────────────────────────────────────────

export async function deleteUser(
  id: string,
  actorId: string,
): Promise<void> {
  const user = await prisma.user.findUnique({ where: { id } });
  if (!user) {
    throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  if (user.role === 'ADMIN') {
    throw AppError.forbidden(
      'Impossible de supprimer un compte ADMIN via cette route',
      'CANNOT_DELETE_ADMIN',
    );
  }

  // Sécurité : un admin ne peut pas se supprimer lui-même
  if (id === actorId) {
    throw AppError.forbidden(
      'Vous ne pouvez pas supprimer votre propre compte',
      'CANNOT_DELETE_SELF',
    );
  }

  await audit(prisma, {
    userId:  actorId,
    action:  'USER_DELETED',
    details: { deletedUserId: id, role: user.role, email: user.email, name: user.name },
  });

  await prisma.user.delete({ where: { id } });
}

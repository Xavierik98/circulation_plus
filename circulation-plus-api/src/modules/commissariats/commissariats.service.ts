import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';
import type { CreateCommissariatBody, UpdateCommissariatBody } from './commissariats.schema';

// ── Liste paginee ──────────────────────────────────────────────────────────────
export async function listCommissariats(params: {
  departement?: string;
  parentId?: string;
  actif?: boolean;
  page: number;
  limit: number;
}) {
  const where = {
    ...(params.departement ? { departement: params.departement as never } : {}),
    ...(params.parentId !== undefined ? { parentId: params.parentId } : {}),
    ...(params.actif !== undefined ? { actif: params.actif } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.commissariat.findMany({
      where,
      orderBy: [{ departement: 'asc' }, { nom: 'asc' }],
      skip: (params.page - 1) * params.limit,
      take: params.limit,
      include: {
        parent: { select: { id: true, nom: true, code: true } },
        _count: { select: { enfants: true, agents: true } },
      },
    }),
    prisma.commissariat.count({ where }),
  ]);

  return {
    items: items.map((c) => ({
      id: c.id,
      nom: c.nom,
      code: c.code,
      departement: c.departement,
      adresse: c.adresse,
      parentId: c.parentId,
      parentNom: c.parent?.nom ?? null,
      lat: c.lat,
      lng: c.lng,
      actif: c.actif,
      createdAt: c.createdAt,
      nbEnfants: c._count.enfants,
      nbAgents: c._count.agents,
    })),
    total,
  };
}

// ── Detail ─────────────────────────────────────────────────────────────────────
export async function getCommissariat(id: string) {
  const c = await prisma.commissariat.findUnique({
    where: { id },
    include: {
      parent: { select: { id: true, nom: true, code: true } },
      enfants: {
        where: { actif: true },
        select: { id: true, nom: true, code: true, departement: true },
        orderBy: { nom: 'asc' },
      },
      _count: { select: { agents: true } },
    },
  });
  if (!c) throw AppError.notFound('Commissariat introuvable', 'COMMISSARIAT_NOT_FOUND');

  return {
    id: c.id,
    nom: c.nom,
    code: c.code,
    departement: c.departement,
    adresse: c.adresse,
    parentId: c.parentId,
    parent: c.parent,
    enfants: c.enfants,
    lat: c.lat,
    lng: c.lng,
    actif: c.actif,
    createdAt: c.createdAt,
    nbAgents: c._count.agents,
  };
}

// ── Creation ───────────────────────────────────────────────────────────────────
export async function createCommissariat(body: CreateCommissariatBody, actorId: string) {
  // Verifier doublon de code
  const existing = await prisma.commissariat.findUnique({ where: { code: body.code } });
  if (existing) {
    throw AppError.conflict(
      `Un commissariat avec le code "${body.code}" existe deja`,
      'COMMISSARIAT_CODE_EXISTS',
    );
  }

  // Verifier que le parent existe si fourni
  if (body.parentId) {
    const parent = await prisma.commissariat.findUnique({ where: { id: body.parentId } });
    if (!parent) {
      throw AppError.badRequest('Commissariat parent introuvable', 'PARENT_NOT_FOUND');
    }
    if (parent.departement !== body.departement) {
      throw AppError.badRequest(
        'Le commissariat enfant doit etre dans le meme departement que son parent',
        'DEPARTMENT_MISMATCH',
      );
    }
  }

  const commissariat = await prisma.commissariat.create({
    data: {
      nom: body.nom,
      code: body.code,
      departement: body.departement as never,
      parentId: body.parentId ?? null,
      lat: body.lat ?? null,
      lng: body.lng ?? null,
      adresse: body.adresse ?? null,
      actif: true,
    },
  });

  await audit(prisma, {
    userId: actorId,
    action: 'COMMISSARIAT_CREATED',
    details: { commissariatId: commissariat.id, code: commissariat.code },
  });

  return commissariat;
}

// ── Modification ───────────────────────────────────────────────────────────────
export async function updateCommissariat(
  id: string,
  body: UpdateCommissariatBody,
  actorId: string,
) {
  const existing = await prisma.commissariat.findUnique({ where: { id } });
  if (!existing) throw AppError.notFound('Commissariat introuvable', 'COMMISSARIAT_NOT_FOUND');

  const updated = await prisma.commissariat.update({
    where: { id },
    data: {
      ...(body.nom !== undefined ? { nom: body.nom } : {}),
      ...(body.lat !== undefined ? { lat: body.lat } : {}),
      ...(body.lng !== undefined ? { lng: body.lng } : {}),
      ...(body.adresse !== undefined ? { adresse: body.adresse } : {}),
      ...(body.actif !== undefined ? { actif: body.actif } : {}),
    },
  });

  await audit(prisma, {
    userId: actorId,
    action: 'COMMISSARIAT_UPDATED',
    details: { commissariatId: id, changes: Object.keys(body) },
  });

  return updated;
}

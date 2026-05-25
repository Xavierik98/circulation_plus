import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';
import type { CreateCommissariatBody, UpdateCommissariatBody } from './commissariats.schema';

// ── Liste paginée ──────────────────────────────────────────────────────────────
export async function listCommissariats(params: {
  departement?: string;    // code string (ex: BRAZZAVILLE)
  actif?: boolean;
  page: number;
  limit: number;
}) {
  // Résoudre departement code → departementId
  let departementId: string | undefined;
  if (params.departement) {
    const dept = await prisma.departement.findUnique({ where: { code: params.departement } });
    if (!dept) {
      return { items: [], total: 0 };
    }
    departementId = dept.id;
  }

  const where = {
    ...(departementId !== undefined ? { departementId } : {}),
    ...(params.actif  !== undefined ? { actif: params.actif } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.commissariat.findMany({
      where,
      orderBy: [{ departementId: 'asc' }, { nom: 'asc' }],
      skip: (params.page - 1) * params.limit,
      take: params.limit,
      include: {
        departement:            { select: { id: true, code: true, nom: true } },
        directionDepartementale:{ select: { id: true, code: true, nom: true } },
        _count: { select: { unites: true, agents: true } },
      },
    }),
    prisma.commissariat.count({ where }),
  ]);

  return {
    items: items.map((c) => ({
      id:                       c.id,
      nom:                      c.nom,
      code:                     c.code,
      departementCode:          c.departement?.code  ?? null,
      departementNom:           c.departement?.nom   ?? null,
      departementId:            c.departementId,
      directionDepartementaleId:c.directionDepartementaleId,
      directionDepartementaleNom: c.directionDepartementale?.nom ?? null,
      adresse:                  c.adresse,
      lat:                      c.lat,
      lng:                      c.lng,
      actif:                    c.actif,
      createdAt:                c.createdAt,
      nbUnites:                 c._count.unites,
      nbAgents:                 c._count.agents,
    })),
    total,
  };
}

// ── Détail ─────────────────────────────────────────────────────────────────────
export async function getCommissariat(id: string) {
  const c = await prisma.commissariat.findUnique({
    where: { id },
    include: {
      departement:             { select: { id: true, code: true, nom: true } },
      directionDepartementale: { select: { id: true, code: true, nom: true } },
      unites: {
        where: { actif: true },
        select: { id: true, nom: true, code: true, sigle: true },
        orderBy: { nom: 'asc' },
      },
      _count: { select: { agents: true } },
    },
  });
  if (!c) throw AppError.notFound('Commissariat introuvable', 'COMMISSARIAT_NOT_FOUND');

  return {
    id:                        c.id,
    nom:                       c.nom,
    code:                      c.code,
    departementCode:           c.departement?.code  ?? null,
    departementNom:            c.departement?.nom   ?? null,
    departementId:             c.departementId,
    directionDepartementaleId: c.directionDepartementaleId,
    directionDepartementale:   c.directionDepartementale,
    unites:                    c.unites,
    // alias "enfants" pour rétrocompatibilité client Flutter
    enfants:                   c.unites,
    adresse:                   c.adresse,
    lat:                       c.lat,
    lng:                       c.lng,
    actif:                     c.actif,
    createdAt:                 c.createdAt,
    nbAgents:                  c._count.agents,
  };
}

// ── Création ───────────────────────────────────────────────────────────────────
export async function createCommissariat(body: CreateCommissariatBody, actorId: string) {
  // Vérifier doublon de code
  const existing = await prisma.commissariat.findUnique({ where: { code: body.code } });
  if (existing) {
    throw AppError.conflict(
      `Un commissariat avec le code "${body.code}" existe déjà`,
      'COMMISSARIAT_CODE_EXISTS',
    );
  }

  // Résoudre departement code → departementId
  const dept = await prisma.departement.findUnique({ where: { code: body.departement } });
  if (!dept) {
    throw AppError.badRequest(
      `Département "${body.departement}" introuvable`,
      'DEPT_NOT_FOUND',
    );
  }

  // Vérifier DD si fournie
  if (body.directionDepartementaleId) {
    const dd = await prisma.directionDepartementale.findUnique({
      where: { id: body.directionDepartementaleId },
    });
    if (!dd) {
      throw AppError.badRequest('Direction départementale introuvable', 'DD_NOT_FOUND');
    }
    if (dd.departementId !== dept.id) {
      throw AppError.badRequest(
        'La direction départementale doit appartenir au même département',
        'DEPARTMENT_MISMATCH',
      );
    }
  }

  const commissariat = await prisma.commissariat.create({
    data: {
      nom:                      body.nom,
      code:                     body.code,
      departementId:            dept.id,
      directionDepartementaleId: body.directionDepartementaleId ?? null,
      lat:                      body.lat     ?? null,
      lng:                      body.lng     ?? null,
      adresse:                  body.adresse ?? null,
      actif:                    true,
    },
    include: {
      departement: { select: { code: true, nom: true } },
    },
  });

  await audit(prisma, {
    userId: actorId,
    action: 'COMMISSARIAT_CREATED',
    details: { commissariatId: commissariat.id, code: commissariat.code },
  });

  return {
    id:              commissariat.id,
    nom:             commissariat.nom,
    code:            commissariat.code,
    departementCode: commissariat.departement?.code ?? null,
    departementId:   commissariat.departementId,
    adresse:         commissariat.adresse,
    lat:             commissariat.lat,
    lng:             commissariat.lng,
    actif:           commissariat.actif,
    createdAt:       commissariat.createdAt,
  };
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
      ...(body.nom     !== undefined ? { nom:     body.nom     } : {}),
      ...(body.lat     !== undefined ? { lat:     body.lat     } : {}),
      ...(body.lng     !== undefined ? { lng:     body.lng     } : {}),
      ...(body.adresse !== undefined ? { adresse: body.adresse } : {}),
      ...(body.actif   !== undefined ? { actif:   body.actif   } : {}),
    },
  });

  await audit(prisma, {
    userId: actorId,
    action: 'COMMISSARIAT_UPDATED',
    details: { commissariatId: id, changes: Object.keys(body) },
  });

  return updated;
}

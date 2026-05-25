import bcrypt from 'bcryptjs';
import { randomBytes } from 'node:crypto';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';
import { revokeAllRefreshTokens } from '../auth/auth.service';
import { sendCredentialsEmail } from '../../config/email';
import type { CreateOfficerBody, UpdateOfficerBody } from './officers.schema';
import type { AuthUser } from '../../types/fastify';

const PIN_ROUNDS = 12;
const PNC_DOMAIN = '@pnc.cg';

export interface OfficerWithStats {
  id: string;
  email: string;
  name: string;
  badgeNumber: string | null;
  telephone: string | null;
  actif: boolean;
  onDuty: boolean;
  mustChangePassword: boolean;
  createdAt: Date;
  lastLat: number | null;
  lastLng: number | null;
  lastSeenAt: Date | null;
  totalFines: number;
  montantCollecte: number;
  // Champs hiérarchiques
  gradeCode: string | null;
  gradeNom: string | null;
  niveauHierarchique: string;
  commissariatId: string | null;
  departementCode: string | null;
}

// ── Génère un mot de passe temporaire fort (ISO 27001) ─────────────────────
function generateTempPassword(): string {
  const upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lower   = 'abcdefghjkmnpqrstuvwxyz';
  const digits  = '23456789';
  const special = '!@#$%&*?';

  const pick = (s: string) => s[randomBytes(1)[0]! % s.length]!;
  const base = [pick(upper), pick(upper), pick(lower), pick(lower),
                pick(digits), pick(digits), pick(special), pick(special)];
  const all = upper + lower + digits + special;
  while (base.length < 12) base.push(pick(all));
  for (let i = base.length - 1; i > 0; i--) {
    const j = randomBytes(1)[0]! % (i + 1);
    [base[i], base[j]] = [base[j]!, base[i]!];
  }
  return base.join('');
}

// ── Résoud le filtre hiérarchique selon le niveau de l'admin ────────────────
async function buildHierarchyFilter(
  admin: AuthUser,
): Promise<Prisma.UserWhereInput> {
  const { niveauHierarchique, commissariatId, departementId, directionDepartementaleId } = admin;

  switch (niveauHierarchique) {
    case 'DIRECTION_GENERALE':
    case 'DIRECTION_NATIONALE':
      return {}; // Voit tout

    case 'DIRECTION_DEPT':
      if (departementId) {
        return { departementId };
      }
      return {};

    case 'COMMISSARIAT_CENTRAL': {
      // Voit tous les commissariats de sa direction départementale
      const ddId = directionDepartementaleId;
      if (ddId) {
        const comms = await prisma.commissariat.findMany({
          where: { directionDepartementaleId: ddId, actif: true },
          select: { id: true },
        });
        return { commissariatId: { in: comms.map((c) => c.id) } };
      }
      if (commissariatId) return { commissariatId };
      return {};
    }

    case 'COMMISSARIAT_ZONE':
    case 'AGENT':
    default:
      if (commissariatId) {
        return { commissariatId };
      }
      return {};
  }
}

// ── Include Prisma pour les retours enrichis ────────────────────────────────
const OFFICER_INCLUDE = {
  grade:      { select: { code: true, nom: true } },
  departement: { select: { code: true, nom: true } },
} satisfies Prisma.UserInclude;

// ── Liste paginée ──────────────────────────────────────────────────────────
export async function listOfficers(
  params: { page: number; limit: number; search?: string },
  admin: AuthUser,
): Promise<{ items: OfficerWithStats[]; total: number }> {
  const hierarchyFilter = await buildHierarchyFilter(admin);
  const where: Prisma.UserWhereInput = { role: 'POLICE', ...hierarchyFilter };
  if (params.search) {
    where.OR = [
      { name:        { contains: params.search, mode: 'insensitive' } },
      { email:       { contains: params.search, mode: 'insensitive' } },
      { badgeNumber: { contains: params.search, mode: 'insensitive' } },
    ];
  }

  const [officers, total] = await Promise.all([
    prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (params.page - 1) * params.limit,
      take: params.limit,
      include: OFFICER_INCLUDE,
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
        id:                 officer.id,
        email:              officer.email,
        name:               officer.name,
        badgeNumber:        officer.badgeNumber,
        telephone:          officer.telephone,
        actif:              officer.actif,
        onDuty:             officer.onDuty,
        mustChangePassword: officer.mustChangePassword,
        createdAt:          officer.createdAt,
        lastLat:            officer.lastLat  ? Number(officer.lastLat)  : null,
        lastLng:            officer.lastLng  ? Number(officer.lastLng)  : null,
        lastSeenAt:         officer.lastSeenAt,
        totalFines,
        montantCollecte:    collected._sum.montantTotal ?? 0,
        gradeCode:          officer.grade?.code    ?? null,
        gradeNom:           officer.grade?.nom     ?? null,
        niveauHierarchique: officer.niveauHierarchique,
        commissariatId:     officer.commissariatId ?? null,
        departementCode:    officer.departement?.code ?? null,
      };
    }),
  );

  return { items, total };
}

// ── Résout grade code → gradeId ─────────────────────────────────────────────
async function resolveGradeId(gradeCode: string | undefined): Promise<string | undefined> {
  if (!gradeCode) return undefined;
  const grade = await prisma.grade.findUnique({ where: { code: gradeCode } });
  if (!grade) throw AppError.badRequest(`Grade "${gradeCode}" introuvable`, 'GRADE_NOT_FOUND');
  return grade.id;
}

// ── Résout departement code → departementId ─────────────────────────────────
async function resolveDepartementId(deptCode: string | undefined): Promise<string | undefined> {
  if (!deptCode) return undefined;
  const dept = await prisma.departement.findUnique({ where: { code: deptCode } });
  if (!dept) throw AppError.badRequest(`Département "${deptCode}" introuvable`, 'DEPT_NOT_FOUND');
  return dept.id;
}

// ── Création manuelle d'un agent ──────────────────────────────────────────
export async function createOfficer(body: CreateOfficerBody, actorId: string) {
  if (!body.email.toLowerCase().endsWith(PNC_DOMAIN)) {
    throw AppError.badRequest(
      `L'email de l'agent doit se terminer par ${PNC_DOMAIN}`,
      'INVALID_OFFICER_DOMAIN',
    );
  }

  const existing = await prisma.user.findFirst({
    where: { OR: [{ email: body.email }, { badgeNumber: body.badgeNumber }] },
  });
  if (existing) {
    throw AppError.conflict(
      'Un agent avec cet email ou ce matricule existe déjà',
      'OFFICER_EXISTS',
    );
  }

  const [gradeId, departementId] = await Promise.all([
    resolveGradeId(body.grade),
    resolveDepartementId(body.departement),
  ]);

  const pinHash = await bcrypt.hash(body.pin, PIN_ROUNDS);
  const officer = await prisma.user.create({
    data: {
      email:              body.email,
      pinHash,
      name:               body.name,
      badgeNumber:        body.badgeNumber,
      telephone:          body.telephone,
      role:               'POLICE',
      mustChangePassword: true,
      niveauHierarchique: body.niveauHierarchique ?? 'AGENT',
      gradeId:            gradeId      ?? undefined,
      departementId:      departementId ?? undefined,
      commissariatId:     body.commissariatId ?? undefined,
    },
    include: OFFICER_INCLUDE,
  });

  await audit(prisma, {
    userId: actorId,
    action: 'OFFICER_CREATED',
    details: { officerId: officer.id, badgeNumber: officer.badgeNumber },
  });

  try {
    await sendCredentialsEmail(
      officer.email,
      officer.name,
      officer.email,
      body.pin,
      officer.badgeNumber ?? '—',
    );
  } catch (err) {
    console.warn('[email] Échec envoi identifiants agent :', (err as Error).message);
  }

  return {
    id:                 officer.id,
    email:              officer.email,
    name:               officer.name,
    badgeNumber:        officer.badgeNumber,
    telephone:          officer.telephone,
    actif:              officer.actif,
    mustChangePassword: officer.mustChangePassword,
    grade:              officer.grade?.code ?? null,
    departement:        officer.departement?.code ?? null,
    niveauHierarchique: officer.niveauHierarchique,
    commissariatId:     officer.commissariatId ?? null,
  };
}

// ── Import CSV en masse ───────────────────────────────────────────────────
export async function importOfficersFromCsv(
  csvContent: string,
  actorId: string,
): Promise<{
  created: number;
  skipped: number;
  errors: { line: number; email: string; reason: string }[];
  credentials: { name: string; email: string; badgeNumber: string; tempPassword: string }[];
}> {
  const lines = csvContent
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  const dataLines = lines[0]?.toLowerCase().includes('email') ? lines.slice(1) : lines;

  const created: { name: string; email: string; badgeNumber: string; tempPassword: string }[] = [];
  const errors: { line: number; email: string; reason: string }[] = [];
  let skipped = 0;

  for (let i = 0; i < dataLines.length; i++) {
    const lineNum = i + (lines[0]?.toLowerCase().includes('email') ? 2 : 1);
    const parts = dataLines[i]!.split(',').map((p) => p.trim().replace(/^"|"$/g, ''));

    if (parts.length < 4) {
      errors.push({ line: lineNum, email: parts[1] ?? '?', reason: 'Format invalide (4 colonnes requises : name,email,badge_number,telephone)' });
      skipped++;
      continue;
    }

    const [name, email, badgeNumber, telephone] = parts as [string, string, string, string];

    if (!email.toLowerCase().endsWith(PNC_DOMAIN)) {
      errors.push({ line: lineNum, email, reason: `Email doit se terminer par ${PNC_DOMAIN}` });
      skipped++;
      continue;
    }

    const existing = await prisma.user.findFirst({
      where: { OR: [{ email }, { badgeNumber }] },
    });
    if (existing) {
      errors.push({ line: lineNum, email, reason: 'Email ou matricule déjà existant' });
      skipped++;
      continue;
    }

    const tempPassword = generateTempPassword();
    const pinHash = await bcrypt.hash(tempPassword, PIN_ROUNDS);

    try {
      const officer = await prisma.user.create({
        data: {
          email,
          pinHash,
          name,
          badgeNumber,
          telephone,
          role: 'POLICE',
          mustChangePassword: true,
        },
      });

      await audit(prisma, {
        userId: actorId,
        action: 'OFFICER_CREATED_CSV',
        details: { officerId: officer.id, badgeNumber },
      });

      created.push({ name, email, badgeNumber, tempPassword });
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Erreur inconnue';
      errors.push({ line: lineNum, email, reason: msg });
      skipped++;
    }
  }

  return { created: created.length, skipped, errors, credentials: created };
}

// ── Historique connexions/deconnexions d'un agent ────────────────────────
export async function getOfficerActivity(
  officerId: string,
  page: number,
  limit: number,
  admin: AuthUser,
): Promise<{
  items: {
    action: string;
    createdAt: Date;
    ip: string | null;
    userAgent: string | null;
    lat: number | null;
    lng: number | null;
  }[];
  total: number;
}> {
  const officer = await prisma.user.findUnique({ where: { id: officerId } });
  if (!officer || officer.role !== 'POLICE') {
    throw AppError.notFound('Agent introuvable', 'OFFICER_NOT_FOUND');
  }

  const hierarchyFilter = await buildHierarchyFilter(admin);
  const cIdFilter = (hierarchyFilter as Prisma.UserWhereInput).commissariatId;
  const dIdFilter = (hierarchyFilter as Prisma.UserWhereInput).departementId;

  if (cIdFilter) {
    const inScope =
      typeof cIdFilter === 'string'
        ? officer.commissariatId === cIdFilter
        : typeof cIdFilter === 'object' && 'in' in cIdFilter
          ? (cIdFilter.in as string[]).includes(officer.commissariatId ?? '')
          : true;
    if (!inScope) {
      throw AppError.forbidden("Cet agent n'est pas dans votre périmètre", 'FORBIDDEN');
    }
  } else if (dIdFilter && typeof dIdFilter === 'string') {
    if (officer.departementId !== dIdFilter) {
      throw AppError.forbidden("Cet agent n'est pas dans votre département", 'FORBIDDEN');
    }
  }

  const where = {
    userId: officerId,
    action: { in: ['LOGIN', 'LOGOUT'] as string[] },
  };

  const [logs, total] = await Promise.all([
    prisma.auditLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
      select: { action: true, createdAt: true, ip: true, userAgent: true, details: true },
    }),
    prisma.auditLog.count({ where }),
  ]);

  const items = logs.map((log) => {
    const d = (log.details as Record<string, unknown> | null) ?? {};
    return {
      action:    log.action,
      createdAt: log.createdAt,
      ip:        log.ip,
      userAgent: log.userAgent ?? null,
      lat:       typeof d['lat'] === 'number' ? d['lat'] : null,
      lng:       typeof d['lng'] === 'number' ? d['lng'] : null,
    };
  });

  return { items, total };
}

// ── Modification d'un agent ───────────────────────────────────────────────
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
  if (body.email !== undefined) {
    if (!body.email.toLowerCase().endsWith(PNC_DOMAIN)) {
      throw AppError.badRequest(`L'email doit se terminer par ${PNC_DOMAIN}`, 'INVALID_OFFICER_DOMAIN');
    }
    data.email = body.email;
  }
  if (body.name        !== undefined) data.name        = body.name;
  if (body.badgeNumber !== undefined) data.badgeNumber = body.badgeNumber;
  if (body.telephone   !== undefined) data.telephone   = body.telephone;
  if (body.actif       !== undefined) data.actif       = body.actif;
  if (body.pin         !== undefined) data.pinHash     = await bcrypt.hash(body.pin, PIN_ROUNDS);
  if (body.niveauHierarchique !== undefined) data.niveauHierarchique = body.niveauHierarchique;

  if (body.grade !== undefined) {
    const gradeId = await resolveGradeId(body.grade);
    data.grade = gradeId ? { connect: { id: gradeId } } : { disconnect: true };
  }
  if (body.departement !== undefined) {
    const departementId = await resolveDepartementId(body.departement);
    data.departement = departementId ? { connect: { id: departementId } } : { disconnect: true };
  }
  if (body.commissariatId !== undefined) {
    data.commissariat = body.commissariatId
      ? { connect: { id: body.commissariatId } }
      : { disconnect: true };
  }

  const updated = await prisma.user.update({
    where: { id },
    data,
    include: OFFICER_INCLUDE,
  });

  if (body.actif === false) {
    await revokeAllRefreshTokens(id);
  }

  await audit(prisma, {
    userId: actorId,
    action: 'OFFICER_MODIFIED',
    details: { officerId: id, changes: Object.keys(body) },
  });

  return {
    id:                 updated.id,
    email:              updated.email,
    name:               updated.name,
    badgeNumber:        updated.badgeNumber,
    telephone:          updated.telephone,
    actif:              updated.actif,
    mustChangePassword: updated.mustChangePassword,
    grade:              updated.grade?.code     ?? null,
    departement:        updated.departement?.code ?? null,
    niveauHierarchique: updated.niveauHierarchique,
    commissariatId:     updated.commissariatId ?? null,
  };
}

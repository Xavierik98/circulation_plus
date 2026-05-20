import bcrypt from 'bcryptjs';
import { randomBytes } from 'node:crypto';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';
import { revokeAllRefreshTokens } from '../auth/auth.service';
import type { CreateOfficerBody, UpdateOfficerBody } from './officers.schema';

const PIN_ROUNDS = 12;
const PNC_DOMAIN = '@pnc.cg';

export interface OfficerWithStats {
  id: string;
  email: string;
  name: string;
  badgeNumber: string | null;
  telephone: string | null;
  actif: boolean;
  mustChangePassword: boolean;
  createdAt: Date;
  totalFines: number;
  montantCollecte: number;
}

// ── Génère un mot de passe temporaire fort (ISO 27001) ─────────────────────
function generateTempPassword(): string {
  const upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lower   = 'abcdefghjkmnpqrstuvwxyz';
  const digits  = '23456789';
  const special = '!@#$%&*?';

  const pick = (s: string) => s[randomBytes(1)[0]! % s.length]!;
  // Garantit au moins 1 de chaque catégorie
  const base = [pick(upper), pick(upper), pick(lower), pick(lower),
                pick(digits), pick(digits), pick(special), pick(special)];
  // Complète à 12 caractères avec un mix
  const all = upper + lower + digits + special;
  while (base.length < 12) base.push(pick(all));
  // Mélange
  for (let i = base.length - 1; i > 0; i--) {
    const j = randomBytes(1)[0]! % (i + 1);
    [base[i], base[j]] = [base[j]!, base[i]!];
  }
  return base.join('');
}

// ── Liste paginée ──────────────────────────────────────────────────────────
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
        mustChangePassword: officer.mustChangePassword,
        createdAt: officer.createdAt,
        totalFines,
        montantCollecte: collected._sum.montantTotal ?? 0,
      };
    }),
  );

  return { items, total };
}

// ── Création manuelle d'un agent ──────────────────────────────────────────
export async function createOfficer(body: CreateOfficerBody, actorId: string) {
  // Domaine @pnc.cg déjà validé par le schéma Zod — double vérification défensive.
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

  const pinHash = await bcrypt.hash(body.pin, PIN_ROUNDS);
  const officer = await prisma.user.create({
    data: {
      email: body.email,
      pinHash,
      name: body.name,
      badgeNumber: body.badgeNumber,
      telephone: body.telephone,
      role: 'POLICE',
      mustChangePassword: true, // Changement obligatoire au 1er login
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
    mustChangePassword: officer.mustChangePassword,
  };
}

// ── Import CSV en masse ───────────────────────────────────────────────────
// Format CSV : name,email,badge_number,telephone  (avec ou sans header)
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

  // Ignore la première ligne si c'est un header
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

    // Validation domaine @pnc.cg
    if (!email.toLowerCase().endsWith(PNC_DOMAIN)) {
      errors.push({ line: lineNum, email, reason: `Email doit se terminer par ${PNC_DOMAIN}` });
      skipped++;
      continue;
    }

    // Vérification doublon
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
  if (body.name !== undefined)        data.name = body.name;
  if (body.badgeNumber !== undefined) data.badgeNumber = body.badgeNumber;
  if (body.telephone !== undefined)   data.telephone = body.telephone;
  if (body.actif !== undefined)       data.actif = body.actif;
  if (body.pin !== undefined)         data.pinHash = await bcrypt.hash(body.pin, PIN_ROUNDS);

  const updated = await prisma.user.update({ where: { id }, data });

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
    mustChangePassword: updated.mustChangePassword,
  };
}

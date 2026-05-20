import type { Prisma, PrismaClient } from '@prisma/client';
import { prisma } from '../../config/database';
import { env } from '../../config/env';
import type { Adapters } from '../../adapters/types';
import type { AuthUser } from '../../types/fastify';
import { AppError } from '../../shared/errors/AppError';
import { audit } from '../../shared/middleware/audit';
import { notify } from '../../shared/utils/fcm';
import { smsTemplates } from '../../shared/utils/sms';
import { createConvocation } from '../convocations/convocations.service';
import type { CreateFineBody } from './fines.schema';

const FINE_INCLUDE = {
  officer: { select: { id: true, name: true, badgeNumber: true } },
  citizen: { select: { id: true, name: true } },
  driver: true,
  vehicle: true,
  infractionType: true,
  payment: true,
  convocation: true,
} satisfies Prisma.FineInclude;

const DUPLICATE_WINDOW_MS = 30 * 60 * 1000;

function splitName(full: string | undefined): { prenom: string; nom: string } {
  if (!full || full.trim() === '') return { prenom: 'Inconnu', nom: 'Inconnu' };
  const parts = full.trim().split(/\s+/);
  if (parts.length === 1) return { prenom: parts[0]!, nom: parts[0]! };
  return { prenom: parts[0]!, nom: parts.slice(1).join(' ') };
}

// Génère "PV-YYYY-NNNNNN" via un compteur annuel atomique (verrou de ligne).
async function generateReference(
  tx: Prisma.TransactionClient,
  year: number,
): Promise<string> {
  const rows = await tx.$queryRaw<{ lastSeq: number }[]>`
    INSERT INTO "FineCounter" ("year", "lastSeq") VALUES (${year}, 1)
    ON CONFLICT ("year")
    DO UPDATE SET "lastSeq" = "FineCounter"."lastSeq" + 1
    RETURNING "lastSeq"`;
  const seq = Number(rows[0]?.lastSeq ?? 1);
  return `PV-${year}-${String(seq).padStart(6, '0')}`;
}

// Sécurité au niveau ligne : restreint la requête selon le rôle.
function rlsWhere(user: AuthUser): Prisma.FineWhereInput {
  if (user.role === 'POLICE') return { officerId: user.id };
  if (user.role === 'CITOYEN') return { citizenId: user.id };
  return {};
}

export interface CreateFineResult {
  fine: unknown;
  duplicate: false;
}

async function resolveDriverAndVehicle(
  tx: Prisma.TransactionClient,
  body: CreateFineBody,
): Promise<{ driverId: string | null; vehicleId: string }> {
  let driverId: string | null = null;

  if (body.numeroPermis) {
    const { prenom, nom } = splitName(body.driverName);
    const driver = await tx.driver.upsert({
      where: { numeroPermis: body.numeroPermis },
      update: { telephone: body.driverPhone },
      create: {
        nom,
        prenom,
        telephone: body.driverPhone,
        numeroPermis: body.numeroPermis,
      },
    });
    driverId = driver.id;
  }

  const vehicle = await tx.vehicle.upsert({
    where: { plaque: body.vehiclePlate },
    update: driverId ? { driverId } : {},
    create: { plaque: body.vehiclePlate, driverId },
  });

  return { driverId, vehicleId: vehicle.id };
}

export async function createFine(
  officer: AuthUser,
  body: CreateFineBody,
  adapters: Adapters,
  ip: string | null,
): Promise<unknown> {
  const infractionType = await prisma.infractionType.findUnique({
    where: { id: body.infractionTypeId },
  });
  if (!infractionType || !infractionType.actif) {
    throw AppError.badRequest(
      'Type d’infraction inconnu ou inactif',
      'INVALID_INFRACTION_TYPE',
    );
  }

  // Détection de doublon : même agent + même plaque dans les 30 dernières minutes.
  const duplicate = await prisma.fine.findFirst({
    where: {
      officerId: officer.id,
      vehicle: { plaque: body.vehiclePlate },
      createdAt: { gte: new Date(Date.now() - DUPLICATE_WINDOW_MS) },
    },
  });
  if (duplicate) {
    throw AppError.conflict(
      `Contravention en doublon : une verbalisation pour ${body.vehiclePlate} ` +
        `a déjà été émise par cet agent il y a moins de 30 minutes ` +
        `(réf. ${duplicate.reference}).`,
      'DUPLICATE_FINE',
    );
  }

  const verbaliseLe = new Date(body.verbaliseLe);
  const dateEcheance = new Date(verbaliseLe.getTime() + 30 * 24 * 3600 * 1000);
  const montantAmende = infractionType.montantBase;
  const montantDeveloppeur = env.PART_DEVELOPPEUR; // 1 000 XAF → compte développeurs
  const montantTotal = montantAmende + montantDeveloppeur; // total payé par le contrevenant

  // Rattachement best-effort à un compte citoyen (téléphone identique).
  const citizen = await prisma.user.findFirst({
    where: { role: 'CITOYEN', telephone: body.driverPhone },
    select: { id: true },
  });

  const created = await prisma.$transaction(async (tx) => {
    const { driverId, vehicleId } = await resolveDriverAndVehicle(tx, body);
    const reference = await generateReference(tx, verbaliseLe.getFullYear());

    const fine = await tx.fine.create({
      data: {
        reference,
        officerId: officer.id,
        citizenId: citizen?.id ?? null,
        driverId,
        vehicleId,
        infractionTypeId: infractionType.id,
        montantAmende,
        montantDeveloppeur,
        montantMajoration: 0,
        montantTotal,
        latitude: body.latitude ?? null,
        longitude: body.longitude ?? null,
        adresseApprox: body.adresseApprox ?? null,
        verbaliseLe,
        dateEcheance,
        signatureAgent: body.signatureAgent ?? null,
        signatureContrevenant: body.signatureContrevenant ?? null,
        refusSignature: body.refusSignature ?? false,
        deviceId: body.deviceId ?? null,
      },
      include: FINE_INCLUDE,
    });

    // Vérification du permis (service interne déterministe).
    let permisInvalide = false;
    if (body.numeroPermis && driverId) {
      const driver = await tx.driver.findUnique({ where: { id: driverId } });
      permisInvalide = driver ? !driver.permisValide : true;
      await tx.licenseVerification.create({
        data: {
          numeroPermis: body.numeroPermis,
          valide: !permisInvalide,
          details: { fineReference: reference },
        },
      });
    }

    if ((permisInvalide || infractionType.convocationObligatoire) && driverId) {
      await createConvocation(tx as unknown as PrismaClient, {
        fineId: fine.id,
        driverId,
        motif: permisInvalide
          ? 'Permis de conduire irrégulier'
          : `Infraction à convocation obligatoire : ${infractionType.libelle}`,
      });
    }

    return fine;
  });

  // Effets de bord post-commit : non bloquants.
  try {
    await adapters.sms.send(
      body.driverPhone,
      smsTemplates.verbalisation({
        ref: created.reference,
        date: verbaliseLe,
        montant: montantTotal,
        echeance: dateEcheance,
      }),
    );
  } catch {
    /* SMS non bloquant */
  }

  // Notification in-app + push pour l'agent verbalisateur
  try {
    const officerUser = await prisma.user.findUnique({
      where: { id: officer.id },
      select: { fcmToken: true },
    });
    await notify(prisma, adapters.push, {
      userId: officer.id,
      fcmToken: officerUser?.fcmToken ?? null,
      title: 'Contravention enregistrée',
      body: `PV ${created.reference} créé (${montantTotal} XAF).`,
      type: 'fine_created',
      data: { fineId: created.id, reference: created.reference },
    });
  } catch {
    /* notification non bloquante */
  }

  // Notification in-app + push pour le citoyen (si compte associé)
  if (citizen?.id) {
    try {
      const citizenUser = await prisma.user.findUnique({
        where: { id: citizen.id },
        select: { fcmToken: true },
      });
      const echeanceStr = dateEcheance.toLocaleDateString('fr-FR', {
        day: '2-digit', month: '2-digit', year: 'numeric',
      });
      await notify(prisma, adapters.push, {
        userId: citizen.id,
        fcmToken: citizenUser?.fcmToken ?? null,
        title: '⚠️ Nouvelle contravention reçue',
        body:
          `PV ${created.reference} — ${infractionType.libelle} — ` +
          `${montantTotal} XAF à payer avant le ${echeanceStr}.`,
        type: 'fine_received',
        data: { fineId: created.id, reference: created.reference },
      });
    } catch {
      /* notification citoyen non bloquante */
    }
  }

  await audit(prisma, {
    userId: officer.id,
    fineId: created.id,
    action: 'FINE_CREATED',
    details: { reference: created.reference, montantTotal },
    ip,
  });

  return created;
}

export async function listFines(
  user: AuthUser,
  query: {
    citizen?: string;
    officer?: string;
    status?: 'PENDING' | 'PAID' | 'OVERDUE' | 'CONTESTED';
    dateFrom?: string;
    dateTo?: string;
    page: number;
    limit: number;
  },
): Promise<{ items: unknown[]; total: number }> {
  const where: Prisma.FineWhereInput = { ...rlsWhere(user) };

  // Filtres additionnels (uniquement pour ADMIN ; POLICE/CITOYEN déjà restreints).
  if (user.role === 'ADMIN') {
    if (query.officer) where.officerId = query.officer;
    if (query.citizen) where.citizenId = query.citizen;
  }
  if (query.status) where.status = query.status;
  if (query.dateFrom || query.dateTo) {
    where.verbaliseLe = {};
    if (query.dateFrom) where.verbaliseLe.gte = new Date(query.dateFrom);
    if (query.dateTo) where.verbaliseLe.lte = new Date(query.dateTo);
  }

  const [items, total] = await Promise.all([
    prisma.fine.findMany({
      where,
      orderBy: { verbaliseLe: 'desc' },
      skip: (query.page - 1) * query.limit,
      take: query.limit,
      include: FINE_INCLUDE,
    }),
    prisma.fine.count({ where }),
  ]);

  return { items, total };
}

export async function getFineById(user: AuthUser, id: string): Promise<unknown> {
  const fine = await prisma.fine.findFirst({
    where: { id, ...rlsWhere(user) },
    include: FINE_INCLUDE,
  });
  if (!fine) {
    throw AppError.notFound('Contravention introuvable', 'FINE_NOT_FOUND');
  }
  return fine;
}

export async function updateFineStatus(
  id: string,
  status: 'CONTESTED' | 'PAID' | 'OVERDUE' | 'PENDING',
): Promise<unknown> {
  const fine = await prisma.fine.findUnique({ where: { id } });
  if (!fine) {
    throw AppError.notFound('Contravention introuvable', 'FINE_NOT_FOUND');
  }
  return prisma.fine.update({
    where: { id },
    data: { status },
    include: FINE_INCLUDE,
  });
}

export async function syncFines(
  officer: AuthUser,
  fines: CreateFineBody[],
  adapters: Adapters,
  ip: string | null,
): Promise<{ created: number; failed: number; errors: { deviceId: string; reason: string }[] }> {
  let created = 0;
  let failed = 0;
  const errors: { deviceId: string; reason: string }[] = [];

  // Traitement par lots de 10 ; résilience par item.
  for (let i = 0; i < fines.length; i += 10) {
    const batch = fines.slice(i, i + 10);
    for (const item of batch) {
      const deviceId = item.deviceId ?? `inconnu-${i}`;
      try {
        // Idempotence : un deviceId déjà synchronisé n'est pas recréé.
        if (item.deviceId) {
          const existing = await prisma.fine.findFirst({
            where: { deviceId: item.deviceId },
          });
          if (existing) {
            errors.push({ deviceId, reason: 'Déjà synchronisé (idempotent)' });
            failed += 1;
            continue;
          }
        }
        await createFine(officer, item, adapters, ip);
        created += 1;
      } catch (err) {
        failed += 1;
        const reason =
          err instanceof AppError ? err.message : 'Erreur de création';
        errors.push({ deviceId, reason });
      }
    }
  }

  return { created, failed, errors };
}

export async function getFineForPdf(user: AuthUser, id: string) {
  const fine = await prisma.fine.findFirst({
    where: { id, ...rlsWhere(user) },
    include: FINE_INCLUDE,
  });
  if (!fine) {
    throw AppError.notFound('Contravention introuvable', 'FINE_NOT_FOUND');
  }
  return fine;
}

export async function persistPdfUrl(id: string, url: string): Promise<void> {
  await prisma.fine.update({ where: { id }, data: { pdfUrl: url } });
}

// Vérification publique (cible du QR code) : données non sensibles uniquement.
export async function verifyFine(reference: string): Promise<{
  reference: string;
  status: string;
  montantTotal: number;
  verbaliseLe: Date;
  infraction: string;
}> {
  const fine = await prisma.fine.findUnique({
    where: { reference },
    include: { infractionType: true },
  });
  if (!fine) {
    throw AppError.notFound('Contravention introuvable', 'FINE_NOT_FOUND');
  }
  return {
    reference: fine.reference,
    status: fine.status,
    montantTotal: fine.montantTotal,
    verbaliseLe: fine.verbaliseLe,
    infraction: fine.infractionType.libelle,
  };
}

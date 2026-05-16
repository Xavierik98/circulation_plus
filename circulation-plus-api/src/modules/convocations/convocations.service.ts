import type { PrismaClient } from '@prisma/client';
import type { Adapters } from '../../adapters/types';
import { env } from '../../config/env';
import { smsTemplates } from '../../shared/utils/sms';

const LIEU_CONVOCATION = 'Commissariat central de Brazzaville';

// Crée une convocation pour une contravention (permis irrégulier ou
// infraction à convocation obligatoire).
export async function createConvocation(
  prisma: PrismaClient,
  params: { fineId: string; driverId: string; motif: string },
): Promise<void> {
  const existing = await prisma.convocation.findUnique({
    where: { fineId: params.fineId },
  });
  if (existing) return;

  const dateConvocation = new Date(
    Date.now() + env.DELAI_CONVOCATION_JOURS * 24 * 3600 * 1000,
  );

  await prisma.convocation.create({
    data: {
      fineId: params.fineId,
      driverId: params.driverId,
      motif: params.motif,
      dateConvocation,
      lieu: LIEU_CONVOCATION,
      status: 'PENDING',
    },
  });
}

// Traitement périodique des convocations : SMS1 -> SMS2 (relance) -> DEFAULTER.
export async function processConvocations(
  prisma: PrismaClient,
  adapters: Adapters,
): Promise<void> {
  const now = Date.now();

  // SMS1 pour les convocations PENDING.
  const pendings = await prisma.convocation.findMany({
    where: { status: 'PENDING', sms1SentAt: null },
    include: { driver: true, fine: true },
  });
  for (const c of pendings) {
    await adapters.sms.send(
      c.driver.telephone,
      smsTemplates.convocation1({
        permis: c.driver.numeroPermis,
        lieu: c.lieu,
        date: c.dateConvocation,
        ref: c.fine.reference,
      }),
    );
    await prisma.convocation.update({
      where: { id: c.id },
      data: { status: 'SMS1_SENT', sms1SentAt: new Date() },
    });
  }

  // SMS2 (relance) après DELAI_RELANCE_JOURS sans présentation.
  const relanceThreshold = new Date(
    now - env.DELAI_RELANCE_JOURS * 24 * 3600 * 1000,
  );
  const toRelance = await prisma.convocation.findMany({
    where: {
      status: 'SMS1_SENT',
      appearedAt: null,
      sms1SentAt: { lte: relanceThreshold },
    },
    include: { driver: true, fine: true },
  });
  for (const c of toRelance) {
    await adapters.sms.send(
      c.driver.telephone,
      smsTemplates.convocation2({ ref: c.fine.reference, lieu: c.lieu }),
    );
    await prisma.convocation.update({
      where: { id: c.id },
      data: { status: 'SMS2_SENT', sms2SentAt: new Date() },
    });
  }

  // Défaillants : relance envoyée mais toujours pas de présentation.
  const defaulterThreshold = new Date(
    now - env.DELAI_RELANCE_JOURS * 24 * 3600 * 1000,
  );
  await prisma.convocation.updateMany({
    where: {
      status: 'SMS2_SENT',
      appearedAt: null,
      sms2SentAt: { lte: defaulterThreshold },
    },
    data: { status: 'DEFAULTER' },
  });
}

// Passe les contraventions PENDING échues à OVERDUE (cohérence des stats).
export async function flagOverdueFines(prisma: PrismaClient): Promise<void> {
  await prisma.fine.updateMany({
    where: { status: 'PENDING', dateEcheance: { lt: new Date() } },
    data: { status: 'OVERDUE' },
  });
}

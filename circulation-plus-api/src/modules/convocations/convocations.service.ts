import type { PrismaClient } from '@prisma/client';
import type { Adapters } from '../../adapters/types';
import { env } from '../../config/env';
import { smsTemplates } from '../../shared/utils/sms';
import { notify } from '../../shared/utils/fcm';

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

// Envoie un rappel SMS + notification in-app pour les amendes PENDING
// dont l'échéance est dans la fenêtre [23h, 25h] à partir de maintenant.
// Lancé toutes les heures → chaque amende reçoit exactement un rappel ~24h avant.
export async function sendOverdueReminders(
  prisma: PrismaClient,
  adapters: Adapters,
): Promise<void> {
  const now = Date.now();
  const in23h = new Date(now + 23 * 3600 * 1000);
  const in25h = new Date(now + 25 * 3600 * 1000);

  const fines = await prisma.fine.findMany({
    where: {
      status: 'PENDING',
      dateEcheance: { gte: in23h, lte: in25h },
    },
    include: {
      driver: true,
      citizen: true,
    },
  });

  for (const fine of fines) {
    // SMS au conducteur ou au citoyen lié
    const phone = fine.driver?.telephone ?? fine.citizen?.telephone ?? null;
    if (phone) {
      try {
        await adapters.sms.send(
          phone,
          smsTemplates.rappelEcheance({
            ref: fine.reference,
            montant: fine.montantTotal,
            echeance: fine.dateEcheance,
          }),
        );
      } catch {
        /* SMS non bloquant */
      }
    }

    // Notification in-app pour le compte citoyen lié
    if (fine.citizenId && fine.citizen) {
      try {
        await notify(prisma, adapters.push, {
          userId: fine.citizenId,
          fcmToken: fine.citizen.fcmToken ?? null,
          title: '⚠️ Amende à régler avant demain',
          body: `Votre amende ${fine.reference} (${fine.montantTotal} XAF) expire dans moins de 24h. Payez maintenant.`,
          type: 'fine_due',
          data: { fineId: fine.id, reference: fine.reference },
        });
      } catch {
        /* notification non bloquante */
      }
    }
  }
}

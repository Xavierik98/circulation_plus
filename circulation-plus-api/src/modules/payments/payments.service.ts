import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { env } from '../../config/env';
import type { Adapters } from '../../adapters/types';
import type { AuthUser } from '../../types/fastify';
import { AppError } from '../../shared/errors/AppError';
import { notify } from '../../shared/utils/fcm';
import { smsTemplates } from '../../shared/utils/sms';

function fineAccessWhere(user: AuthUser, fineId: string): Prisma.FineWhereInput {
  if (user.role === 'POLICE') return { id: fineId, officerId: user.id };
  if (user.role === 'CITOYEN') return { id: fineId, citizenId: user.id };
  return { id: fineId };
}

// Initie un paiement Mobile Money. Réutilise l'unique Payment PENDING d'une fine.
export async function initiatePayment(
  user: AuthUser,
  body: { fineId: string; operateur: 'MTN' | 'AIRTEL'; telephone: string },
  adapters: Adapters,
): Promise<{ paymentUrl: string; reference: string }> {
  const fine = await prisma.fine.findFirst({
    where: fineAccessWhere(user, body.fineId),
  });
  if (!fine) {
    throw AppError.notFound('Contravention introuvable', 'FINE_NOT_FOUND');
  }
  if (fine.status === 'PAID') {
    throw AppError.conflict('Cette contravention est déjà payée', 'FINE_ALREADY_PAID');
  }

  const existing = await prisma.payment.findUnique({
    where: { fineId: fine.id },
  });
  if (existing && existing.status === 'CONFIRMED') {
    throw AppError.conflict('Paiement déjà confirmé', 'PAYMENT_ALREADY_CONFIRMED');
  }

  const paymentReference = `PAY-${fine.reference}`;
  const initiation = await adapters.payment.initiate({
    reference: paymentReference,
    amount: fine.montantTotal,
    phone: body.telephone,
    operator: body.operateur,
  });

  if (existing) {
    await prisma.payment.update({
      where: { id: existing.id },
      data: {
        operateur: body.operateur,
        telephone: body.telephone,
        transactionId: initiation.providerTxId,
        status: 'PENDING',
      },
    });
  } else {
    await prisma.payment.create({
      data: {
        fineId: fine.id,
        montantTotal: fine.montantTotal,
        operateur: body.operateur,
        telephone: body.telephone,
        transactionId: initiation.providerTxId,
        status: 'PENDING',
      },
    });
  }

  return { paymentUrl: initiation.paymentUrl, reference: paymentReference };
}

// Répartition à somme exacte : partDeveloppeur fixe, le reste réparti au
// prorata des poids PART_AGENT/POLICE/TRESOR ; le résidu d'arrondi va au Trésor.
export function computeRepartition(montantTotal: number): {
  partDeveloppeur: number;
  partAgent: number;
  partPolice: number;
  partTresor: number;
} {
  const partDeveloppeur = Math.min(env.PART_DEVELOPPEUR, montantTotal);
  const reste = montantTotal - partDeveloppeur;

  const wAgent = env.PART_AGENT;
  const wPolice = env.PART_POLICE;
  const wTresor = env.PART_TRESOR;
  const sumW = wAgent + wPolice + wTresor;

  let partAgent = 0;
  let partPolice = 0;
  let partTresor = 0;

  if (sumW > 0) {
    partAgent = Math.floor((reste * wAgent) / sumW);
    partPolice = Math.floor((reste * wPolice) / sumW);
    partTresor = reste - partAgent - partPolice; // absorbe le résidu d'arrondi
  } else {
    partTresor = reste; // configuration dev tout-à-zéro
  }

  return { partDeveloppeur, partAgent, partPolice, partTresor };
}

// Webhook CinetPay : signature vérifiée AVANT, transaction atomique, idempotent.
export async function confirmPayment(
  rawBody: Buffer,
  headers: Record<string, string | string[] | undefined>,
  adapters: Adapters,
  ip: string | null,
): Promise<{ idempotent: boolean }> {
  const verification = adapters.payment.verifyWebhook(rawBody, headers);
  if (!verification.valid) {
    throw AppError.unauthorized('Signature webhook invalide', 'INVALID_SIGNATURE');
  }

  const payment = await prisma.payment.findUnique({
    where: { transactionId: verification.transactionId },
    include: { fine: true },
  });
  if (!payment) {
    throw AppError.notFound('Paiement introuvable', 'PAYMENT_NOT_FOUND');
  }

  // Transaction + verrou de ligne => idempotence garantie.
  const result = await prisma.$transaction(async (tx) => {
    const locked = await tx.$queryRaw<{ id: string; status: string }[]>`
      SELECT "id", "status" FROM "Payment" WHERE "id" = ${payment.id} FOR UPDATE`;
    const current = locked[0];
    if (!current) {
      throw AppError.notFound('Paiement introuvable', 'PAYMENT_NOT_FOUND');
    }
    if (current.status === 'CONFIRMED') {
      return { idempotent: true as const };
    }

    if (verification.status === 'FAILED') {
      await tx.payment.update({
        where: { id: payment.id },
        data: { status: 'FAILED' },
      });
      return { idempotent: false as const };
    }

    await tx.payment.update({
      where: { id: payment.id },
      data: { status: 'CONFIRMED', confirmedAt: new Date() },
    });
    await tx.fine.update({
      where: { id: payment.fineId },
      data: { status: 'PAID' },
    });

    const parts = computeRepartition(payment.montantTotal);
    await tx.repartition.create({
      data: { paymentId: payment.id, ...parts },
    });

    await tx.auditLog.create({
      data: {
        fineId: payment.fineId,
        action: 'PAYMENT_CONFIRMED',
        details: {
          transactionId: payment.transactionId,
          ...parts,
          // Traçabilité des comptes destinataires
          compteDeveloppeur: env.COMPTE_DEVELOPPEUR ?? 'non configuré',
          comptePolice: env.COMPTE_POLICE ?? 'non configuré',
        },
        ip,
      },
    });

    return { idempotent: false as const };
  });

  if (result.idempotent) {
    return { idempotent: true };
  }

  // Effets de bord post-commit (non bloquants) uniquement si confirmé.
  const fresh = await prisma.payment.findUnique({
    where: { id: payment.id },
    include: {
      fine: { include: { officer: true, citizen: true } },
    },
  });
  if (fresh && fresh.status === 'CONFIRMED') {
    const ref = fresh.fine.reference;
    const montant = fresh.montantTotal;

    // SMS citoyen + agent (telephone peut être null si paiement Trésor public)
    try {
      if (fresh.telephone) {
        await adapters.sms.send(
          fresh.telephone,
          smsTemplates.paiementConfirmeContrevenant({ ref, montant }),
        );
      }
      const agentTel = fresh.fine.officer.telephone ?? fresh.telephone;
      if (agentTel) {
        await adapters.sms.send(
          agentTel,
          smsTemplates.paiementConfirmeAgent({ ref, montant }),
        );
      }
    } catch {
      /* SMS non bloquant */
    }

    // Notification in-app pour l'agent
    try {
      await notify(prisma, adapters.push, {
        userId: fresh.fine.officerId,
        fcmToken: fresh.fine.officer.fcmToken ?? null,
        title: '✅ Paiement confirmé',
        body: `PV ${ref} réglé (${montant} XAF). Restituez les pièces au conducteur.`,
        type: 'payment_confirmed',
        data: { fineId: fresh.fineId, reference: ref },
      });
    } catch {
      /* notification non bloquante */
    }

    // Notification in-app pour le citoyen (si compte associé)
    if (fresh.fine.citizenId && fresh.fine.citizen) {
      try {
        await notify(prisma, adapters.push, {
          userId: fresh.fine.citizenId,
          fcmToken: fresh.fine.citizen.fcmToken ?? null,
          title: '✅ Paiement reçu',
          body: `Votre paiement pour le PV ${ref} (${montant} XAF) a bien été enregistré.`,
          type: 'payment_confirmed',
          data: { fineId: fresh.fineId, reference: ref },
        });
      } catch {
        /* notification citoyen non bloquante */
      }
    }
  }

  return { idempotent: false };
}

// Enregistre un paiement effectué au Trésor public (quittance physique).
// La confirmation est immédiate : le citoyen/agent saisit le n° de quittance après
// paiement en agence. Le paiement est directement marqué CONFIRMED.
export async function recordTresorPayment(
  user: AuthUser,
  body: { fineId: string; quittanceNumero: string; quittanceDate?: string; agentTresor?: string },
  adapters: Adapters,
  ip: string | null,
): Promise<{ paymentId: string; reference: string }> {
  const fine = await prisma.fine.findFirst({
    where: fineAccessWhere(user, body.fineId),
    include: { officer: true, citizen: true },
  });
  if (!fine) throw AppError.notFound('Contravention introuvable', 'FINE_NOT_FOUND');
  if (fine.status === 'PAID') throw AppError.conflict('Contravention déjà payée', 'FINE_ALREADY_PAID');

  // Vérifier unicité quittance
  const existingQuittance = await prisma.payment.findFirst({
    where: { quittanceNumero: body.quittanceNumero },
  });
  if (existingQuittance) {
    throw AppError.conflict('Ce numéro de quittance est déjà enregistré', 'QUITTANCE_DUPLICATE');
  }

  const parts = computeRepartition(fine.montantTotal);

  const payment = await prisma.$transaction(async (tx) => {
    const p = await tx.payment.create({
      data: {
        fineId: fine.id,
        montantTotal: fine.montantTotal,
        mode: 'TRESOR_PUBLIC',
        quittanceNumero: body.quittanceNumero,
        quittanceDate: body.quittanceDate ? new Date(body.quittanceDate) : new Date(),
        agentTresor: body.agentTresor ?? null,
        status: 'CONFIRMED',
        confirmedAt: new Date(),
      },
    });
    await tx.fine.update({
      where: { id: fine.id },
      data: { status: 'PAID' },
    });
    await tx.repartition.create({
      data: { paymentId: p.id, ...parts },
    });
    await tx.auditLog.create({
      data: {
        fineId: fine.id,
        action: 'PAYMENT_TRESOR_CONFIRMED',
        details: { quittanceNumero: body.quittanceNumero, ...parts },
        ip,
      },
    });
    return p;
  });

  // Notifications post-commit (non bloquantes)
  try {
    await notify(prisma, adapters.push, {
      userId: fine.officerId,
      fcmToken: fine.officer.fcmToken ?? null,
      title: '✅ Paiement Trésor confirmé',
      body: `PV ${fine.reference} réglé au Trésor public (${fine.montantTotal} XAF).`,
      type: 'payment_confirmed',
      data: { fineId: fine.id, reference: fine.reference },
    });
  } catch { /* non bloquant */ }

  if (fine.citizenId && fine.citizen) {
    try {
      await notify(prisma, adapters.push, {
        userId: fine.citizenId,
        fcmToken: fine.citizen.fcmToken ?? null,
        title: '✅ Paiement Trésor enregistré',
        body: `Votre paiement pour le PV ${fine.reference} a été enregistré.`,
        type: 'payment_confirmed',
        data: { fineId: fine.id, reference: fine.reference },
      });
    } catch { /* non bloquant */ }
  }

  return { paymentId: payment.id, reference: fine.reference };
}

export async function getReceipt(user: AuthUser, paymentId: string) {
  const payment = await prisma.payment.findUnique({
    where: { id: paymentId },
    include: {
      repartition: true,
      fine: { include: { infractionType: true, officer: { select: { name: true, badgeNumber: true } } } },
    },
  });
  if (!payment) {
    throw AppError.notFound('Paiement introuvable', 'PAYMENT_NOT_FOUND');
  }

  // RLS : POLICE/CITOYEN ne voient que les paiements liés à leurs fines.
  if (user.role === 'POLICE') {
    const owned = await prisma.fine.findFirst({
      where: { id: payment.fineId, officerId: user.id },
      select: { id: true },
    });
    if (!owned) throw AppError.notFound('Paiement introuvable', 'PAYMENT_NOT_FOUND');
  } else if (user.role === 'CITOYEN') {
    const owned = await prisma.fine.findFirst({
      where: { id: payment.fineId, citizenId: user.id },
      select: { id: true },
    });
    if (!owned) throw AppError.notFound('Paiement introuvable', 'PAYMENT_NOT_FOUND');
  }

  return payment;
}

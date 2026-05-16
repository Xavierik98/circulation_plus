import type { PrismaClient, Prisma } from '@prisma/client';

export interface AuditInput {
  userId?: string | null;
  fineId?: string | null;
  action: string;
  details?: Prisma.InputJsonValue;
  ip?: string | null;
}

// Journalisation des actions sensibles : login, création de fine,
// confirmation de paiement, modification d'agent.
export async function audit(prisma: PrismaClient, input: AuditInput): Promise<void> {
  try {
    await prisma.auditLog.create({
      data: {
        userId: input.userId ?? null,
        fineId: input.fineId ?? null,
        action: input.action,
        details: input.details,
        ip: input.ip ?? null,
      },
    });
  } catch {
    // L'échec d'écriture d'audit ne doit pas interrompre l'action métier.
  }
}

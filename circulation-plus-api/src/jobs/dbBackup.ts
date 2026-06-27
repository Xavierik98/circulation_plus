import { PrismaClient, Prisma } from '@prisma/client';
import cron from 'node-cron';
import { env } from '../config/env';
import { prisma as sourcePrisma } from '../config/database';
import { audit } from '../shared/middleware/audit';

const BATCH_SIZE = 500;

function modelClientKey(modelName: string): string {
  return modelName.charAt(0).toLowerCase() + modelName.slice(1);
}

/**
 * Copie complète et périodique de la base principale (Neon, DATABASE_URL)
 * vers la base de secours (Supabase, SUPABASE_DATABASE_URL). Désactivée si
 * SUPABASE_DATABASE_URL est absent.
 *
 * Pour chaque modèle Prisma : on vide la table cible puis on réinsère
 * toutes les lignes de la source. Les contraintes de clé étrangère sont
 * désactivées au niveau de la session cible (`session_replication_role =
 * replica`) pendant la copie pour s'affranchir de l'ordre des tables —
 * c'est le même mécanisme que pg_dump/pg_restore.
 */
export async function runDatabaseBackup(): Promise<{ rowsCopied: number; tables: number }> {
  if (!env.SUPABASE_DATABASE_URL) {
    throw new Error('SUPABASE_DATABASE_URL non configuré — sauvegarde désactivée');
  }

  const backupPrisma = new PrismaClient({
    datasources: { db: { url: env.SUPABASE_DATABASE_URL } },
  });

  const models = Prisma.dmmf.datamodel.models.map((m) => m.name);
  let rowsCopied = 0;

  try {
    await backupPrisma.$executeRawUnsafe('SET session_replication_role = replica');

    for (const modelName of models) {
      const key = modelClientKey(modelName);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const sourceDelegate = (sourcePrisma as any)[key];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const targetDelegate = (backupPrisma as any)[key];
      if (!sourceDelegate?.findMany || !targetDelegate?.deleteMany) continue;

      const rows: Record<string, unknown>[] = await sourceDelegate.findMany();
      await targetDelegate.deleteMany();

      for (let i = 0; i < rows.length; i += BATCH_SIZE) {
        const batch = rows.slice(i, i + BATCH_SIZE);
        if (batch.length === 0) continue;
        await targetDelegate.createMany({ data: batch, skipDuplicates: true });
      }
      rowsCopied += rows.length;
    }
  } finally {
    await backupPrisma
      .$executeRawUnsafe('SET session_replication_role = origin')
      .catch(() => undefined);
    await backupPrisma.$disconnect();
  }

  return { rowsCopied, tables: models.length };
}

/** Exécute la sauvegarde et journalise le résultat (succès/échec) dans AuditLog. */
export async function runDatabaseBackupAndLog(): Promise<void> {
  const startedAt = Date.now();
  try {
    const { rowsCopied, tables } = await runDatabaseBackup();
    await audit(sourcePrisma, {
      action: 'DB_BACKUP_SUCCESS',
      details: { rowsCopied, tables, durationMs: Date.now() - startedAt },
    });
  } catch (err) {
    await audit(sourcePrisma, {
      action: 'DB_BACKUP_FAILED',
      details: {
        error: err instanceof Error ? err.message : String(err),
        durationMs: Date.now() - startedAt,
      },
    });
  }
}

/** Démarre la tâche planifiée (toutes les 6 h). Pas d'effet si non configuré. */
export function scheduleDbBackup(): void {
  if (!env.SUPABASE_DATABASE_URL) return;
  cron.schedule('0 */6 * * *', () => {
    void runDatabaseBackupAndLog();
  });
}

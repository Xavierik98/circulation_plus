import type { FastifyInstance } from 'fastify';
import { ToadScheduler, SimpleIntervalJob, AsyncTask } from 'toad-scheduler';
import { prisma } from '../../config/database';
import { processConvocations, flagOverdueFines, sendOverdueReminders } from './convocations.service';

let scheduler: ToadScheduler | null = null;

// Tâche horaire : traite les convocations et marque les contraventions échues.
export function startConvocationCron(app: FastifyInstance): void {
  scheduler = new ToadScheduler();

  const task = new AsyncTask(
    'convocations-tick',
    async () => {
      await flagOverdueFines(prisma);
      await processConvocations(prisma, app.adapters);
      await sendOverdueReminders(prisma, app.adapters);
    },
    (err: Error) => {
      app.log.error({ err }, 'Échec du traitement périodique des convocations');
    },
  );

  scheduler.addSimpleIntervalJob(
    new SimpleIntervalJob({ hours: 1, runImmediately: false }, task),
  );

  app.addHook('onClose', async () => {
    scheduler?.stop();
  });
}

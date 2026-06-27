import { buildApp } from './app';
import { env } from './config/env';
import { scheduleDbBackup } from './jobs/dbBackup';

async function main(): Promise<void> {
  const app = await buildApp();
  try {
    await app.listen({ port: env.PORT, host: '0.0.0.0' });
    app.log.info(`Circulation+ API démarrée sur le port ${env.PORT}`);

    scheduleDbBackup();
    if (env.SUPABASE_DATABASE_URL) {
      app.log.info('[backup] Sauvegarde Neon → Supabase planifiée toutes les 6h');
    } else {
      app.log.warn('[backup] SUPABASE_DATABASE_URL absent — sauvegarde désactivée');
    }
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

void main();

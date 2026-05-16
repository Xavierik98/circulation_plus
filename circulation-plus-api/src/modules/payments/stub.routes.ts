import { readFile } from 'node:fs/promises';
import { join, normalize } from 'node:path';
import type { FastifyInstance } from 'fastify';
import { StubStorageProvider } from '../../adapters/storage/stub.storage';
import { confirmPayment } from './payments.service';

// Routes de développement, montées uniquement quand les adaptateurs sont en
// mode stub. Permettent de tester toute la chaîne sans credentials externes.
export function registerStubRoutes(app: FastifyInstance): void {
  if (app.adapters.storage.mode === 'stub') {
    app.get('/__stub_storage/*', { schema: { hide: true } }, async (request, reply) => {
      const wildcard = (request.params as Record<string, string>)['*'] ?? '';
      // Empêche la traversée de répertoire.
      const safe = normalize(wildcard).replace(/^(\.\.[/\\])+/, '');
      const filePath = join(StubStorageProvider.DIR, safe);
      try {
        const bytes = await readFile(filePath);
        reply.header('Content-Type', 'application/pdf');
        return reply.send(bytes);
      } catch {
        return reply.status(404).send({ success: false, error: 'Fichier introuvable', code: 'NOT_FOUND' });
      }
    });
  }

  if (app.adapters.payment.mode === 'stub') {
    app.get('/__stub_pay/:reference', { schema: { hide: true } }, async (request, reply) => {
      const { reference } = request.params as { reference: string };
      const tx = (request.query as { tx?: string }).tx ?? '';

      const body = Buffer.from(
        JSON.stringify({ transactionId: tx, status: 'CONFIRMED', reference }),
      );
      try {
        await confirmPayment(
          body,
          { 'x-stub-signature': 'stub' },
          app.adapters,
          request.ip,
        );
      } catch (err) {
        request.log.error({ err }, 'Échec de la confirmation stub');
      }

      reply.header('Content-Type', 'text/html; charset=utf-8');
      return reply.send(
        `<!doctype html><html lang="fr"><head><meta charset="utf-8">` +
          `<title>Paiement simulé</title></head><body style="font-family:sans-serif;` +
          `text-align:center;padding-top:60px">` +
          `<h2>Paiement simulé pour ${reference}</h2>` +
          `<p>Le webhook de confirmation a été déclenché (mode stub).</p>` +
          `</body></html>`,
      );
    });
  }
}

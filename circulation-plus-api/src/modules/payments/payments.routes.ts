import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { AppError } from '../../shared/errors/AppError';
import {
  initiatePaymentSchema,
  receiptParamsSchema,
} from './payments.schema';
import { initiatePayment, confirmPayment, getReceipt } from './payments.service';

export async function paymentsRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // POST /api/payments/initiate — CITOYEN, POLICE, ADMIN.
  r.post(
    '/initiate',
    {
      preHandler: [authenticate, authorize('CITOYEN', 'POLICE', 'ADMIN')],
      schema: {
        tags: ['Paiements'],
        summary: 'Initier un paiement Mobile Money',
        description:
          'Rôles autorisés : CITOYEN, POLICE, ADMIN. Codes : FINE_NOT_FOUND ' +
          '(404), FINE_ALREADY_PAID (409).',
        security: [{ bearerAuth: [] }],
        body: initiatePaymentSchema,
      },
    },
    async (request) =>
      ok(await initiatePayment(request.user!, request.body, app.adapters)),
  );

  // POST /api/payments/confirm — webhook CinetPay, SANS JWT, signature HMAC.
  app.post(
    '/confirm',
    {
      config: { rawBody: true },
      schema: {
        tags: ['Paiements'],
        summary: 'Webhook de confirmation CinetPay',
        description:
          'PUBLIC (signature HMAC vérifiée). Idempotent. Codes : ' +
          'INVALID_SIGNATURE (401), PAYMENT_NOT_FOUND (404).',
      },
    },
    async (request) => {
      const raw = request.rawBody;
      const buffer = Buffer.isBuffer(raw)
        ? raw
        : Buffer.from(typeof raw === 'string' ? raw : JSON.stringify(request.body ?? {}));
      if (buffer.length === 0) {
        throw AppError.badRequest('Corps de webhook vide', 'EMPTY_WEBHOOK');
      }
      const result = await confirmPayment(
        buffer,
        request.headers,
        app.adapters,
        request.ip,
      );
      return ok({ confirmed: !result.idempotent, idempotent: result.idempotent });
    },
  );

  // GET /api/payments/receipt/:id — authentifié (RLS).
  r.get(
    '/receipt/:id',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Paiements'],
        summary: 'Reçu de paiement (paiement + répartition + fine)',
        description: 'Rôles autorisés : tous (authentifié, propriétaire).',
        security: [{ bearerAuth: [] }],
        params: receiptParamsSchema,
      },
    },
    async (request) =>
      ok(await getReceipt(request.user!, request.params.id)),
  );
}

import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { ok } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';

export async function statusRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // PATCH /api/officers/me/location — Heartbeat GPS (agent en service, toutes les 30s).
  r.patch(
    '/me/location',
    {
      preHandler: [authenticate, authorize('POLICE')],
      schema: {
        tags: ['Agents'],
        summary: 'Mise à jour de la position GPS (heartbeat)',
        description: 'Rôles autorisés : POLICE. Appelé toutes les 30s par l\'app quand l\'agent est en service.',
        security: [{ bearerAuth: [] }],
        body: z.object({
          lat: z.number().min(-90).max(90),
          lng: z.number().min(-180).max(180),
        }),
      },
    },
    async (request) => {
      const { lat, lng } = request.body;
      const userId = request.user!.id;
      await prisma.user.update({
        where: { id: userId },
        data: { lastLat: lat, lastLng: lng, lastSeenAt: new Date() },
      });
      return ok({ lat, lng, updatedAt: new Date() });
    },
  );

  // POST /api/officers/me/status — Agent authentifié, met à jour son statut de service.
  r.post(
    '/me/status',
    {
      preHandler: [authenticate, authorize('POLICE')],
      schema: {
        tags: ['Agents'],
        summary: 'Mise à jour du statut de service (En service / Hors service)',
        description: 'Rôles autorisés : POLICE.',
        security: [{ bearerAuth: [] }],
        body: z.object({
          onDuty: z.boolean(),
          lat: z.number().optional(),
          lng: z.number().optional(),
        }),
      },
    },
    async (request) => {
      const { onDuty, lat, lng } = request.body;
      const userId = request.user!.id;

      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user) {
        throw AppError.notFound('Utilisateur introuvable', 'USER_NOT_FOUND');
      }

      const updated = await prisma.user.update({
        where: { id: userId },
        data: {
          onDuty,
          lastLat: lat ?? null,
          lastLng: lng ?? null,
          lastSeenAt: new Date(),
        },
      });

      return ok({
        onDuty: updated.onDuty,
        lastLat: updated.lastLat,
        lastLng: updated.lastLng,
        lastSeenAt: updated.lastSeenAt,
      });
    },
  );
}

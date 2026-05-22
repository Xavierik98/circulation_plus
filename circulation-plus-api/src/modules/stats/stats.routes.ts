import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { getRevenueStats, getHeatmap, getOfficerStats } from './stats.service';

const revenueQuerySchema = z.object({
  dateFrom: z.string().datetime().optional(),
  dateTo: z.string().datetime().optional(),
});

// Module Stats — réservé au rôle ADMIN.
export async function statsRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // GET /api/stats/me — Agent authentifié, ses propres statistiques.
  r.get(
    '/me',
    {
      preHandler: [authenticate, authorize('POLICE')],
      schema: {
        tags: ['Statistiques'],
        summary: 'Statistiques personnelles de l\'agent connecté',
        description: 'Rôle autorisé : POLICE.',
        security: [{ bearerAuth: [] }],
      },
    },
    async (request) => ok(await getOfficerStats(request.user!.id)),
  );

  r.get(
    '/revenue',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Statistiques'],
        summary: 'Revenus collectés et ventilation',
        description: 'Rôle autorisé : ADMIN.',
        security: [{ bearerAuth: [] }],
        querystring: revenueQuerySchema,
      },
    },
    async (request) => ok(await getRevenueStats(request.query)),
  );

  r.get(
    '/infractions/heatmap',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Statistiques'],
        summary: 'Carte de chaleur des infractions (cellules 3 décimales)',
        description: 'Rôle autorisé : ADMIN.',
        security: [{ bearerAuth: [] }],
      },
    },
    async () => ok(await getHeatmap()),
  );
}

import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { driverQuerySchema } from './drivers.schema';
import { findDriver } from './drivers.service';

// GET /api/drivers?plate=... | ?license=... — POLICE, ADMIN.
export async function driversRoutes(app: FastifyInstance): Promise<void> {
  app.withTypeProvider<ZodTypeProvider>().get(
    '/',
    {
      preHandler: [authenticate, authorize('POLICE', 'ADMIN')],
      schema: {
        tags: ['Conducteurs'],
        summary: 'Recherche conducteur par plaque ou permis',
        description:
          'Rôles autorisés : POLICE, ADMIN. Retourne le conducteur, ses ' +
          'véhicules et ses 5 dernières contraventions.',
        security: [{ bearerAuth: [] }],
        querystring: driverQuerySchema,
      },
    },
    async (request) => {
      const { plate, license } = request.query;
      return ok(await findDriver({ plate, license }));
    },
  );
}

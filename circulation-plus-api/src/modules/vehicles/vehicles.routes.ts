import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { vehicleParamsSchema } from './vehicles.schema';
import { findVehicleByPlate } from './vehicles.service';

// GET /api/vehicles/:plate — POLICE, ADMIN.
export async function vehiclesRoutes(app: FastifyInstance): Promise<void> {
  app.withTypeProvider<ZodTypeProvider>().get(
    '/:plate',
    {
      preHandler: [authenticate, authorize('POLICE', 'ADMIN')],
      schema: {
        tags: ['Véhicules'],
        summary: 'Détail d’un véhicule par plaque',
        description: 'Rôles autorisés : POLICE, ADMIN.',
        security: [{ bearerAuth: [] }],
        params: vehicleParamsSchema,
      },
    },
    async (request) => ok(await findVehicleByPlate(request.params.plate)),
  );
}

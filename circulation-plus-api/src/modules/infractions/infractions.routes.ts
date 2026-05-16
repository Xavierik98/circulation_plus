import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok } from '../../shared/utils/response';
import { listActiveInfractions } from './infractions.service';

// GET /api/infractions — PUBLIC (pas d'authentification). Catalogue public.
export async function infractionsRoutes(app: FastifyInstance): Promise<void> {
  app.withTypeProvider<ZodTypeProvider>().get(
    '/',
    {
      schema: {
        tags: ['Infractions'],
        summary: 'Catalogue public des types d’infractions actifs',
        description:
          'Accessible sans authentification. Réponse mise en cache 1h. ' +
          'Rôles autorisés : public.',
      },
    },
    async () => ok(await listActiveInfractions()),
  );
}

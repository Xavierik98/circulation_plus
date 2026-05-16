import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok, paginated } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import {
  officersQuerySchema,
  createOfficerSchema,
  updateOfficerSchema,
  officerIdParamsSchema,
} from './officers.schema';
import { listOfficers, createOfficer, updateOfficer } from './officers.service';

// Module Officers — réservé au rôle ADMIN.
export async function officersRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  r.get(
    '/',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Agents'],
        summary: 'Liste paginée des agents avec statistiques',
        description: 'Rôles autorisés : ADMIN.',
        security: [{ bearerAuth: [] }],
        querystring: officersQuerySchema,
      },
    },
    async (request) => {
      const { page, limit, search } = request.query;
      const { items, total } = await listOfficers({ page, limit, search });
      return ok(paginated(items, total, page, limit));
    },
  );

  r.post(
    '/',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Agents'],
        summary: 'Création d’un agent',
        description: 'Rôles autorisés : ADMIN. Code : OFFICER_EXISTS (409).',
        security: [{ bearerAuth: [] }],
        body: createOfficerSchema,
      },
    },
    async (request) =>
      ok(await createOfficer(request.body, request.user!.id)),
  );

  r.patch(
    '/:id',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Agents'],
        summary: 'Modification partielle d’un agent',
        description:
          'Rôles autorisés : ADMIN. Si actif=false, tous les refresh ' +
          'tokens de l’agent sont révoqués.',
        security: [{ bearerAuth: [] }],
        params: officerIdParamsSchema,
        body: updateOfficerSchema,
      },
    },
    async (request) =>
      ok(await updateOfficer(request.params.id, request.body, request.user!.id)),
  );
}

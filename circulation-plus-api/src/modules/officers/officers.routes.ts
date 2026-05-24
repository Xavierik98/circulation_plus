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
  importCsvSchema,
} from './officers.schema';
import { listOfficers, createOfficer, updateOfficer, importOfficersFromCsv } from './officers.service';

// Module Officers — réservé au rôle ADMIN.
export async function officersRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // GET /api/officers
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
      const { items, total } = await listOfficers({ page, limit, search }, request.user!);
      return ok(paginated(items, total, page, limit));
    },
  );

  // POST /api/officers — création manuelle
  r.post(
    '/',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Agents'],
        summary: 'Création manuelle d\'un agent (email @pnc.cg obligatoire)',
        description:
          'Rôles autorisés : ADMIN. ' +
          'L\'email doit se terminer par @pnc.cg. ' +
          'mustChangePassword est automatiquement mis à true. ' +
          'Code : OFFICER_EXISTS (409), INVALID_OFFICER_DOMAIN (400).',
        security: [{ bearerAuth: [] }],
        body: createOfficerSchema,
      },
    },
    async (request) =>
      ok(await createOfficer(request.body, request.user!.id)),
  );

  // POST /api/officers/import-csv — import en masse
  r.post(
    '/import-csv',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Agents'],
        summary: 'Import CSV d\'agents en masse',
        description:
          'Format CSV : name,email,badge_number,telephone (header optionnel). ' +
          'Tous les emails doivent se terminer par @pnc.cg. ' +
          'Des mots de passe temporaires forts sont générés automatiquement. ' +
          'mustChangePassword=true est forcé pour chaque compte créé. ' +
          'La réponse contient les identifiants temporaires à distribuer.',
        security: [{ bearerAuth: [] }],
        body: importCsvSchema,
      },
    },
    async (request) =>
      ok(await importOfficersFromCsv(request.body.csvContent, request.user!.id)),
  );

  // PATCH /api/officers/:id
  r.patch(
    '/:id',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Agents'],
        summary: 'Modification partielle d\'un agent',
        description:
          'Rôles autorisés : ADMIN. Si actif=false, tous les refresh ' +
          'tokens de l\'agent sont révoqués.',
        security: [{ bearerAuth: [] }],
        params: officerIdParamsSchema,
        body: updateOfficerSchema,
      },
    },
    async (request) =>
      ok(await updateOfficer(request.params.id, request.body, request.user!.id)),
  );
}

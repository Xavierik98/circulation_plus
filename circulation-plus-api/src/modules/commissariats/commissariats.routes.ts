import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok, paginated } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { AppError } from '../../shared/errors/AppError';
import {
  createCommissariatSchema,
  updateCommissariatSchema,
  commissariatIdSchema,
  listCommissariatsSchema,
} from './commissariats.schema';
import {
  listCommissariats,
  getCommissariat,
  createCommissariat,
  updateCommissariat,
} from './commissariats.service';

export async function commissariatsRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // GET /api/commissariats — liste (ADMIN tous niveaux)
  r.get(
    '/',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Commissariats'],
        summary: 'Liste paginee des commissariats',
        description: 'Roles autorises : ADMIN. Filtres : departement, parentId, actif.',
        security: [{ bearerAuth: [] }],
        querystring: listCommissariatsSchema,
      },
    },
    async (request) => {
      const { page, limit, departement, actif } = request.query;
      const { items, total } = await listCommissariats({
        departement,
        actif,
        page,
        limit,
      });
      return ok(paginated(items, total, page, limit));
    },
  );

  // GET /api/commissariats/:id — detail (ADMIN tous niveaux)
  r.get(
    '/:id',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Commissariats'],
        summary: "Detail d'un commissariat avec ses enfants",
        security: [{ bearerAuth: [] }],
        params: commissariatIdSchema,
      },
    },
    async (request) => ok(await getCommissariat(request.params.id)),
  );

  // POST /api/commissariats — creation (DIRECTION_GENERALE uniquement)
  r.post(
    '/',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Commissariats'],
        summary: 'Creer un nouveau commissariat',
        description:
          'Roles autorises : ADMIN avec niveauHierarchique DIRECTION_GENERALE. ' +
          'Code unique, departement obligatoire, parentId optionnel.',
        security: [{ bearerAuth: [] }],
        body: createCommissariatSchema,
      },
    },
    async (request) => {
      const user = request.user!;
      if (user.niveauHierarchique !== 'DIRECTION_GENERALE') {
        throw AppError.forbidden(
          'Seule la Direction Generale peut creer des commissariats.',
          'FORBIDDEN',
        );
      }
      return ok(await createCommissariat(request.body, user.id));
    },
  );

  // PATCH /api/commissariats/:id — modification (DIRECTION_GENERALE)
  r.patch(
    '/:id',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Commissariats'],
        summary: 'Modifier un commissariat (nom, GPS, adresse, actif)',
        description: 'Roles autorises : ADMIN avec niveauHierarchique DIRECTION_GENERALE.',
        security: [{ bearerAuth: [] }],
        params: commissariatIdSchema,
        body: updateCommissariatSchema,
      },
    },
    async (request) => {
      const user = request.user!;
      if (user.niveauHierarchique !== 'DIRECTION_GENERALE') {
        throw AppError.forbidden(
          'Seule la Direction Generale peut modifier des commissariats.',
          'FORBIDDEN',
        );
      }
      return ok(await updateCommissariat(request.params.id, request.body, user.id));
    },
  );
}

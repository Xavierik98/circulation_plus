import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { ok, paginated } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { listUsers, getUserById, setUserStatus, deleteUser } from './users.service';

// ── Schémas de validation ──────────────────────────────────────────────────────

const userIdParamsSchema = z.object({
  id: z.string().uuid('Identifiant utilisateur invalide'),
});

const usersQuerySchema = z.object({
  role:   z.enum(['POLICE', 'CITOYEN', 'ADMIN']).optional(),
  actif:  z.coerce.boolean().optional(),
  search: z.string().max(100).optional(),
  page:   z.coerce.number().int().positive().default(1),
  limit:  z.coerce.number().int().positive().max(100).default(25),
});

const setStatusBodySchema = z.object({
  actif: z.boolean({ required_error: 'Le champ actif est requis' }),
});

// ── Module Admin — gestion des comptes utilisateurs ──────────────────────────

export async function usersRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // GET /api/admin/users — liste paginée avec filtres
  r.get(
    '/',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Admin — Utilisateurs'],
        summary: 'Liste paginée des utilisateurs (citoyens + police + admins)',
        description:
          'Rôle autorisé : ADMIN. '
          + 'Filtres disponibles : role (POLICE | CITOYEN | ADMIN), actif (boolean), '
          + 'search (email / nom). Pagination : page (défaut 1), limit (défaut 25, max 100).',
        security: [{ bearerAuth: [] }],
        querystring: usersQuerySchema,
      },
    },
    async (request) => {
      const { role, actif, search, page, limit } = request.query;
      const { items, total } = await listUsers({ role, actif, search, page, limit });
      return ok(paginated(items, total, page, limit));
    },
  );

  // GET /api/admin/users/:id — détail d'un utilisateur
  r.get(
    '/:id',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Admin — Utilisateurs'],
        summary: "Détail d'un utilisateur",
        description:
          'Rôle autorisé : ADMIN. '
          + "Retourne le profil complet + nombre d'amendes liées si le compte est CITOYEN. "
          + 'Code : USER_NOT_FOUND (404).',
        security: [{ bearerAuth: [] }],
        params: userIdParamsSchema,
      },
    },
    async (request) => ok(await getUserById(request.params.id)),
  );

  // PATCH /api/admin/users/:id/status — activer ou suspendre un compte
  r.patch(
    '/:id/status',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Admin — Utilisateurs'],
        summary: 'Activer ou suspendre un compte utilisateur',
        description:
          'Rôle autorisé : ADMIN. '
          + 'Body : { actif: boolean }. '
          + 'Codes : USER_NOT_FOUND (404), ALREADY_ACTIVE (400), ALREADY_SUSPENDED (400).',
        security: [{ bearerAuth: [] }],
        params: userIdParamsSchema,
        body: setStatusBodySchema,
      },
    },
    async (request) => {
      const { id } = request.params;
      const { actif } = request.body;
      return ok(await setUserStatus(id, actif, request.user!.id));
    },
  );

  // DELETE /api/admin/users/:id — supprimer un compte
  r.delete(
    '/:id',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Admin — Utilisateurs'],
        summary: 'Supprimer un compte utilisateur',
        description:
          'Rôle autorisé : ADMIN. '
          + 'Interdit sur les comptes ADMIN et sur son propre compte. '
          + 'Codes : USER_NOT_FOUND (404), CANNOT_DELETE_ADMIN (403), CANNOT_DELETE_SELF (403).',
        security: [{ bearerAuth: [] }],
        params: userIdParamsSchema,
      },
    },
    async (request, reply) => {
      await deleteUser(request.params.id, request.user!.id);
      return reply.status(204).send();
    },
  );
}

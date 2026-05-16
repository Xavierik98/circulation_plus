import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok, paginated } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import {
  notificationsQuerySchema,
  notificationIdParamsSchema,
} from './notifications.schema';
import { listNotifications, markAsRead } from './notifications.service';

// Module Notifications — chaque utilisateur voit les siennes.
export async function notificationsRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  r.get(
    '/',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Notifications'],
        summary: 'Liste paginée des notifications de l’utilisateur',
        description: 'Rôles autorisés : tous (authentifié).',
        security: [{ bearerAuth: [] }],
        querystring: notificationsQuerySchema,
      },
    },
    async (request) => {
      const { page, limit, unreadOnly } = request.query;
      const { items, total } = await listNotifications({
        userId: request.user!.id,
        page,
        limit,
        unreadOnly,
      });
      return ok(paginated(items, total, page, limit));
    },
  );

  r.patch(
    '/:id/read',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Notifications'],
        summary: 'Marquer une notification comme lue',
        description: 'Rôles autorisés : tous (authentifié, propriétaire).',
        security: [{ bearerAuth: [] }],
        params: notificationIdParamsSchema,
      },
    },
    async (request) =>
      ok(await markAsRead(request.user!.id, request.params.id)),
  );
}

import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { ok } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';

const sanctionTypeValues = [
  'AVERTISSEMENT',
  'BLAME',
  'SUSPENSION_TEMPORAIRE',
  'REVOCATION',
] as const;

export async function sanctionsRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // POST /api/officers/:id/sanctions — Admin seulement
  r.post(
    '/:id/sanctions',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Sanctions'],
        summary: 'Appliquer une sanction à un agent',
        description: 'Rôles autorisés : ADMIN.',
        security: [{ bearerAuth: [] }],
        params: z.object({ id: z.string().uuid() }),
        body: z.object({
          motif: z.string().min(1, 'Le motif est requis').max(500),
          type: z.enum(sanctionTypeValues),
        }),
      },
    },
    async (request) => {
      const { id: officerId } = request.params as { id: string };
      const { motif, type } = request.body;
      const adminId = request.user!.id;

      const officer = await prisma.user.findUnique({ where: { id: officerId } });
      if (!officer || officer.role !== 'POLICE') {
        throw AppError.notFound('Agent introuvable', 'OFFICER_NOT_FOUND');
      }

      const sanction = await prisma.sanction.create({
        data: {
          officerId,
          adminId,
          motif,
          type,
        },
      });

      return ok({
        id: sanction.id,
        officerId: sanction.officerId,
        adminId: sanction.adminId,
        motif: sanction.motif,
        type: sanction.type,
        createdAt: sanction.createdAt,
      });
    },
  );

  // GET /api/officers/:id/sanctions — Admin seulement
  r.get(
    '/:id/sanctions',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Sanctions'],
        summary: 'Liste des sanctions d\'un agent',
        description: 'Rôles autorisés : ADMIN.',
        security: [{ bearerAuth: [] }],
        params: z.object({ id: z.string().uuid() }),
      },
    },
    async (request) => {
      const { id: officerId } = request.params as { id: string };

      const sanctions = await prisma.sanction.findMany({
        where: { officerId },
        orderBy: { createdAt: 'desc' },
        include: {
          admin: { select: { name: true, email: true } },
        },
      });

      return ok(
        sanctions.map((s) => ({
          id: s.id,
          motif: s.motif,
          type: s.type,
          createdAt: s.createdAt,
          admin: s.admin,
        })),
      );
    },
  );
}

import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok, paginated } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { generateFinePdf, type FinePdfData } from '../../shared/utils/pdf';
import { env } from '../../config/env';
import { LOGIN_RATE_LIMIT } from '../../shared/middleware/rateLimit';
import { initiatePayment } from '../payments/payments.service';
import {
  finesQuerySchema,
  createFineSchema,
  fineIdParamsSchema,
  updateStatusSchema,
  payFineSchema,
  syncFinesSchema,
  fineReferenceParamsSchema,
} from './fines.schema';
import {
  listFines,
  getFineById,
  createFine,
  updateFineStatus,
  syncFines,
  getFineForPdf,
  persistPdfUrl,
  verifyFine,
} from './fines.service';

type FineWithRelations = Awaited<ReturnType<typeof getFineForPdf>>;

const PDF_URL_TTL = 7 * 24 * 3600; // 7 jours

export async function finesRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // GET /api/fines — RLS appliquée dans le service.
  r.get(
    '/',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Contraventions'],
        summary: 'Liste paginée des contraventions',
        description:
          'Rôles autorisés : POLICE (ses fines), CITOYEN (ses fines), ADMIN (toutes).',
        security: [{ bearerAuth: [] }],
        querystring: finesQuerySchema,
      },
    },
    async (request) => {
      const q = request.query;
      const { items, total } = await listFines(request.user!, q);
      return ok(paginated(items, total, q.page, q.limit));
    },
  );

  // GET /api/fines/:reference/verify -- PUBLIC (cible du QR code).
  // Rate-limited : protege contre l’enumeration sequentielle des references PV.
  r.get(
    "/:reference/verify",
    {
      config: { rateLimit: LOGIN_RATE_LIMIT },
      schema: {
        tags: ["Contraventions"],
        summary: "Verification publique d’un PV (QR code)",
        description: "PUBLIC. Donnees non sensibles uniquement. Limite a 10 req/min/IP.",
        params: fineReferenceParamsSchema,
      },
    },
    async (request) => ok(await verifyFine(request.params.reference)),
  );

  // GET /api/fines/:id — RLS.
  r.get(
    '/:id',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Contraventions'],
        summary: 'Détail d’une contravention',
        description: 'Rôles autorisés : POLICE/CITOYEN (la sienne), ADMIN (toutes).',
        security: [{ bearerAuth: [] }],
        params: fineIdParamsSchema,
      },
    },
    async (request) => ok(await getFineById(request.user!, request.params.id)),
  );

  // POST /api/fines — POLICE uniquement.
  r.post(
    '/',
    {
      preHandler: [authenticate, authorize('POLICE')],
      schema: {
        tags: ['Contraventions'],
        summary: 'Création d’une contravention',
        description:
          'Rôle autorisé : POLICE. Codes : INVALID_INFRACTION_TYPE (400), ' +
          'DUPLICATE_FINE (409).',
        security: [{ bearerAuth: [] }],
        body: createFineSchema,
      },
    },
    async (request, reply) => {
      const fine = await createFine(
        request.user!,
        request.body,
        app.adapters,
        request.ip,
      );
      return reply.status(201).send(ok(fine));
    },
  );

  // PATCH /api/fines/:id/status — ADMIN.
  r.patch(
    '/:id/status',
    {
      preHandler: [authenticate, authorize('ADMIN')],
      schema: {
        tags: ['Contraventions'],
        summary: 'Modification du statut d’une contravention',
        description: 'Rôle autorisé : ADMIN.',
        security: [{ bearerAuth: [] }],
        params: fineIdParamsSchema,
        body: updateStatusSchema,
      },
    },
    async (request) =>
      ok(await updateFineStatus(request.params.id, request.body.status)),
  );

  // POST /api/fines/:id/pay — CITOYEN ou POLICE (délègue au service paiements).
  r.post(
    '/:id/pay',
    {
      preHandler: [authenticate, authorize('CITOYEN', 'POLICE')],
      schema: {
        tags: ['Contraventions'],
        summary: 'Initier le paiement d’une contravention',
        description: 'Rôles autorisés : CITOYEN, POLICE.',
        security: [{ bearerAuth: [] }],
        params: fineIdParamsSchema,
        body: payFineSchema,
      },
    },
    async (request) =>
      ok(
        await initiatePayment(
          request.user!,
          {
            fineId: request.params.id,
            operateur: request.body.operateur,
            telephone: request.body.telephone,
          },
          app.adapters,
        ),
      ),
  );

  // POST /api/fines/sync — POLICE (sync offline par lots).
  r.post(
    '/sync',
    {
      preHandler: [authenticate, authorize('POLICE')],
      schema: {
        tags: ['Contraventions'],
        summary: 'Synchronisation batch des contraventions hors-ligne',
        description: 'Rôle autorisé : POLICE. Traitement par lots de 10.',
        security: [{ bearerAuth: [] }],
        body: syncFinesSchema,
      },
    },
    async (request) =>
      ok(
        await syncFines(
          request.user!,
          request.body.fines,
          app.adapters,
          request.ip,
        ),
      ),
  );

  // GET /api/fines/:id/pdf — génère/récupère le PDF, renvoie une URL signée 7j.
  r.get(
    '/:id/pdf',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Contraventions'],
        summary: 'PDF officiel de la contravention (URL signée 7 jours)',
        description: 'Rôles autorisés : POLICE/CITOYEN (la sienne), ADMIN.',
        security: [{ bearerAuth: [] }],
        params: fineIdParamsSchema,
      },
    },
    async (request) => {
      const fine = (await getFineForPdf(
        request.user!,
        request.params.id,
      )) as NonNullable<FineWithRelations>;

      const pdfData: FinePdfData = {
        reference: fine.reference,
        verbaliseLe: fine.verbaliseLe,
        createdAt: fine.createdAt,
        lieu: fine.adresseApprox,
        latitude: fine.latitude,
        longitude: fine.longitude,
        agentNom: fine.officer.name,
        agentBadge: fine.officer.badgeNumber,
        conducteurNom: fine.driver
          ? `${fine.driver.prenom} ${fine.driver.nom}`
          : null,
        conducteurTelephone: fine.driver?.telephone ?? null,
        conducteurPermis: fine.driver?.numeroPermis ?? null,
        vehiculePlaque: fine.vehicle?.plaque ?? null,
        vehiculeMarque: fine.vehicle?.marque ?? null,
        vehiculeModele: fine.vehicle?.modele ?? null,
        infractionCode: fine.infractionType.code,
        infractionLibelle: fine.infractionType.libelle,
        montantTotal: fine.montantTotal,
        signatureAgent: fine.signatureAgent,
        signatureContrevenant: fine.signatureContrevenant,
        refusSignature: fine.refusSignature,
        verifyUrl: `${env.BASE_URL}/api/fines/${fine.reference}/verify`,
      };

      const buffer = await generateFinePdf(pdfData);
      const key = `fines/${fine.reference}.pdf`;
      await app.adapters.storage.upload(key, buffer, 'application/pdf');
      const url = await app.adapters.storage.signedUrl(key, PDF_URL_TTL);
      await persistPdfUrl(fine.id, url);

      return ok({ url });
    },
  );
}

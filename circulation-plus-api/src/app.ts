import Fastify, { type FastifyInstance } from 'fastify';
import helmet from '@fastify/helmet';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import rawBody from 'fastify-raw-body';
import { ZodError } from 'zod';
import {
  validatorCompiler,
  jsonSchemaTransform,
  type ZodTypeProvider,
} from 'fastify-type-provider-zod';
import { env, isProduction, isTest } from './config/env';
import { buildAdapters } from './adapters';
import { AppError } from './shared/errors/AppError';
import { fail, ok } from './shared/utils/response';
import { GLOBAL_RATE_LIMIT } from './shared/middleware/rateLimit';
import { authRoutes } from './modules/auth/auth.routes';
import { infractionsRoutes } from './modules/infractions/infractions.routes';
import { finesRoutes } from './modules/fines/fines.routes';
import { paymentsRoutes } from './modules/payments/payments.routes';
import { driversRoutes } from './modules/drivers/drivers.routes';
import { vehiclesRoutes } from './modules/vehicles/vehicles.routes';
import { officersRoutes } from './modules/officers/officers.routes';
import { statusRoutes } from './modules/officers/status.routes';
import { sanctionsRoutes } from './modules/sanctions/sanctions.routes';
import { notificationsRoutes } from './modules/notifications/notifications.routes';
import { statsRoutes } from './modules/stats/stats.routes';
import { commissariatsRoutes } from './modules/commissariats/commissariats.routes';
import { registerStubRoutes } from './modules/payments/stub.routes';
import { startConvocationCron } from './modules/convocations/convocations.cron';

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    // trustProxy : indispensable derrière nginx / CloudFlare / Render pour que
    // request.ip contienne l'IP réelle du client (X-Forwarded-For) et non celle
    // du proxy. Sans cela, tous les logs d'audit enregistrent l'IP du proxy.
    trustProxy: true,
    logger: isTest
      ? false
      : {
          level: isProduction ? 'info' : 'debug',
          transport: isProduction
            ? undefined
            : { target: 'pino-pretty', options: { translateTime: 'HH:MM:ss' } },
        },
  }).withTypeProvider<ZodTypeProvider>();

  // On garde le validateur Zod (validation requêtes) mais PAS le sérialiseur Zod
  // global : la sérialisation par défaut de Fastify préserve l'enveloppe
  // { success, data } sur toutes les réponses, y compris les erreurs.
  app.setValidatorCompiler(validatorCompiler);

  await app.register(helmet, {
    // CSP : API REST — uniquement les pages HTML d'auth (verify-email, reset-password)
    // sont servies au navigateur. Politique stricte : pas de scripts inline, pas de
    // ressources externes inconnues.
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        // Les pages HTML d'auth n'embarquent que des styles inline (reset form).
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:'],
        scriptSrc: ["'none'"],
        objectSrc: ["'none'"],
        frameSrc: ["'none'"],
        baseUri: ["'self'"],
        formAction: ["'self'"],
      },
    },
  });
  await app.register(cors, {
    origin: env.CORS_ORIGINS === '*' ? true : env.CORS_ORIGINS.split(',').map((o) => o.trim()),
    credentials: true,
  });
  await app.register(rawBody, {
    field: 'rawBody',
    global: false,
    encoding: false,
    runFirst: true,
  });
  await app.register(rateLimit, {
    max: GLOBAL_RATE_LIMIT.max,
    timeWindow: GLOBAL_RATE_LIMIT.timeWindow,
    errorResponseBuilder: () =>
      fail('Trop de requêtes, réessayez plus tard', 'RATE_LIMITED'),
  });

  // Documentation Swagger masquée en production (évite l'exposition de l'API interne).
  await app.register(swagger, {
    openapi: {
      info: {
        title: 'Circulation+ API',
        description:
          'API de gestion des contraventions routières — Police Nationale du ' +
          'Congo-Brazzaville. Toutes les réponses suivent l’enveloppe ' +
          '`{ success: true, data }` ou `{ success: false, error, code }`.',
        version: '1.0.0',
      },
      components: {
        securitySchemes: {
          bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
        },
      },
    },
    transform: jsonSchemaTransform,
  });
  await app.register(swaggerUi, {
    routePrefix: '/docs',
    // En production : accès restreint (désactivé par défaut, activer via ENABLE_DOCS=true)
    uiConfig: { docExpansion: 'list', deepLinking: false },
    // Masquer les routes d'admin en production
    transformSpecificationClone: isProduction
      ? true
      : false,
  });
  // Bloquer /docs en production sauf si explicitement activé
  if (isProduction && process.env['ENABLE_DOCS'] !== 'true') {
    app.addHook('onRequest', async (request, reply) => {
      if (request.url.startsWith('/docs')) {
        reply.status(404).send({ success: false, error: 'Not found', code: 'NOT_FOUND' });
      }
    });
  }

  // Bundle d'adaptateurs (réel ou stub selon la configuration).
  const adapters = buildAdapters(app.log);
  app.decorate('adapters', adapters);

  // Gestionnaires d'erreur enregistrés AVANT les routes : un setErrorHandler
  // posé après app.register(...) ne s'applique pas aux plugins déjà encapsulés.
  app.setNotFoundHandler((_request, reply) => {
    reply.status(404).send(fail('Ressource introuvable', 'NOT_FOUND'));
  });

  app.setErrorHandler((error: unknown, request, reply) => {
    if (error instanceof AppError) {
      reply.status(error.statusCode).send(fail(error.message, error.code));
      return;
    }
    if (error instanceof ZodError) {
      const msg = error.issues
        .map((i) => `${i.path.join('.')}: ${i.message}`)
        .join('; ');
      reply.status(400).send(fail(`Validation échouée : ${msg}`, 'VALIDATION_ERROR'));
      return;
    }

    const err = error as {
      validation?: unknown;
      statusCode?: number;
      message?: string;
    };

    if (err.validation) {
      reply
        .status(400)
        .send(fail(err.message ?? 'Validation échouée', 'VALIDATION_ERROR'));
      return;
    }
    if (err.statusCode === 429) {
      reply
        .status(429)
        .send(fail(err.message ?? 'Trop de requêtes', 'RATE_LIMITED'));
      return;
    }

    request.log.error(error);
    // Pas de stacktrace exposée en production.
    const message = isProduction
      ? 'Erreur interne du serveur'
      : err.message ?? 'Erreur interne du serveur';
    reply.status(500).send(fail(message, 'INTERNAL_ERROR'));
  });

  app.get('/health', { schema: { hide: true } }, async () =>
    ok({ status: 'ok', time: new Date().toISOString() }),
  );

  // Routes stub dev (stockage + paiement) montées uniquement en mode stub.
  registerStubRoutes(app);

  await app.register(authRoutes, { prefix: '/api/auth' });
  await app.register(infractionsRoutes, { prefix: '/api/infractions' });
  await app.register(finesRoutes, { prefix: '/api/fines' });
  await app.register(paymentsRoutes, { prefix: '/api/payments' });
  await app.register(driversRoutes, { prefix: '/api/drivers' });
  await app.register(vehiclesRoutes, { prefix: '/api/vehicles' });
  await app.register(officersRoutes, { prefix: '/api/officers' });
  await app.register(statusRoutes, { prefix: '/api/officers' });
  await app.register(sanctionsRoutes, { prefix: '/api/officers' });
  await app.register(notificationsRoutes, { prefix: '/api/notifications' });
  await app.register(statsRoutes, { prefix: '/api/stats' });
  await app.register(commissariatsRoutes, { prefix: '/api/commissariats' });

  if (!isTest) {
    startConvocationCron(app);
  }

  return app;
}

import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { LOGIN_RATE_LIMIT } from '../../shared/middleware/rateLimit';
import {
  loginBodySchema,
  refreshBodySchema,
  logoutBodySchema,
  registerBodySchema,
} from './auth.schema';
import { login, refresh, logout, getMe, register } from './auth.service';

export async function authRoutes(app: FastifyInstance): Promise<void> {
  const r = app.withTypeProvider<ZodTypeProvider>();

  // POST /api/auth/register — PUBLIC, auto-inscription citoyen.
  r.post(
    '/register',
    {
      config: { rateLimit: LOGIN_RATE_LIMIT },
      schema: {
        tags: ['Auth'],
        summary: 'Inscription citoyen (auto-inscription publique)',
        description: 'Crée un compte CITOYEN. Codes : EMAIL_ALREADY_USED (409).',
        body: registerBodySchema,
      },
    },
    async (request) => {
      const { name, email, telephone, pin } = request.body;
      const result = await register(name, email, telephone, pin, request.ip);
      return ok(result);
    },
  );

  // POST /api/auth/login — PUBLIC, limité à 10 req/min/IP.
  r.post(
    '/login',
    {
      config: { rateLimit: LOGIN_RATE_LIMIT },
      schema: {
        tags: ['Auth'],
        summary: 'Connexion par email + PIN + rôle',
        description:
          'PUBLIC. Codes : INVALID_CREDENTIALS (401), ACCOUNT_LOCKED (429 ' +
          'après 5 échecs, blocage 30 min).',
        body: loginBodySchema,
      },
    },
    async (request) => {
      const { email, pin, role } = request.body;
      const result = await login(email, pin, role, request.ip);
      return ok(result);
    },
  );

  // POST /api/auth/refresh — PUBLIC (rotation du refresh token).
  r.post(
    '/refresh',
    {
      schema: {
        tags: ['Auth'],
        summary: 'Renouvellement du token d’accès',
        description: 'PUBLIC. Codes : INVALID_REFRESH (401).',
        body: refreshBodySchema,
      },
    },
    async (request) => ok(await refresh(request.body.refreshToken)),
  );

  // POST /api/auth/logout — authentifié.
  r.post(
    '/logout',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Auth'],
        summary: 'Déconnexion (invalide le refresh token)',
        description: 'Rôles autorisés : tous (authentifié).',
        security: [{ bearerAuth: [] }],
        body: logoutBodySchema,
      },
    },
    async (request) => {
      await logout(request.body.refreshToken);
      return ok({ loggedOut: true });
    },
  );

  // GET /api/auth/me — authentifié.
  r.get(
    '/me',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Auth'],
        summary: 'Profil de l’utilisateur courant',
        description: 'Rôles autorisés : tous (authentifié).',
        security: [{ bearerAuth: [] }],
      },
    },
    async (request) => ok(await getMe(request.user!.id)),
  );
}

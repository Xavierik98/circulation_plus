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
  changePasswordSchema,
  resendVerificationSchema,
} from './auth.schema';
import { login, refresh, logout, getMe, register, changePassword, verifyEmail, resendVerification } from './auth.service';

// ── Page HTML retournée après clic sur le lien de vérification ────────────────
function verifyHtml(success: boolean): string {
  const icon    = success ? '✅' : '❌';
  const title   = success ? 'Email vérifié !' : 'Lien invalide';
  const message = success
    ? 'Votre compte Circulation+ est maintenant actif. Retournez dans l\'application pour vous connecter.'
    : 'Ce lien est invalide ou a déjà été utilisé. Demandez un nouveau lien depuis l\'application.';
  const color   = success ? '#22c55e' : '#ef4444';

  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Circulation+ — ${title}</title>
  <style>
    body{font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;margin:0;display:flex;align-items:center;justify-content:center;min-height:100vh}
    .card{background:#1e293b;border-radius:16px;padding:40px 32px;max-width:420px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.4)}
    .icon{font-size:64px;margin-bottom:16px}
    h1{font-size:22px;color:${color};margin:0 0 12px}
    p{font-size:14px;color:#94a3b8;line-height:1.6;margin:0}
    .brand{font-size:13px;color:#475569;margin-top:28px;padding-top:20px;border-top:1px solid #334155}
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${icon}</div>
    <h1>${title}</h1>
    <p>${message}</p>
    <div class="brand">🇨🇬 Circulation+ · Police Nationale Congolaise</div>
  </div>
</body>
</html>`;
}

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
        description:
          'Crée un compte CITOYEN avec emailVerified=false. '
          + 'Un email de vérification est envoyé. '
          + 'En mode développement (pas de SMTP), verificationUrl est inclus dans la réponse. '
          + 'Codes : EMAIL_ALREADY_USED (409).',
        body: registerBodySchema,
      },
    },
    async (request) => {
      const { name, email, telephone, pin } = request.body;
      const result = await register(name, email, telephone, pin, request.ip);
      return ok(result);
    },
  );

  // GET /api/auth/verify-email — PUBLIC (lien cliqué depuis l'email).
  app.get(
    '/verify-email',
    async (request, reply) => {
      const { token } = request.query as { token?: string };
      if (!token) {
        return reply.type('text/html').send(verifyHtml(false));
      }
      try {
        await verifyEmail(token);
        return reply.type('text/html').send(verifyHtml(true));
      } catch {
        return reply.type('text/html').send(verifyHtml(false));
      }
    },
  );

  // POST /api/auth/resend-verification — PUBLIC.
  r.post(
    '/resend-verification',
    {
      config: { rateLimit: LOGIN_RATE_LIMIT },
      schema: {
        tags: ['Auth'],
        summary: 'Renvoyer l\'email de vérification',
        description: 'PUBLIC. Aucune erreur si le compte n\'existe pas (anti-enumeration).',
        body: resendVerificationSchema,
      },
    },
    async (request) => {
      const result = await resendVerification(request.body.email, request.ip);
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

  // POST /api/auth/change-password — authentifié (obligatoire si mustChangePassword).
  r.post(
    '/change-password',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Auth'],
        summary: 'Changement de mot de passe (ISO 27001/27005)',
        description:
          'Rôles autorisés : tous (authentifié). ' +
          'Vérifie le mot de passe actuel, applique la politique de sécurité, ' +
          'révoque tous les refresh tokens et remet mustChangePassword à false.',
        security: [{ bearerAuth: [] }],
        body: changePasswordSchema,
      },
    },
    async (request) => {
      const { currentPassword, newPassword } = request.body;
      return ok(await changePassword(request.user!.id, currentPassword, newPassword, request.ip));
    },
  );
}

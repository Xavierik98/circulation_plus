import type { FastifyInstance } from 'fastify';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { ok } from '../../shared/utils/response';
import { authenticate } from '../../shared/middleware/authenticate';
import { LOGIN_RATE_LIMIT } from '../../shared/middleware/rateLimit';
import { z } from 'zod';
import {
  loginBodySchema,
  refreshBodySchema,
  logoutBodySchema,
  registerBodySchema,
  changePasswordSchema,
  resendVerificationSchema,
} from './auth.schema';
import { login, refresh, logout, getMe, register, changePassword, verifyEmail, resendVerification, updateProfile, uploadProfilePhoto, forgotPassword, resetPassword } from './auth.service';

// ── Page HTML retournée après clic sur le lien de vérification ────────────────
type VerifyResult = 'success' | 'expired' | 'invalid';

function verifyHtml(result: VerifyResult): string {
  const config = {
    success: {
      icon: '✅',
      title: 'Email vérifié !',
      message: 'Votre compte Circulation+ est maintenant actif. Retournez dans l\'application pour vous connecter.',
      color: '#22c55e',
    },
    expired: {
      icon: '⏰',
      title: 'Lien expiré',
      message: 'Ce lien de vérification n\'est plus valide (durée de validité : 24 heures). Ouvrez l\'application Circulation+ et demandez un nouveau lien.',
      color: '#f59e0b',
    },
    invalid: {
      icon: '❌',
      title: 'Lien invalide',
      message: 'Ce lien est invalide ou a déjà été utilisé. Demandez un nouveau lien depuis l\'application.',
      color: '#ef4444',
    },
  }[result];

  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Circulation+ — ${config.title}</title>
  <style>
    body{font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;margin:0;display:flex;align-items:center;justify-content:center;min-height:100vh}
    .card{background:#1e293b;border-radius:16px;padding:40px 32px;max-width:420px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.4)}
    .icon{font-size:64px;margin-bottom:16px}
    h1{font-size:22px;color:${config.color};margin:0 0 12px}
    p{font-size:14px;color:#94a3b8;line-height:1.6;margin:0}
    .brand{font-size:13px;color:#475569;margin-top:28px;padding-top:20px;border-top:1px solid #334155}
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${config.icon}</div>
    <h1>${config.title}</h1>
    <p>${config.message}</p>
    <div class="brand">🇨🇬 Circulation+ · Police Nationale Congolaise</div>
  </div>
</body>
</html>`;
}

type ResetState = 'form' | 'success' | 'invalid' | 'error';

function _resetHtml(state: ResetState, token: string, errorMsg?: string): string {
  if (state === 'success') {
    return `<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Mot de passe réinitialisé</title>
    <style>body{font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
    .card{background:#1e293b;border-radius:16px;padding:40px 32px;max-width:420px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.4)}
    .icon{font-size:64px;margin-bottom:16px}h1{color:#22c55e;margin:0 0 12px}p{color:#94a3b8;font-size:14px}
    .brand{font-size:13px;color:#475569;margin-top:28px;padding-top:20px;border-top:1px solid #334155}</style></head>
    <body><div class="card"><div class="icon">✅</div><h1>Mot de passe réinitialisé !</h1>
    <p>Votre mot de passe a été modifié avec succès. Retournez dans l'application Circulation+ pour vous connecter.</p>
    <div class="brand">🇨🇬 Circulation+ · Police Nationale Congolaise</div></div></body></html>`;
  }
  if (state === 'invalid') {
    return `<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Lien invalide</title>
    <style>body{font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
    .card{background:#1e293b;border-radius:16px;padding:40px 32px;max-width:420px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.4)}
    .icon{font-size:64px;margin-bottom:16px}h1{color:#ef4444;margin:0 0 12px}p{color:#94a3b8;font-size:14px}
    .brand{font-size:13px;color:#475569;margin-top:28px;padding-top:20px;border-top:1px solid #334155}</style></head>
    <body><div class="card"><div class="icon">❌</div><h1>Lien invalide ou expiré</h1>
    <p>Ce lien a expiré (validité : 1 heure) ou a déjà été utilisé. Faites une nouvelle demande depuis l'application.</p>
    <div class="brand">🇨🇬 Circulation+ · Police Nationale Congolaise</div></div></body></html>`;
  }
  // 'form' ou 'error'
  const errBlock = errorMsg
    ? `<div class="error">${errorMsg}</div>`
    : '';
  return `<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Nouveau mot de passe</title>
  <style>
    *{box-sizing:border-box}body{font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:16px}
    .card{background:#1e293b;border-radius:16px;padding:36px 28px;width:100%;max-width:400px;box-shadow:0 20px 60px rgba(0,0,0,.4)}
    .logo{font-size:20px;font-weight:700;color:#3b82f6;margin-bottom:20px}
    h1{font-size:17px;margin:0 0 6px;color:#f1f5f9}p{font-size:13px;color:#94a3b8;margin:0 0 20px}
    label{display:block;font-size:12px;color:#64748b;text-transform:uppercase;letter-spacing:1px;margin-bottom:6px}
    input{width:100%;background:#0f172a;border:1px solid #334155;border-radius:8px;padding:12px 14px;color:#f1f5f9;font-size:15px;margin-bottom:16px;outline:none}
    input:focus{border-color:#3b82f6}
    button{width:100%;background:linear-gradient(135deg,#3b82f6,#1e3a8a);color:#fff;border:none;border-radius:10px;padding:14px;font-size:15px;font-weight:700;cursor:pointer;margin-top:4px}
    .error{background:#1a0a0a;border:1px solid #7f1d1d;border-radius:8px;padding:12px 14px;color:#fca5a5;font-size:13px;margin-bottom:16px}
    .brand{font-size:11px;color:#475569;margin-top:24px;padding-top:16px;border-top:1px solid #334155;text-align:center}
  </style></head>
  <body><div class="card">
    <div class="logo">🇨🇬 Circulation+</div>
    <h1>Nouveau mot de passe</h1>
    <p>Choisissez un mot de passe sécurisé (6 caractères minimum).</p>
    ${errBlock}
    <form method="POST" action="/api/auth/reset-password">
      <input type="hidden" name="token" value="${token}">
      <label>Nouveau mot de passe</label>
      <input type="password" name="newPassword" placeholder="••••••••" required minlength="6" autofocus>
      <label>Confirmer le mot de passe</label>
      <input type="password" name="confirm" placeholder="••••••••" required minlength="6">
      <button type="submit">Réinitialiser le mot de passe</button>
    </form>
    <div class="brand">Police Nationale Congolaise · Circulation+</div>
  </div></body></html>`;
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
        return reply.type('text/html').send(verifyHtml('invalid'));
      }
      try {
        await verifyEmail(token);
        return reply.type('text/html').send(verifyHtml('success'));
      } catch (err: unknown) {
        // Distinguer token expiré vs invalide/déjà utilisé
        const code = (err as { code?: string })?.code ?? '';
        if (code === 'TOKEN_EXPIRED') {
          return reply.type('text/html').send(verifyHtml('expired'));
        }
        return reply.type('text/html').send(verifyHtml('invalid'));
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

  // POST /api/auth/forgot-password — PUBLIC.
  r.post(
    '/forgot-password',
    {
      config: { rateLimit: LOGIN_RATE_LIMIT },
      schema: {
        tags: ['Auth'],
        summary: 'Demande de réinitialisation de mot de passe',
        description: 'PUBLIC. Toujours 200 (anti-enumeration). Un email est envoyé si le compte existe.',
        body: z.object({ email: z.string().email() }),
      },
    },
    async (request) => {
      await forgotPassword(request.body.email);
      return ok({ sent: true });
    },
  );

  // GET /api/auth/reset-password — PUBLIC, page HTML avec formulaire.
  app.get(
    '/reset-password',
    { schema: { hide: true } },
    async (request, reply) => {
      const { token } = request.query as { token?: string };
      if (!token) return reply.type('text/html').send(_resetHtml('invalid', ''));
      return reply.type('text/html').send(_resetHtml('form', token));
    },
  );

  // POST /api/auth/reset-password — PUBLIC, soumission du formulaire HTML.
  app.post(
    '/reset-password',
    { schema: { hide: true } },
    async (request, reply) => {
      const body = request.body as { token?: string; newPassword?: string; confirm?: string };
      const { token, newPassword, confirm } = body;
      if (!token || !newPassword || newPassword.length < 6) {
        return reply.type('text/html').send(_resetHtml('error', token ?? '', 'Mot de passe trop court (6 caractères minimum).'));
      }
      if (newPassword !== confirm) {
        return reply.type('text/html').send(_resetHtml('error', token, 'Les mots de passe ne correspondent pas.'));
      }
      try {
        await resetPassword(token, newPassword);
        return reply.type('text/html').send(_resetHtml('success', ''));
      } catch {
        return reply.type('text/html').send(_resetHtml('invalid', ''));
      }
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

  // PATCH /api/auth/profile — authentifié, mise à jour du profil (nom, téléphone).
  r.patch(
    '/profile',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Auth'],
        summary: 'Mise à jour du profil (nom, téléphone)',
        description: 'Rôles autorisés : tous (authentifié).',
        security: [{ bearerAuth: [] }],
        body: z.object({
          name: z.string().min(1).max(100).optional(),
          telephone: z.string().max(30).optional(),
        }),
      },
    },
    async (request) => {
      const { name, telephone } = request.body as { name?: string; telephone?: string };
      return ok(await updateProfile(request.user!.id, name, telephone));
    },
  );

  // POST /api/auth/profile/photo — authentifié, upload photo de profil (base64 ≤ 2 Mo).
  r.post(
    '/profile/photo',
    {
      preHandler: authenticate,
      schema: {
        tags: ['Auth'],
        summary: 'Upload photo de profil (JPEG/PNG/WebP, max 2 Mo, base64)',
        description: 'Rôles autorisés : tous (authentifié).',
        security: [{ bearerAuth: [] }],
        body: z.object({
          imageBase64: z.string().min(1),
          mimeType: z.enum(['image/jpeg', 'image/jpg', 'image/png', 'image/webp']),
        }),
      },
    },
    async (request) => {
      const { imageBase64, mimeType } = request.body as { imageBase64: string; mimeType: string };
      return ok(await uploadProfilePhoto(request.user!.id, imageBase64, mimeType, app.adapters));
    },
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

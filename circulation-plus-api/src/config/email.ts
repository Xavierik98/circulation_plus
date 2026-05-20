/**
 * Service email — Circulation+
 *
 * Modes :
 *  - SMTP réel : SMTP_HOST + SMTP_USER + SMTP_PASS dans .env
 *  - Stub (développement) : aucune configuration requise,
 *    les emails sont loggés dans la console et le lien de vérification
 *    est retourné en clair dans la réponse API (NODE_ENV !== 'production').
 */
import nodemailer from 'nodemailer';
import { env } from './env.js';

// ── Détection du mode ─────────────────────────────────────────────────────────
const isConfigured =
  Boolean(process.env['SMTP_HOST']) &&
  Boolean(process.env['SMTP_USER']) &&
  Boolean(process.env['SMTP_PASS']);

// ── Transporter ──────────────────────────────────────────────────────────────
const transporter = isConfigured
  ? nodemailer.createTransport({
      host:   process.env['SMTP_HOST'],
      port:   Number(process.env['SMTP_PORT'] ?? 587),
      secure: process.env['SMTP_PORT'] === '465',
      auth: {
        user: process.env['SMTP_USER'],
        pass: process.env['SMTP_PASS'],
      },
    })
  : null;

const FROM_NAME    = 'Circulation+ Congo';
const FROM_ADDRESS = process.env['EMAIL_FROM'] ?? 'noreply@circulation-plus.cg';

// ── Template HTML ────────────────────────────────────────────────────────────
function verificationHtml(name: string, link: string): string {
  return `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: Arial, sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 20px; }
    .card { background: #1e293b; border-radius: 12px; max-width: 480px; margin: 40px auto; padding: 32px; }
    .logo { font-size: 22px; font-weight: 700; color: #3b82f6; margin-bottom: 24px; }
    h1 { font-size: 18px; margin: 0 0 12px; color: #f1f5f9; }
    p { font-size: 14px; color: #94a3b8; line-height: 1.6; }
    .btn { display: inline-block; background: linear-gradient(135deg,#3b82f6,#1e3a8a); color: #fff !important; text-decoration: none; padding: 14px 28px; border-radius: 8px; font-weight: 600; font-size: 15px; margin: 20px 0; }
    .footer { font-size: 11px; color: #475569; margin-top: 24px; border-top: 1px solid #334155; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🇨🇬 Circulation+</div>
    <h1>Confirmez votre adresse email</h1>
    <p>Bonjour <strong>${name}</strong>,</p>
    <p>Merci de vous être inscrit sur Circulation+, le portail citoyen de gestion des contraventions routières de la République du Congo.</p>
    <p>Cliquez sur le bouton ci-dessous pour activer votre compte :</p>
    <a class="btn" href="${link}">✅ Vérifier mon adresse email</a>
    <p>Ce lien expire dans <strong>24 heures</strong>. Si vous n'avez pas créé de compte, ignorez cet email.</p>
    <div class="footer">Police Nationale Congolaise · Circulation+ · Brazzaville, Congo</div>
  </div>
</body>
</html>`;
}

// ── Fonction principale ───────────────────────────────────────────────────────
export async function sendVerificationEmail(
  to: string,
  name: string,
  token: string,
): Promise<void> {
  const link = `${env.BASE_URL}/api/auth/verify-email?token=${token}`;

  if (!isConfigured) {
    // Mode stub : on affiche simplement le lien dans les logs.
    console.info(`\n📧  [EMAIL STUB] Vérification email pour ${to}`);
    console.info(`   Lien : ${link}\n`);
    return;
  }

  await transporter!.sendMail({
    from: `"${FROM_NAME}" <${FROM_ADDRESS}>`,
    to,
    subject: 'Circulation+ — Confirmez votre adresse email',
    html: verificationHtml(name, link),
  });
}

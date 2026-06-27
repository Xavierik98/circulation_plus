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

/** `true` si un SMTP réel est configuré (sinon mode stub — emails simulés en log). */
export const isEmailConfigured = isConfigured;

// ── Transporter ──────────────────────────────────────────────────────────────
// family: 4 — force IPv4. Sans ça, sur des hébergeurs sans routage IPv6
// (ex. Railway), Node résout smtp.gmail.com en AAAA et échoue avec
// "ENETUNREACH" en tentant de joindre l'adresse IPv6, alors que l'IPv4
// fonctionnerait. C'est la cause des emails jamais envoyés en production.
const transporter = isConfigured
  ? nodemailer.createTransport({
      host:   process.env['SMTP_HOST'],
      port:   Number(process.env['SMTP_PORT'] ?? 587),
      secure: process.env['SMTP_PORT'] === '465',
      auth: {
        user: process.env['SMTP_USER'],
        pass: process.env['SMTP_PASS'],
      },
      // `family` n'est pas dans les types nodemailer mais est transmis tel
      // quel à net.connect/tls.connect — voir commentaire ci-dessus.
      family: 4,
    } as nodemailer.TransportOptions)
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

// ── Template credentials agent ────────────────────────────────────────────────
function credentialsHtml(
  name: string,
  email: string,
  badgeNumber: string,
  password: string,
): string {
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
    .credentials-box { background: #0f172a; border: 1px solid #334155; border-radius: 8px; padding: 20px; margin: 20px 0; }
    .cred-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
    .cred-label { font-size: 12px; color: #64748b; text-transform: uppercase; letter-spacing: 1px; }
    .cred-value { font-size: 15px; font-weight: 700; color: #f1f5f9; font-family: monospace; }
    .password-value { font-size: 18px; font-weight: 700; color: #3b82f6; font-family: monospace; letter-spacing: 2px; }
    .warning { background: #422006; border: 1px solid #92400e; border-radius: 8px; padding: 14px; margin-top: 16px; }
    .warning p { color: #fbbf24; margin: 0; font-size: 13px; }
    .footer { font-size: 11px; color: #475569; margin-top: 24px; border-top: 1px solid #334155; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🇨🇬 Circulation+</div>
    <h1>Bienvenue dans Circulation+ — Vos identifiants de connexion</h1>
    <p>Bonjour <strong>${name}</strong>,</p>
    <p>Votre compte agent a été créé sur la plateforme Circulation+ de la Police Nationale Congolaise. Voici vos identifiants de connexion :</p>
    <div class="credentials-box">
      <div class="cred-row">
        <span class="cred-label">Email</span>
        <span class="cred-value">${email}</span>
      </div>
      <div class="cred-row">
        <span class="cred-label">Matricule</span>
        <span class="cred-value">${badgeNumber}</span>
      </div>
      <div class="cred-row" style="margin-bottom:0">
        <span class="cred-label">Mot de passe temporaire</span>
        <span class="password-value">${password}</span>
      </div>
    </div>
    <div class="warning">
      <p>⚠️ Ce mot de passe est temporaire. Vous serez invité à le changer à la première connexion.</p>
    </div>
    <div class="footer">Police Nationale Congolaise · Circulation+ · Brazzaville, Congo</div>
  </div>
</body>
</html>`;
}

// ── Envoi des credentials à un agent nouvellement créé ───────────────────────
export async function sendCredentialsEmail(
  to: string,
  name: string,
  email: string,
  password: string,
  badgeNumber: string,
): Promise<void> {
  if (!isConfigured) {
    console.info(`\n📧  [EMAIL STUB] Identifiants agent pour ${to}`);
    console.info(`   Email: ${email} | Matricule: ${badgeNumber} | Mot de passe: ${password}\n`);
    return;
  }

  await transporter!.sendMail({
    from: `"${FROM_NAME}" <${FROM_ADDRESS}>`,
    to,
    subject: 'Circulation+ — Vos identifiants de connexion',
    html: credentialsHtml(name, email, badgeNumber, password),
  });
}

// ── Template réinitialisation mot de passe ────────────────────────────────────
function passwordResetHtml(name: string, link: string): string {
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
    .btn { display: inline-block; background: linear-gradient(135deg,#ef4444,#b91c1c); color: #fff !important; text-decoration: none; padding: 14px 28px; border-radius: 8px; font-weight: 600; font-size: 15px; margin: 20px 0; }
    .warning { background: #1a0a0a; border: 1px solid #7f1d1d; border-radius: 8px; padding: 14px; margin-top: 16px; }
    .warning p { color: #fca5a5; margin: 0; font-size: 13px; }
    .footer { font-size: 11px; color: #475569; margin-top: 24px; border-top: 1px solid #334155; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🇨🇬 Circulation+</div>
    <h1>Réinitialisation de votre mot de passe</h1>
    <p>Bonjour <strong>${name}</strong>,</p>
    <p>Vous avez demandé la réinitialisation de votre mot de passe sur Circulation+. Cliquez sur le bouton ci-dessous :</p>
    <a class="btn" href="${link}">🔑 Réinitialiser mon mot de passe</a>
    <div class="warning">
      <p>⚠️ Ce lien expire dans <strong>1 heure</strong>. Si vous n'avez pas fait cette demande, ignorez cet email — votre mot de passe n'a pas été modifié.</p>
    </div>
    <div class="footer">Police Nationale Congolaise · Circulation+ · Brazzaville, Congo</div>
  </div>
</body>
</html>`;
}

function twoFaHtml(name: string, code: string): string {
  return `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: Arial, sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 20px; }
    .card { background: #1e293b; border-radius: 12px; max-width: 480px; margin: 40px auto; padding: 32px; text-align: center; }
    .logo { font-size: 22px; font-weight: 700; color: #3b82f6; margin-bottom: 24px; }
    h1 { font-size: 18px; margin: 0 0 12px; color: #f1f5f9; }
    p { font-size: 14px; color: #94a3b8; line-height: 1.6; }
    .code { font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #fff; background: #0f172a;
      border: 1px solid #334155; border-radius: 10px; padding: 16px 12px; margin: 20px 0; }
    .footer { font-size: 11px; color: #475569; margin-top: 24px; border-top: 1px solid #334155; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🇨🇬 Circulation+</div>
    <h1>Code de vérification (2FA)</h1>
    <p>Bonjour <strong>${name}</strong>, voici votre code de connexion :</p>
    <div class="code">${code}</div>
    <p>Ce code est valable 5 minutes. Ne le partagez avec personne.</p>
    <div class="footer">Si vous n'êtes pas à l'origine de cette connexion, ignorez cet email et changez votre mot de passe.</div>
  </div>
</body>
</html>`;
}

export async function send2faCode(to: string, name: string, code: string): Promise<void> {
  if (!isConfigured) {
    console.info(`\n🔐  [EMAIL STUB] Code 2FA pour ${to} : ${code}\n`);
    return;
  }

  await transporter!.sendMail({
    from: `"${FROM_NAME}" <${FROM_ADDRESS}>`,
    to,
    subject: 'Circulation+ — Votre code de vérification',
    html: twoFaHtml(name, code),
  });
}

export async function sendPasswordResetEmail(
  to: string,
  name: string,
  token: string,
): Promise<void> {
  const link = `${env.BASE_URL}/api/auth/reset-password?token=${token}`;

  if (!isConfigured) {
    console.info(`\n📧  [EMAIL STUB] Réinitialisation mot de passe pour ${to}`);
    console.info(`   Lien : ${link}\n`);
    return;
  }

  await transporter!.sendMail({
    from: `"${FROM_NAME}" <${FROM_ADDRESS}>`,
    to,
    subject: 'Circulation+ — Réinitialisation de votre mot de passe',
    html: passwordResetHtml(name, link),
  });
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

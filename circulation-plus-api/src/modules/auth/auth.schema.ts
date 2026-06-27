import { z } from 'zod';

// ── Politique mot de passe ISO 27001 / 27005 ─────────────────────────────────
// • Min 10 caractères, max 64
// • Au moins 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial
const PASSWORD_POLICY = z
  .string()
  .min(10, 'Le mot de passe doit contenir au moins 10 caractères')
  .max(64, 'Le mot de passe ne peut pas dépasser 64 caractères')
  .regex(/[A-Z]/, 'Le mot de passe doit contenir au moins une lettre majuscule')
  .regex(/[a-z]/, 'Le mot de passe doit contenir au moins une lettre minuscule')
  .regex(/[0-9]/, 'Le mot de passe doit contenir au moins un chiffre')
  .regex(
    /[!@#$%^&*()\-_=+\[\]{};:'",.<>/?\\|`~]/,
    'Le mot de passe doit contenir au moins un caractère spécial (!@#$%...)',
  );

// Le frontend envoie le rôle en minuscule ("police" | "citizen" | "admin").
// ⚠️  Pas de PASSWORD_POLICY ici : la vérification du mot de passe est faite
// par bcrypt. Appliquer la politique à la connexion bloquerait les anciens
// mots de passe et les mots de passe générés légitimes.
export const loginBodySchema = z.object({
  email: z.string().email(),
  pin:   z.string().min(1, 'Mot de passe requis'),
  role:  z.enum(['police', 'citizen', 'admin']),
  // Coordonnees GPS optionnelles envoyees par le client au moment du login.
  // Stockees dans AuditLog.details pour la traçabilite des connexions agents.
  lat:   z.number().min(-90).max(90).nullish(),
  lng:   z.number().min(-180).max(180).nullish(),
});
export type LoginBody = z.infer<typeof loginBodySchema>;

// 2FA obligatoire (POLICE / ADMIN) — code à 6 chiffres envoyé par email + SMS.
export const verify2faBodySchema = z.object({
  challengeToken: z.string().min(10),
  code:           z.string().length(6).regex(/^\d{6}$/, 'Code à 6 chiffres requis'),
});
export type Verify2faBody = z.infer<typeof verify2faBodySchema>;

export const resend2faBodySchema = z.object({
  challengeToken: z.string().min(10),
});
export type Resend2faBody = z.infer<typeof resend2faBodySchema>;

export const refreshBodySchema = z.object({
  refreshToken: z.string().min(10),
});
export type RefreshBody = z.infer<typeof refreshBodySchema>;

export const logoutBodySchema = z.object({
  refreshToken: z.string().min(10),
});
export type LogoutBody = z.infer<typeof logoutBodySchema>;

export const userPublicSchema = z.object({
  id:          z.string(),
  role:        z.enum(['POLICE', 'CITOYEN', 'ADMIN']),
  name:        z.string(),
  badgeNumber: z.string().nullable(),
  email:       z.string().optional(),
  telephone:   z.string().nullable().optional(),
  actif:       z.boolean().optional(),
});

// Inscription citoyen (auto-inscription publique)
export const registerBodySchema = z.object({
  name:      z.string().min(2).max(80),
  email:     z.string().email(),
  telephone: z.preprocess(
    (v) => (v === '' || v === null ? undefined : v),
    z.string().min(8).max(20).optional(),
  ),
  pin:       PASSWORD_POLICY,
});
export type RegisterBody = z.infer<typeof registerBodySchema>;

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Mot de passe actuel requis'),
  newPassword:     PASSWORD_POLICY,
});
export type ChangePasswordBody = z.infer<typeof changePasswordSchema>;

export const resendVerificationSchema = z.object({
  email: z.string().email(),
});
export type ResendVerificationBody = z.infer<typeof resendVerificationSchema>;

export const loginResponseSchema = z.object({
  success: z.literal(true),
  data: z.object({
    token:        z.string(),
    refreshToken: z.string(),
    user:         userPublicSchema,
  }),
});

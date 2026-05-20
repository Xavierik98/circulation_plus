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
export const loginBodySchema = z.object({
  email: z.string().email(),
  pin:   PASSWORD_POLICY,
  role:  z.enum(['police', 'citizen', 'admin']),
});
export type LoginBody = z.infer<typeof loginBodySchema>;

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
  telephone: z.string().min(8).max(20),
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

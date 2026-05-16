import { z } from 'zod';

// Le frontend envoie le rôle en minuscule ("police" | "citizen" | "admin").
export const loginBodySchema = z.object({
  email: z.string().email(),
  pin: z.string().min(4).max(12),
  role: z.enum(['police', 'citizen', 'admin']),
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
  id: z.string(),
  role: z.enum(['POLICE', 'CITOYEN', 'ADMIN']),
  name: z.string(),
  badgeNumber: z.string().nullable(),
  email: z.string().optional(),
  telephone: z.string().nullable().optional(),
  actif: z.boolean().optional(),
});

export const loginResponseSchema = z.object({
  success: z.literal(true),
  data: z.object({
    token: z.string(),
    refreshToken: z.string(),
    user: userPublicSchema,
  }),
});

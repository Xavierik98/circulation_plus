import { z } from 'zod';

// ── Domaine obligatoire pour les agents PNC ───────────────────────────────────
const PNC_DOMAIN = '@pnc.cg';
const pncEmail = z
  .string()
  .email('Email invalide')
  .refine((e) => e.toLowerCase().endsWith(PNC_DOMAIN), {
    message: `L'adresse email d'un agent doit se terminer par ${PNC_DOMAIN}`,
  });

// ── Politique mot de passe ISO 27001 / 27005 ─────────────────────────────────
const PASSWORD_POLICY = z
  .string()
  .min(10, 'Le mot de passe doit contenir au moins 10 caractères')
  .max(64, 'Le mot de passe ne peut pas dépasser 64 caractères')
  .regex(/[A-Z]/, 'Doit contenir au moins une majuscule')
  .regex(/[a-z]/, 'Doit contenir au moins une minuscule')
  .regex(/[0-9]/, 'Doit contenir au moins un chiffre')
  .regex(/[!@#$%^&*()\-_=+\[\]{};:'",.<>/?\\|`~]/, 'Doit contenir au moins un caractère spécial');

export const officersQuerySchema = z.object({
  page:   z.coerce.number().int().positive().default(1),
  limit:  z.coerce.number().int().positive().max(100).default(20),
  search: z.string().optional(),
});
export type OfficersQuery = z.infer<typeof officersQuerySchema>;

export const createOfficerSchema = z.object({
  email:       pncEmail,
  pin:         PASSWORD_POLICY,
  name:        z.string().min(2).max(80),
  badgeNumber: z.string().min(1),
  telephone:   z.string().min(8).max(20),
});
export type CreateOfficerBody = z.infer<typeof createOfficerSchema>;

export const updateOfficerSchema = z
  .object({
    email:       pncEmail.optional(),
    pin:         PASSWORD_POLICY.optional(),
    name:        z.string().min(2).max(80).optional(),
    badgeNumber: z.string().min(1).optional(),
    telephone:   z.string().min(8).max(20).optional(),
    actif:       z.boolean().optional(),
  })
  .refine((b) => Object.keys(b).length > 0, {
    message: 'Au moins un champ à modifier est requis',
  });
export type UpdateOfficerBody = z.infer<typeof updateOfficerSchema>;

export const officerIdParamsSchema = z.object({ id: z.string().uuid() });

// ── Import CSV ────────────────────────────────────────────────────────────────
// Le corps est le contenu brut du fichier CSV (Content-Type: text/plain)
// Format attendu : name,email,badge_number,telephone  (header optionnel)
export const importCsvSchema = z.object({
  csvContent: z.string().min(10, 'Contenu CSV vide ou invalide'),
});
export type ImportCsvBody = z.infer<typeof importCsvSchema>;

import { z } from 'zod';

export const createCommissariatSchema = z.object({
  nom:          z.string().min(3).max(100),
  code:         z.string().min(2).max(30).regex(/^[A-Z0-9_-]+$/, 'Code : lettres majuscules, chiffres, - ou _'),
  departement:  z.string().min(2).max(30),   // code du département (ex: BRAZZAVILLE)
  directionDepartementaleId: z.string().uuid().optional(),
  lat:          z.number().min(-90).max(90).optional(),
  lng:          z.number().min(-180).max(180).optional(),
  adresse:      z.string().max(200).optional(),
});

export const updateCommissariatSchema = z.object({
  nom:     z.string().min(3).max(100).optional(),
  lat:     z.number().min(-90).max(90).optional(),
  lng:     z.number().min(-180).max(180).optional(),
  adresse: z.string().max(200).optional(),
  actif:   z.boolean().optional(),
});

export const commissariatIdSchema = z.object({ id: z.string().uuid() });

export const listCommissariatsSchema = z.object({
  departement: z.string().optional(),   // code du département
  actif:       z.coerce.boolean().optional(),
  page:        z.coerce.number().int().positive().default(1),
  limit:       z.coerce.number().int().positive().max(200).default(50),
});

export type CreateCommissariatBody = z.infer<typeof createCommissariatSchema>;
export type UpdateCommissariatBody = z.infer<typeof updateCommissariatSchema>;

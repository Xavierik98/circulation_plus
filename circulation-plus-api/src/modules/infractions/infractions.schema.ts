import { z } from 'zod';

export const infractionItemSchema = z.object({
  id: z.string(),
  code: z.string(),
  libelle: z.string(),
  montantBase: z.number().int(),
  convocationObligatoire: z.boolean(),
});

export type InfractionItem = z.infer<typeof infractionItemSchema>;

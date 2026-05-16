import { z } from 'zod';

// Un des deux paramètres est requis : plaque OU numéro de permis.
export const driverQuerySchema = z
  .object({
    plate: z.string().optional(),
    license: z.string().optional(),
  })
  .refine((q) => Boolean(q.plate) || Boolean(q.license), {
    message: 'Le paramètre "plate" ou "license" est requis',
  });

export type DriverQuery = z.infer<typeof driverQuerySchema>;

import { z } from 'zod';

export const officersQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  search: z.string().optional(),
});
export type OfficersQuery = z.infer<typeof officersQuerySchema>;

export const createOfficerSchema = z.object({
  email: z.string().email(),
  pin: z.string().min(4).max(12),
  name: z.string().min(1),
  badgeNumber: z.string().min(1),
  telephone: z.string().min(1),
});
export type CreateOfficerBody = z.infer<typeof createOfficerSchema>;

export const updateOfficerSchema = z
  .object({
    email: z.string().email().optional(),
    pin: z.string().min(4).max(12).optional(),
    name: z.string().min(1).optional(),
    badgeNumber: z.string().min(1).optional(),
    telephone: z.string().min(1).optional(),
    actif: z.boolean().optional(),
  })
  .refine((b) => Object.keys(b).length > 0, {
    message: 'Au moins un champ à modifier est requis',
  });
export type UpdateOfficerBody = z.infer<typeof updateOfficerSchema>;

export const officerIdParamsSchema = z.object({ id: z.string().uuid() });

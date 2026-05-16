import { z } from 'zod';

export const finesQuerySchema = z.object({
  citizen: z.string().optional(),
  officer: z.string().optional(),
  status: z.enum(['PENDING', 'PAID', 'OVERDUE', 'CONTESTED']).optional(),
  dateFrom: z.string().datetime().optional(),
  dateTo: z.string().datetime().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});
export type FinesQuery = z.infer<typeof finesQuerySchema>;

export const createFineSchema = z.object({
  infractionTypeId: z.string().min(1),
  driverPhone: z.string().min(1),
  driverName: z.string().optional(),
  vehiclePlate: z.string().min(1),
  numeroPermis: z.string().optional(),
  numeroCarteGrise: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  adresseApprox: z.string().optional(),
  signatureAgent: z.string().optional(),
  signatureContrevenant: z.string().optional(),
  refusSignature: z.boolean().optional(),
  deviceId: z.string().optional(),
  verbaliseLe: z.string().datetime(),
});
export type CreateFineBody = z.infer<typeof createFineSchema>;

export const fineIdParamsSchema = z.object({ id: z.string().uuid() });

export const updateStatusSchema = z.object({
  status: z.enum(['CONTESTED', 'PAID', 'OVERDUE', 'PENDING']),
});
export type UpdateStatusBody = z.infer<typeof updateStatusSchema>;

export const payFineSchema = z.object({
  operateur: z.enum(['MTN', 'AIRTEL']),
  telephone: z.string().min(1),
});
export type PayFineBody = z.infer<typeof payFineSchema>;

export const syncFinesSchema = z.object({
  fines: z.array(createFineSchema).min(1),
});
export type SyncFinesBody = z.infer<typeof syncFinesSchema>;

export const fineReferenceParamsSchema = z.object({
  reference: z.string().min(1),
});

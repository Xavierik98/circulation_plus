import { z } from 'zod';

export const initiatePaymentSchema = z.object({
  fineId: z.string().min(1),
  operateur: z.enum(['MTN', 'AIRTEL']),
  telephone: z.string().min(1),
});
export type InitiatePaymentBody = z.infer<typeof initiatePaymentSchema>;

export const tresorPaymentSchema = z.object({
  fineId: z.string().min(1),
  quittanceNumero: z.string().min(1),
  quittanceDate: z.string().optional(), // ISO date string (YYYY-MM-DD)
  agentTresor: z.string().optional(),
});
export type TresorPaymentBody = z.infer<typeof tresorPaymentSchema>;

export const receiptParamsSchema = z.object({ id: z.string().min(1) });

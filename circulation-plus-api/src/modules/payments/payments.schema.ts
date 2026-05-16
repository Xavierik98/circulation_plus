import { z } from 'zod';

export const initiatePaymentSchema = z.object({
  fineId: z.string().min(1),
  operateur: z.enum(['MTN', 'AIRTEL']),
  telephone: z.string().min(1),
});
export type InitiatePaymentBody = z.infer<typeof initiatePaymentSchema>;

export const receiptParamsSchema = z.object({ id: z.string().min(1) });

import { z } from 'zod';

export const vehicleParamsSchema = z.object({
  plate: z.string().min(1),
});

export type VehicleParams = z.infer<typeof vehicleParamsSchema>;

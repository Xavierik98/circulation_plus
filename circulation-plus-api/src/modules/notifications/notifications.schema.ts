import { z } from 'zod';

export const notificationsQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  unreadOnly: z
    .union([z.boolean(), z.enum(['true', 'false'])])
    .transform((v) => v === true || v === 'true')
    .optional(),
});
export type NotificationsQuery = z.infer<typeof notificationsQuerySchema>;

export const notificationIdParamsSchema = z.object({ id: z.string().uuid() });

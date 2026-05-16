import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';

// Chaque utilisateur ne voit que ses propres notifications (RLS).
export async function listNotifications(params: {
  userId: string;
  page: number;
  limit: number;
  unreadOnly?: boolean;
}): Promise<{ items: unknown[]; total: number }> {
  const where: Prisma.NotificationWhereInput = { userId: params.userId };
  if (params.unreadOnly) {
    where.read = false;
  }

  const [items, total] = await Promise.all([
    prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (params.page - 1) * params.limit,
      take: params.limit,
    }),
    prisma.notification.count({ where }),
  ]);

  return { items, total };
}

export async function markAsRead(userId: string, notificationId: string) {
  const notif = await prisma.notification.findUnique({
    where: { id: notificationId },
  });
  // Ressource d'un autre utilisateur => 404 (pas de fuite d'existence).
  if (!notif || notif.userId !== userId) {
    throw AppError.notFound('Notification introuvable', 'NOTIFICATION_NOT_FOUND');
  }

  return prisma.notification.update({
    where: { id: notificationId },
    data: { read: true },
  });
}

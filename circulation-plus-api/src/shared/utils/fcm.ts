import type { PrismaClient, Prisma } from '@prisma/client';
import type { PushProvider } from '../../adapters/types';

export interface NotifyInput {
  userId: string;
  fcmToken: string | null;
  title: string;
  body: string;
  type: string;
  data?: Prisma.InputJsonValue;
}

// Crée la Notification durable (canal de référence, testé) puis tente le push
// FCM best-effort. L'échec du push n'interrompt jamais le flux métier.
export async function notify(
  prisma: PrismaClient,
  push: PushProvider,
  input: NotifyInput,
): Promise<void> {
  await prisma.notification.create({
    data: {
      userId: input.userId,
      title: input.title,
      body: input.body,
      type: input.type,
      data: input.data,
    },
  });

  try {
    const stringData: Record<string, string> = {};
    if (input.data && typeof input.data === 'object' && !Array.isArray(input.data)) {
      for (const [k, v] of Object.entries(input.data)) {
        stringData[k] = String(v);
      }
    }
    await push.send(input.fcmToken, {
      title: input.title,
      body: input.body,
      data: stringData,
    });
  } catch {
    // Push non bloquant.
  }
}

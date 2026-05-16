import type admin from 'firebase-admin';
import type { PushProvider, PushPayload } from '../types';

// Implémentation réelle des notifications push via Firebase Cloud Messaging.
export class FcmPushProvider implements PushProvider {
  readonly mode = 'real' as const;

  constructor(private readonly messaging: admin.messaging.Messaging) {}

  async send(token: string | null, payload: PushPayload): Promise<{ ok: boolean }> {
    if (!token) {
      // Pas de token enregistré pour cet utilisateur : on ignore silencieusement.
      return { ok: false };
    }
    try {
      await this.messaging.send({
        token,
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
      });
      return { ok: true };
    } catch {
      return { ok: false };
    }
  }
}

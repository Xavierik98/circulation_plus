import type { PushProvider, PushPayload } from '../types';

// Stub push : journalise la notification au lieu de l'envoyer via FCM.
export class StubPushProvider implements PushProvider {
  readonly mode = 'stub' as const;

  async send(token: string | null, payload: PushPayload): Promise<{ ok: boolean }> {
    // eslint-disable-next-line no-console
    console.log(
      `[PUSH:STUB] token=${token ?? 'none'} title="${payload.title}" body="${payload.body}"`,
    );
    return { ok: true };
  }
}

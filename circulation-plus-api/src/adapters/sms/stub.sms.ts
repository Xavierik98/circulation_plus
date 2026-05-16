import type { SmsProvider } from '../types';

// Stub SMS : journalise le message au lieu de l'envoyer. Permet de faire
// fonctionner toute la chaîne sans credentials Africa's Talking.
export class StubSmsProvider implements SmsProvider {
  readonly mode = 'stub' as const;

  async send(
    to: string,
    message: string,
  ): Promise<{ ok: boolean; providerMessageId?: string }> {
    // eslint-disable-next-line no-console
    console.log(`[SMS:STUB] -> ${to}\n${message}\n`);
    return { ok: true, providerMessageId: `stub-${Date.now()}` };
  }
}

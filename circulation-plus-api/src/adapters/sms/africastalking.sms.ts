import AfricasTalking from 'africastalking';
import type { SmsProvider } from '../types';

// Implémentation réelle SMS via Africa's Talking (couvre le Congo-Brazzaville).
export class AfricasTalkingSmsProvider implements SmsProvider {
  readonly mode = 'real' as const;
  private readonly sms: { send: (opts: Record<string, unknown>) => Promise<unknown> };

  constructor(apiKey: string, username: string, private readonly senderId: string) {
    const client = AfricasTalking({ apiKey, username });
    this.sms = client.SMS;
  }

  async send(
    to: string,
    message: string,
  ): Promise<{ ok: boolean; providerMessageId?: string }> {
    try {
      const result = (await this.sms.send({
        to: [to],
        message,
        from: this.senderId,
      })) as { SMSMessageData?: { Recipients?: Array<{ messageId?: string }> } };
      const messageId = result.SMSMessageData?.Recipients?.[0]?.messageId;
      return { ok: true, providerMessageId: messageId };
    } catch {
      // L'échec d'un SMS ne doit jamais interrompre la transaction métier.
      return { ok: false };
    }
  }
}

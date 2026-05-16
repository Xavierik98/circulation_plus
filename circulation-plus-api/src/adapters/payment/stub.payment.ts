import { randomUUID } from 'node:crypto';
import type {
  PaymentProvider,
  PaymentInitiateInput,
  PaymentInitiateResult,
  WebhookVerification,
} from '../types';

// Stub paiement : renvoie une URL locale (${BASE_URL}/__stub_pay/<reference>)
// qui, une fois ouverte, déclenche un webhook confirmé synthétique. Permet
// de tester toute la chaîne paiement + répartition sans credentials CinetPay.
export class StubPaymentProvider implements PaymentProvider {
  readonly mode = 'stub' as const;

  constructor(private readonly baseUrl: string) {}

  async initiate(input: PaymentInitiateInput): Promise<PaymentInitiateResult> {
    const providerTxId = `stub-tx-${randomUUID()}`;
    return {
      paymentUrl: `${this.baseUrl}/__stub_pay/${encodeURIComponent(input.reference)}?tx=${providerTxId}`,
      providerTxId,
    };
  }

  verifyWebhook(
    rawBody: Buffer,
    headers: Record<string, string | string[] | undefined>,
  ): WebhookVerification {
    const signature = headers['x-stub-signature'];
    if (signature !== 'stub') {
      return { valid: false, transactionId: '', status: 'FAILED' };
    }
    try {
      const parsed = JSON.parse(rawBody.toString('utf-8')) as {
        transactionId?: string;
        status?: string;
      };
      return {
        valid: typeof parsed.transactionId === 'string' && parsed.transactionId.length > 0,
        transactionId: parsed.transactionId ?? '',
        status: parsed.status === 'FAILED' ? 'FAILED' : 'CONFIRMED',
      };
    } catch {
      return { valid: false, transactionId: '', status: 'FAILED' };
    }
  }
}

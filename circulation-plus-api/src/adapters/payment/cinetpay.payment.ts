import { createHmac, timingSafeEqual } from 'node:crypto';
import type {
  PaymentProvider,
  PaymentInitiateInput,
  PaymentInitiateResult,
  WebhookVerification,
} from '../types';

export interface CinetPayConfig {
  apiKey: string;
  siteId: string;
  webhookSecret: string;
  baseUrl: string;
}

const CINETPAY_ENDPOINT = 'https://api-checkout.cinetpay.com/v2/payment';

// Implémentation réelle Mobile Money via CinetPay (MTN Congo + Airtel Congo).
export class CinetPayPaymentProvider implements PaymentProvider {
  readonly mode = 'real' as const;

  constructor(private readonly config: CinetPayConfig) {}

  async initiate(input: PaymentInitiateInput): Promise<PaymentInitiateResult> {
    const response = await fetch(CINETPAY_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        apikey: this.config.apiKey,
        site_id: this.config.siteId,
        transaction_id: input.reference,
        amount: input.amount,
        currency: 'XAF',
        channels: input.operator === 'MTN' ? 'MOBILE_MONEY' : 'MOBILE_MONEY',
        customer_phone_number: input.phone,
        description: `Paiement contravention ${input.reference}`,
        notify_url: `${this.config.baseUrl}/api/payments/confirm`,
        return_url: `${this.config.baseUrl}/api/payments/confirm`,
      }),
    });

    const json = (await response.json()) as {
      code?: string;
      data?: { payment_url?: string; payment_token?: string };
    };

    if (json.code !== '201' || !json.data?.payment_url) {
      throw new Error(`Échec d'initiation CinetPay (code ${json.code ?? 'inconnu'})`);
    }

    return {
      paymentUrl: json.data.payment_url,
      providerTxId: json.data.payment_token ?? input.reference,
    };
  }

  verifyWebhook(
    rawBody: Buffer,
    headers: Record<string, string | string[] | undefined>,
  ): WebhookVerification {
    const headerToken = headers['x-token'];
    const token = Array.isArray(headerToken) ? headerToken[0] : headerToken;
    if (!token) {
      return { valid: false, transactionId: '', status: 'FAILED' };
    }

    const expected = createHmac('sha256', this.config.webhookSecret)
      .update(rawBody)
      .digest('hex');

    const a = Buffer.from(expected);
    const b = Buffer.from(token);
    const signatureValid = a.length === b.length && timingSafeEqual(a, b);
    if (!signatureValid) {
      return { valid: false, transactionId: '', status: 'FAILED' };
    }

    try {
      const parsed = JSON.parse(rawBody.toString('utf-8')) as {
        cpm_trans_id?: string;
        cpm_result?: string;
      };
      return {
        valid: typeof parsed.cpm_trans_id === 'string',
        transactionId: parsed.cpm_trans_id ?? '',
        status: parsed.cpm_result === '00' ? 'CONFIRMED' : 'FAILED',
      };
    } catch {
      return { valid: false, transactionId: '', status: 'FAILED' };
    }
  }
}

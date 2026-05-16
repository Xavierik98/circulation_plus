// Interfaces des fournisseurs externes. Chaque fournisseur a une implémentation
// réelle (SDK/HTTP) et une implémentation stub (journalisée) sélectionnée au
// démarrage selon la présence des variables d'environnement.

export interface SmsProvider {
  readonly mode: 'real' | 'stub';
  send(to: string, message: string): Promise<{ ok: boolean; providerMessageId?: string }>;
}

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface PushProvider {
  readonly mode: 'real' | 'stub';
  send(token: string | null, payload: PushPayload): Promise<{ ok: boolean }>;
}

export interface StorageProvider {
  readonly mode: 'real' | 'stub';
  upload(key: string, bytes: Buffer, contentType: string): Promise<{ key: string }>;
  signedUrl(key: string, expiresInSeconds: number): Promise<string>;
}

export interface PaymentInitiateInput {
  reference: string;
  amount: number;
  phone: string;
  operator: 'MTN' | 'AIRTEL';
}

export interface PaymentInitiateResult {
  paymentUrl: string;
  providerTxId: string;
}

export interface WebhookVerification {
  valid: boolean;
  transactionId: string;
  status: 'CONFIRMED' | 'FAILED';
}

export interface PaymentProvider {
  readonly mode: 'real' | 'stub';
  initiate(input: PaymentInitiateInput): Promise<PaymentInitiateResult>;
  verifyWebhook(
    rawBody: Buffer,
    headers: Record<string, string | string[] | undefined>,
  ): WebhookVerification;
}

export interface Adapters {
  sms: SmsProvider;
  push: PushProvider;
  storage: StorageProvider;
  payment: PaymentProvider;
}

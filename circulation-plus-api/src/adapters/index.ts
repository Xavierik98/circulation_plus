import type { FastifyBaseLogger } from 'fastify';
import { env } from '../config/env';
import { getFirebaseMessaging } from '../config/firebase';
import type { Adapters } from './types';
import { StubSmsProvider } from './sms/stub.sms';
import { AfricasTalkingSmsProvider } from './sms/africastalking.sms';
import { StubPushProvider } from './push/stub.push';
import { FcmPushProvider } from './push/fcm.push';
import { StubStorageProvider } from './storage/stub.storage';
import { R2StorageProvider } from './storage/r2.storage';
import { StubPaymentProvider } from './payment/stub.payment';
import { CinetPayPaymentProvider } from './payment/cinetpay.payment';

// Construit le bundle d'adaptateurs : implémentation réelle si la configuration
// est complète, sinon stub journalisé (le projet démarre sans aucune clé).
export function buildAdapters(logger: FastifyBaseLogger): Adapters {
  const sms =
    env.AT_API_KEY && env.AT_USERNAME
      ? new AfricasTalkingSmsProvider(env.AT_API_KEY, env.AT_USERNAME, env.AT_SENDER_ID)
      : new StubSmsProvider();
  if (sms.mode === 'stub') {
    logger.warn('[adapters] SMS : mode STUB (AT_API_KEY / AT_USERNAME absents)');
  }

  const firebaseMessaging = getFirebaseMessaging();
  const push = firebaseMessaging
    ? new FcmPushProvider(firebaseMessaging)
    : new StubPushProvider();
  if (push.mode === 'stub') {
    logger.warn('[adapters] PUSH : mode STUB (configuration Firebase absente)');
  }

  const storage =
    env.R2_ACCOUNT_ID && env.R2_ACCESS_KEY_ID && env.R2_SECRET_ACCESS_KEY
      ? new R2StorageProvider({
          accountId: env.R2_ACCOUNT_ID,
          accessKeyId: env.R2_ACCESS_KEY_ID,
          secretAccessKey: env.R2_SECRET_ACCESS_KEY,
          bucket: env.R2_BUCKET_NAME,
        })
      : new StubStorageProvider(env.BASE_URL);
  if (storage.mode === 'stub') {
    logger.warn('[adapters] STORAGE : mode STUB (configuration R2 absente)');
  }

  const payment =
    env.CINETPAY_API_KEY && env.CINETPAY_SITE_ID && env.CINETPAY_WEBHOOK_SECRET
      ? new CinetPayPaymentProvider({
          apiKey: env.CINETPAY_API_KEY,
          siteId: env.CINETPAY_SITE_ID,
          webhookSecret: env.CINETPAY_WEBHOOK_SECRET,
          baseUrl: env.BASE_URL,
        })
      : new StubPaymentProvider(env.BASE_URL);
  if (payment.mode === 'stub') {
    logger.warn('[adapters] PAYMENT : mode STUB (configuration CinetPay absente)');
  }

  return { sms, push, storage, payment };
}

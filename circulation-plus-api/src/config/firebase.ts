import admin from 'firebase-admin';
import { env } from './env';

// Initialise le SDK Firebase Admin uniquement si la configuration est présente.
// Sinon, l'adaptateur push bascule en mode stub.
let messaging: admin.messaging.Messaging | null = null;

export function getFirebaseMessaging(): admin.messaging.Messaging | null {
  if (messaging) return messaging;

  if (
    !env.FIREBASE_PROJECT_ID ||
    !env.FIREBASE_PRIVATE_KEY ||
    !env.FIREBASE_CLIENT_EMAIL
  ) {
    return null;
  }

  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: env.FIREBASE_PROJECT_ID,
        clientEmail: env.FIREBASE_CLIENT_EMAIL,
        // Les sauts de ligne sont échappés dans les variables d'environnement.
        privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
  }

  messaging = admin.messaging();
  return messaging;
}

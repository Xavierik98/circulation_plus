import { Redis } from 'ioredis';
import { env } from './env';

// Singleton Redis — utilisé pour les refresh tokens, le verrouillage de compte,
// le compteur de tentatives de connexion et le cache du catalogue d'infractions.
const globalForRedis = globalThis as unknown as { redis?: Redis };

export const redis =
  globalForRedis.redis ??
  new Redis(env.REDIS_URL, {
    maxRetriesPerRequest: 3,
    lazyConnect: false,
  });

if (env.NODE_ENV !== 'production') {
  globalForRedis.redis = redis;
}

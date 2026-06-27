import 'dotenv/config';
import { z } from 'zod';

// Transforme une chaîne vide (variable « présente mais non renseignée ») en undefined,
// ce qui déclenche le mode stub de l'adaptateur correspondant.
const optionalStr = z
  .string()
  .transform((value) => (value.trim() === '' ? undefined : value))
  .optional();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  BASE_URL: z.string().url().default('http://localhost:3000'),
  CORS_ORIGINS: z.string().default('*'),

  DATABASE_URL: z.string().min(1, 'DATABASE_URL est requis'),
  // Base de secours (Supabase) — copie périodique complète depuis DATABASE_URL
  // (Neon). La sauvegarde automatique est désactivée si absent.
  SUPABASE_DATABASE_URL: optionalStr,
  REDIS_URL: z.string().min(1, 'REDIS_URL est requis'),

  JWT_SECRET: z.string().min(32, 'JWT_SECRET doit faire au moins 32 caractères'),
  JWT_REFRESH_SECRET: z
    .string()
    .min(32, 'JWT_REFRESH_SECRET doit faire au moins 32 caractères'),

  // SMS — Africa's Talking
  AT_API_KEY: optionalStr,
  AT_USERNAME: optionalStr,
  AT_SENDER_ID: z.string().default('CirculationPlus'),

  // Mobile Money — CinetPay
  CINETPAY_API_KEY: optionalStr,
  CINETPAY_SITE_ID: optionalStr,
  CINETPAY_WEBHOOK_SECRET: optionalStr,

  // Firebase FCM
  FIREBASE_PROJECT_ID: optionalStr,
  FIREBASE_PRIVATE_KEY: optionalStr,
  FIREBASE_CLIENT_EMAIL: optionalStr,

  // Cloudflare R2
  R2_ACCOUNT_ID: optionalStr,
  R2_ACCESS_KEY_ID: optionalStr,
  R2_SECRET_ACCESS_KEY: optionalStr,
  R2_BUCKET_NAME: z.string().default('circulation-plus-pdfs'),
  R2_PUBLIC_URL: optionalStr,

  // Répartition financière (XAF)
  PART_DEVELOPPEUR: z.coerce.number().int().nonnegative().default(1000),
  PART_AGENT: z.coerce.number().int().nonnegative().default(0),
  PART_POLICE: z.coerce.number().int().nonnegative().default(0),
  PART_TRESOR: z.coerce.number().int().nonnegative().default(0),

  // Comptes Mobile Money de versement (MTN ou Airtel Congo)
  // COMPTE_DEVELOPPEUR : numéro recevant les 1 000 XAF de frais plateforme
  // COMPTE_POLICE      : numéro recevant la part amende officielle (police/trésor)
  COMPTE_DEVELOPPEUR: optionalStr,
  COMPTE_POLICE: optionalStr,

  // Convocations
  DELAI_CONVOCATION_JOURS: z.coerce.number().int().positive().default(7),
  DELAI_RELANCE_JOURS: z.coerce.number().int().positive().default(14),
});

export type Env = z.infer<typeof envSchema>;

function loadEnv(): Env {
  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `  - ${issue.path.join('.')}: ${issue.message}`)
      .join('\n');
    // Échec rapide : configuration invalide => on refuse de démarrer.
    throw new Error(`Configuration d'environnement invalide :\n${issues}`);
  }
  return parsed.data;
}

export const env = loadEnv();

export const isProduction = env.NODE_ENV === 'production';
export const isTest = env.NODE_ENV === 'test';

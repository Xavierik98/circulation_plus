import { defineConfig } from 'vitest/config';
import 'dotenv/config'; // charge .env avant d'évaluer les URLs

// Tests use TEST_DATABASE_URL if set; otherwise falls back to DATABASE_URL (Neon).
// This allows sharing the same Neon DB for tests — setup.ts truncates tables before each test.
const TEST_DATABASE_URL =
  process.env.TEST_DATABASE_URL ??
  process.env.DATABASE_URL ??
  'postgresql://postgres:password@localhost:5432/circulation_test';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
    globalSetup: ['tests/globalSetup.ts'],
    setupFiles: ['tests/setup.ts'],
    fileParallelism: false,
    testTimeout: 30000,
    hookTimeout: 60000,
    env: {
      NODE_ENV: 'test',
      DATABASE_URL: TEST_DATABASE_URL,
      REDIS_URL: process.env.TEST_REDIS_URL ?? process.env.REDIS_URL ?? 'redis://localhost:6379',
      BASE_URL: 'http://localhost:3000',
      CORS_ORIGINS: '*',
      JWT_SECRET: 'test_jwt_secret_at_least_32_characters_long',
      JWT_REFRESH_SECRET: 'test_refresh_secret_at_least_32_characters_long',
      PART_DEVELOPPEUR: '1000',
      PART_AGENT: '0',
      PART_POLICE: '0',
      PART_TRESOR: '0',
    },
  },
});

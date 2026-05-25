import { execSync } from 'node:child_process';
import 'dotenv/config'; // charge .env avant tout

const TEST_DATABASE_URL =
  process.env.TEST_DATABASE_URL ??
  process.env.DATABASE_URL ??
  'postgresql://postgres:password@localhost:5432/circulation_test';

// Applique le schéma sur la base de test une seule fois avant toute la suite.
export default function setup(): void {
  execSync('npx prisma migrate deploy', {
    stdio: 'inherit',
    env: { ...process.env, DATABASE_URL: TEST_DATABASE_URL },
  });
}

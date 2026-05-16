import { beforeEach, afterAll } from 'vitest';
import { prisma } from '../src/config/database';
import { redis } from '../src/config/redis';

// Isolation : on vide toutes les tables et Redis avant chaque test.
beforeEach(async () => {
  const tables = await prisma.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'`;
  if (tables.length > 0) {
    const list = tables.map((t) => `"public"."${t.tablename}"`).join(', ');
    await prisma.$executeRawUnsafe(
      `TRUNCATE ${list} RESTART IDENTITY CASCADE`,
    );
  }
  await redis.flushdb();
});

afterAll(async () => {
  await prisma.$disconnect();
  redis.disconnect();
});

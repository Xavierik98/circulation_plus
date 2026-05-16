import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import type { InfractionItem } from './infractions.schema';

const CACHE_KEY = 'cache:infractions:active';
const CACHE_TTL_SECONDS = 3600; // 1 heure

// Catalogue public des infractions actives, mis en cache Redis 1h.
export async function listActiveInfractions(): Promise<InfractionItem[]> {
  const cached = await redis.get(CACHE_KEY);
  if (cached) {
    return JSON.parse(cached) as InfractionItem[];
  }

  const rows = await prisma.infractionType.findMany({
    where: { actif: true },
    orderBy: { code: 'asc' },
    select: {
      id: true,
      code: true,
      libelle: true,
      montantBase: true,
      convocationObligatoire: true,
    },
  });

  await redis.set(CACHE_KEY, JSON.stringify(rows), 'EX', CACHE_TTL_SECONDS);
  return rows;
}

// À appeler si l'administration modifie le catalogue.
export async function invalidateInfractionsCache(): Promise<void> {
  await redis.del(CACHE_KEY);
}

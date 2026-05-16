import { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';

interface DateRange {
  dateFrom?: string;
  dateTo?: string;
}

export interface RevenueStats {
  totalCollected: number;
  totalFines: number;
  paidFines: number;
  pendingFines: number;
  overdueFines: number;
  byDay: { date: string; amount: number; count: number }[];
  byInfraction: { code: string; libelle: string; count: number; amount: number }[];
}

export async function getRevenueStats(range: DateRange): Promise<RevenueStats> {
  const from = range.dateFrom ? new Date(range.dateFrom) : undefined;
  const to = range.dateTo ? new Date(range.dateTo) : undefined;

  const fineDateFilter: Prisma.FineWhereInput =
    from || to
      ? { verbaliseLe: { ...(from ? { gte: from } : {}), ...(to ? { lte: to } : {}) } }
      : {};

  const [collected, totalFines, paidFines, pendingFines, overdueFines] =
    await Promise.all([
      prisma.payment.aggregate({
        where: {
          status: 'CONFIRMED',
          ...(from || to
            ? { confirmedAt: { ...(from ? { gte: from } : {}), ...(to ? { lte: to } : {}) } }
            : {}),
        },
        _sum: { montantTotal: true },
      }),
      prisma.fine.count({ where: fineDateFilter }),
      prisma.fine.count({ where: { ...fineDateFilter, status: 'PAID' } }),
      prisma.fine.count({ where: { ...fineDateFilter, status: 'PENDING' } }),
      prisma.fine.count({ where: { ...fineDateFilter, status: 'OVERDUE' } }),
    ]);

  const conds: Prisma.Sql[] = [
    Prisma.sql`"status" = 'CONFIRMED'`,
    Prisma.sql`"confirmedAt" IS NOT NULL`,
  ];
  if (from) conds.push(Prisma.sql`"confirmedAt" >= ${from}`);
  if (to) conds.push(Prisma.sql`"confirmedAt" <= ${to}`);
  const whereSql = Prisma.join(conds, ' AND ');

  const byDayRows = await prisma.$queryRaw<
    { date: string; amount: number; count: number }[]
  >`
    SELECT to_char(date_trunc('day', "confirmedAt"), 'YYYY-MM-DD') AS date,
           SUM("montantTotal")::int AS amount,
           COUNT(*)::int AS count
    FROM "Payment"
    WHERE ${whereSql}
    GROUP BY 1
    ORDER BY 1`;

  const grouped = await prisma.fine.groupBy({
    by: ['infractionTypeId'],
    where: { ...fineDateFilter, status: 'PAID' },
    _count: { _all: true },
    _sum: { montantTotal: true },
  });
  const types = await prisma.infractionType.findMany({
    where: { id: { in: grouped.map((g) => g.infractionTypeId) } },
    select: { id: true, code: true, libelle: true },
  });
  const typeMap = new Map(types.map((t) => [t.id, t]));
  const byInfraction = grouped.map((g) => {
    const t = typeMap.get(g.infractionTypeId);
    return {
      code: t?.code ?? 'INCONNU',
      libelle: t?.libelle ?? 'Inconnu',
      count: g._count._all,
      amount: g._sum.montantTotal ?? 0,
    };
  });

  return {
    totalCollected: collected._sum.montantTotal ?? 0,
    totalFines,
    paidFines,
    pendingFines,
    overdueFines,
    byDay: byDayRows.map((r) => ({
      date: r.date,
      amount: Number(r.amount),
      count: Number(r.count),
    })),
    byInfraction,
  };
}

export async function getHeatmap(): Promise<
  { latitude: number; longitude: number; count: number }[]
> {
  const rows = await prisma.$queryRaw<
    { latitude: number; longitude: number; count: number }[]
  >`
    SELECT ROUND("latitude"::numeric, 3)::float8 AS latitude,
           ROUND("longitude"::numeric, 3)::float8 AS longitude,
           COUNT(*)::int AS count
    FROM "Fine"
    WHERE "latitude" IS NOT NULL AND "longitude" IS NOT NULL
    GROUP BY 1, 2`;

  return rows.map((r) => ({
    latitude: Number(r.latitude),
    longitude: Number(r.longitude),
    count: Number(r.count),
  }));
}

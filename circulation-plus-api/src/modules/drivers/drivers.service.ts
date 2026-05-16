import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';

// Recherche d'un conducteur par plaque ou numéro de permis,
// avec ses véhicules et ses 5 dernières contraventions.
export async function findDriver(params: {
  plate?: string;
  license?: string;
}) {
  let driverId: string | null = null;

  if (params.license) {
    const driver = await prisma.driver.findUnique({
      where: { numeroPermis: params.license },
    });
    driverId = driver?.id ?? null;
  } else if (params.plate) {
    const vehicle = await prisma.vehicle.findUnique({
      where: { plaque: params.plate },
    });
    driverId = vehicle?.driverId ?? null;
  }

  if (!driverId) {
    throw AppError.notFound('Aucun conducteur trouvé pour ces critères', 'DRIVER_NOT_FOUND');
  }

  const driver = await prisma.driver.findUnique({
    where: { id: driverId },
    include: {
      vehicles: true,
      fines: {
        orderBy: { verbaliseLe: 'desc' },
        take: 5,
        include: { infractionType: true },
      },
    },
  });

  if (!driver) {
    throw AppError.notFound('Conducteur introuvable', 'DRIVER_NOT_FOUND');
  }

  return driver;
}

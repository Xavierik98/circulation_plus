import { prisma } from '../../config/database';
import { AppError } from '../../shared/errors/AppError';

// Récupère un véhicule par sa plaque, avec le conducteur associé.
export async function findVehicleByPlate(plate: string) {
  const vehicle = await prisma.vehicle.findUnique({
    where: { plaque: plate },
    include: { driver: true },
  });

  if (!vehicle) {
    throw AppError.notFound('Véhicule introuvable', 'VEHICLE_NOT_FOUND');
  }

  return vehicle;
}

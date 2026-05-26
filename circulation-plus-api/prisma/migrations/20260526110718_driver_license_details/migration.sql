-- AlterTable
ALTER TABLE "Driver" ADD COLUMN     "categoriesPermis" TEXT NOT NULL DEFAULT 'B',
ADD COLUMN     "dateDelivrancePermis" TIMESTAMP(3),
ADD COLUMN     "dateExpirationPermis" TIMESTAMP(3),
ADD COLUMN     "dateNaissance" TIMESTAMP(3),
ADD COLUMN     "lieuDelivrance" TEXT,
ADD COLUMN     "permisSuspendu" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "photoUrl" TEXT,
ADD COLUMN     "pointsPermis" INTEGER NOT NULL DEFAULT 12,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

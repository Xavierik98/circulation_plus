-- Add photoUrl to User
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "photoUrl" TEXT;

-- Add missing Payment index
CREATE INDEX IF NOT EXISTS "Payment_quittanceNumero_idx" ON "Payment"("quittanceNumero");

-- Fix nullable mismatches from schema
ALTER TABLE "Commissariat" ALTER COLUMN "departementId" SET NOT NULL;

ALTER TABLE "Departement" ALTER COLUMN "updatedAt" DROP DEFAULT;
ALTER TABLE "DirectionDepartementale" ALTER COLUMN "updatedAt" DROP DEFAULT;
ALTER TABLE "DirectionGenerale" ALTER COLUMN "updatedAt" DROP DEFAULT;
ALTER TABLE "DirectionNationale" ALTER COLUMN "updatedAt" DROP DEFAULT;
ALTER TABLE "Unite" ALTER COLUMN "updatedAt" DROP DEFAULT;

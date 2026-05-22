-- Migration: add_agent_status_gps_and_sanctions
-- Adds onDuty/GPS fields to User and the Sanction model with SanctionType enum.

-- Agent status & GPS fields
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "onDuty" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "lastLat" DOUBLE PRECISION;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "lastLng" DOUBLE PRECISION;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "lastSeenAt" TIMESTAMP(3);

-- Sanction type enum
DO $$ BEGIN
  CREATE TYPE "SanctionType" AS ENUM (
    'AVERTISSEMENT',
    'BLAME',
    'SUSPENSION_TEMPORAIRE',
    'REVOCATION'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Sanction table
CREATE TABLE IF NOT EXISTS "Sanction" (
  "id"        TEXT NOT NULL,
  "officerId" TEXT NOT NULL,
  "adminId"   TEXT NOT NULL,
  "motif"     TEXT NOT NULL,
  "type"      "SanctionType" NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Sanction_pkey" PRIMARY KEY ("id")
);

-- Foreign keys
DO $$ BEGIN
  ALTER TABLE "Sanction" ADD CONSTRAINT "Sanction_officerId_fkey"
    FOREIGN KEY ("officerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "Sanction" ADD CONSTRAINT "Sanction_adminId_fkey"
    FOREIGN KEY ("adminId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Index
CREATE INDEX IF NOT EXISTS "Sanction_officerId_idx" ON "Sanction"("officerId");

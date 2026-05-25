-- ============================================================
-- Migration : hiérarchie complète PNC Congo
-- Remplace enums GradePNC/Departement par des tables FK,
-- ajoute DirectionGenerale, DirectionNationale, DirectionDepartementale,
-- Unite, Grade, AppRole, Permission, RolePermission.
-- ============================================================

-- ── Phase 1 : étendre NiveauHierarchique ──────────────────────────────────────
ALTER TYPE "NiveauHierarchique" ADD VALUE IF NOT EXISTS 'DIRECTION_NATIONALE';

-- ── Phase 2 : supprimer colonnes enum (avant de supprimer les types) ──────────

-- User.grade (GradePNC)
ALTER TABLE "User" DROP COLUMN IF EXISTS "grade";

-- User.departement (Departement enum)
ALTER TABLE "User" DROP COLUMN IF EXISTS "departement";

-- Fine.departementInfraction (Departement enum)
ALTER TABLE "Fine" DROP COLUMN IF EXISTS "departementInfraction";

-- Commissariat.departement (Departement enum) + parentId (auto-référence)
ALTER TABLE "Commissariat" DROP CONSTRAINT IF EXISTS "Commissariat_parentId_fkey";
DROP INDEX IF EXISTS "Commissariat_parentId_idx";
DROP INDEX IF EXISTS "Commissariat_departement_idx";
ALTER TABLE "Commissariat" DROP COLUMN IF EXISTS "departement";
ALTER TABLE "Commissariat" DROP COLUMN IF EXISTS "parentId";

-- ── Phase 3 : supprimer les anciens types enum ────────────────────────────────
DROP TYPE IF EXISTS "GradePNC";
DROP TYPE IF EXISTS "Departement";

-- ── Phase 4 : créer les nouvelles tables de référence ────────────────────────

-- 4.1  DirectionGenerale (1 — DGPN)
CREATE TABLE IF NOT EXISTS "DirectionGenerale" (
  "id"        TEXT         NOT NULL,
  "nom"       TEXT         NOT NULL,
  "code"      TEXT         NOT NULL,
  "adresse"   TEXT,
  "actif"     BOOLEAN      NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "DirectionGenerale_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "DirectionGenerale_code_key" ON "DirectionGenerale"("code");

-- 4.2  DirectionNationale (7 — DSP, DPJ, DPAF, DCRP, DCI, DST, DRSP)
CREATE TABLE IF NOT EXISTS "DirectionNationale" (
  "id"                  TEXT         NOT NULL,
  "nom"                 TEXT         NOT NULL,
  "sigle"               TEXT         NOT NULL,
  "description"         TEXT,
  "directionGeneraleId" TEXT         NOT NULL,
  "actif"               BOOLEAN      NOT NULL DEFAULT true,
  "createdAt"           TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"           TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "DirectionNationale_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "DirectionNationale_sigle_key" ON "DirectionNationale"("sigle");
CREATE INDEX IF NOT EXISTS "DirectionNationale_directionGeneraleId_idx" ON "DirectionNationale"("directionGeneraleId");
DO $$ BEGIN
  ALTER TABLE "DirectionNationale" ADD CONSTRAINT "DirectionNationale_directionGeneraleId_fkey"
    FOREIGN KEY ("directionGeneraleId") REFERENCES "DirectionGenerale"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 4.3  Departement (TABLE — remplace l'enum)
-- NOTE : l'ancien type ENUM "Departement" a été supprimé en Phase 3
CREATE TABLE IF NOT EXISTS "Departement" (
  "id"        TEXT         NOT NULL,
  "nom"       TEXT         NOT NULL,
  "code"      TEXT         NOT NULL,
  "chefLieu"  TEXT,
  "actif"     BOOLEAN      NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Departement_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "Departement_code_key" ON "Departement"("code");
CREATE INDEX IF NOT EXISTS "Departement_code_idx" ON "Departement"("code");

-- 4.4  DirectionDepartementale (1 par département)
CREATE TABLE IF NOT EXISTS "DirectionDepartementale" (
  "id"            TEXT         NOT NULL,
  "nom"           TEXT         NOT NULL,
  "code"          TEXT         NOT NULL,
  "adresse"       TEXT,
  "lat"           DOUBLE PRECISION,
  "lng"           DOUBLE PRECISION,
  "departementId" TEXT         NOT NULL,
  "actif"         BOOLEAN      NOT NULL DEFAULT true,
  "createdAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "DirectionDepartementale_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "DirectionDepartementale_code_key" ON "DirectionDepartementale"("code");
CREATE UNIQUE INDEX IF NOT EXISTS "DirectionDepartementale_departementId_key" ON "DirectionDepartementale"("departementId");
CREATE INDEX IF NOT EXISTS "DirectionDepartementale_departementId_idx" ON "DirectionDepartementale"("departementId");
DO $$ BEGIN
  ALTER TABLE "DirectionDepartementale" ADD CONSTRAINT "DirectionDepartementale_departementId_fkey"
    FOREIGN KEY ("departementId") REFERENCES "Departement"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── Phase 5 : modifier Commissariat ──────────────────────────────────────────

ALTER TABLE "Commissariat"
  ADD COLUMN IF NOT EXISTS "departementId"             TEXT,
  ADD COLUMN IF NOT EXISTS "directionDepartementaleId" TEXT;

DO $$ BEGIN
  ALTER TABLE "Commissariat" ADD CONSTRAINT "Commissariat_departementId_fkey"
    FOREIGN KEY ("departementId") REFERENCES "Departement"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "Commissariat" ADD CONSTRAINT "Commissariat_directionDepartementaleId_fkey"
    FOREIGN KEY ("directionDepartementaleId") REFERENCES "DirectionDepartementale"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "Commissariat_departementId_idx"             ON "Commissariat"("departementId");
CREATE INDEX IF NOT EXISTS "Commissariat_directionDepartementaleId_idx" ON "Commissariat"("directionDepartementaleId");

-- 5.1  Unite (unités opérationnelles au sein des commissariats)
CREATE TABLE IF NOT EXISTS "Unite" (
  "id"             TEXT         NOT NULL,
  "nom"            TEXT         NOT NULL,
  "sigle"          TEXT         NOT NULL,
  "code"           TEXT         NOT NULL,
  "commissariatId" TEXT         NOT NULL,
  "actif"          BOOLEAN      NOT NULL DEFAULT true,
  "createdAt"      TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"      TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Unite_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "Unite_code_key" ON "Unite"("code");
CREATE INDEX IF NOT EXISTS "Unite_commissariatId_idx" ON "Unite"("commissariatId");
DO $$ BEGIN
  ALTER TABLE "Unite" ADD CONSTRAINT "Unite_commissariatId_fkey"
    FOREIGN KEY ("commissariatId") REFERENCES "Commissariat"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── Phase 6 : Grade (remplace l'enum GradePNC) ────────────────────────────────

CREATE TABLE IF NOT EXISTS "Grade" (
  "id"        TEXT    NOT NULL,
  "nom"       TEXT    NOT NULL,
  "code"      TEXT    NOT NULL,
  "sigle"     TEXT,
  "niveau"    INTEGER NOT NULL,
  "categorie" TEXT    NOT NULL,
  "actif"     BOOLEAN NOT NULL DEFAULT true,
  CONSTRAINT "Grade_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "Grade_code_key" ON "Grade"("code");
CREATE INDEX IF NOT EXISTS "Grade_niveau_idx" ON "Grade"("niveau");

-- ── Phase 7 : RBAC — AppRole, Permission, RolePermission ─────────────────────

CREATE TABLE IF NOT EXISTS "AppRole" (
  "id"          TEXT         NOT NULL,
  "nom"         TEXT         NOT NULL,
  "code"        TEXT         NOT NULL,
  "description" TEXT,
  "actif"       BOOLEAN      NOT NULL DEFAULT true,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AppRole_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "AppRole_code_key" ON "AppRole"("code");

CREATE TABLE IF NOT EXISTS "Permission" (
  "id"          TEXT NOT NULL,
  "nom"         TEXT NOT NULL,
  "code"        TEXT NOT NULL,
  "description" TEXT,
  CONSTRAINT "Permission_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "Permission_code_key" ON "Permission"("code");

CREATE TABLE IF NOT EXISTS "RolePermission" (
  "id"           TEXT NOT NULL,
  "appRoleId"    TEXT NOT NULL,
  "permissionId" TEXT NOT NULL,
  CONSTRAINT "RolePermission_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "RolePermission_appRoleId_permissionId_key" ON "RolePermission"("appRoleId", "permissionId");
CREATE INDEX IF NOT EXISTS "RolePermission_appRoleId_idx" ON "RolePermission"("appRoleId");
DO $$ BEGIN
  ALTER TABLE "RolePermission" ADD CONSTRAINT "RolePermission_appRoleId_fkey"
    FOREIGN KEY ("appRoleId") REFERENCES "AppRole"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "RolePermission" ADD CONSTRAINT "RolePermission_permissionId_fkey"
    FOREIGN KEY ("permissionId") REFERENCES "Permission"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── Phase 8 : nouvelles colonnes FK sur User ──────────────────────────────────

ALTER TABLE "User"
  ADD COLUMN IF NOT EXISTS "gradeId"                   TEXT,
  ADD COLUMN IF NOT EXISTS "departementId"             TEXT,
  ADD COLUMN IF NOT EXISTS "directionNationaleId"      TEXT,
  ADD COLUMN IF NOT EXISTS "directionDepartementaleId" TEXT,
  ADD COLUMN IF NOT EXISTS "uniteId"                   TEXT,
  ADD COLUMN IF NOT EXISTS "appRoleId"                 TEXT;

DO $$ BEGIN
  ALTER TABLE "User" ADD CONSTRAINT "User_gradeId_fkey"
    FOREIGN KEY ("gradeId") REFERENCES "Grade"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "User" ADD CONSTRAINT "User_departementId_fkey"
    FOREIGN KEY ("departementId") REFERENCES "Departement"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "User" ADD CONSTRAINT "User_directionNationaleId_fkey"
    FOREIGN KEY ("directionNationaleId") REFERENCES "DirectionNationale"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "User" ADD CONSTRAINT "User_directionDepartementaleId_fkey"
    FOREIGN KEY ("directionDepartementaleId") REFERENCES "DirectionDepartementale"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "User" ADD CONSTRAINT "User_uniteId_fkey"
    FOREIGN KEY ("uniteId") REFERENCES "Unite"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "User" ADD CONSTRAINT "User_appRoleId_fkey"
    FOREIGN KEY ("appRoleId") REFERENCES "AppRole"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "User_departementId_idx" ON "User"("departementId");

-- ── Phase 9 : Fine — remplace departementInfraction par departementCode ───────

ALTER TABLE "Fine" ADD COLUMN IF NOT EXISTS "departementCode" TEXT;

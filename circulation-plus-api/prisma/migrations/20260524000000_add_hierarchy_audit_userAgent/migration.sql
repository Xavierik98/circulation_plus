-- Migration: add_hierarchy_audit_userAgent
-- Adds PNC organisational hierarchy (Commissariat + GradePNC + NiveauHierarchique),
-- extends User with grade / level / commissariat assignment,
-- and adds userAgent to AuditLog for full connection tracing.

-- ── 1. Enums ─────────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE "GradePNC" AS ENUM (
    'DIRECTEUR_GENERAL',
    'DIRECTEUR_GENERAL_ADJOINT',
    'DIRECTEUR_CENTRAL',
    'DIRECTEUR_DEPARTEMENTAL',
    'COMMISSAIRE_DIVISIONNAIRE',
    'COMMISSAIRE_PRINCIPAL',
    'COMMISSAIRE',
    'INSPECTEUR_PRINCIPAL',
    'INSPECTEUR',
    'BRIGADIER_CHEF',
    'BRIGADIER',
    'GARDIEN_DE_LA_PAIX_1CL',
    'GARDIEN_DE_LA_PAIX_2CL'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "NiveauHierarchique" AS ENUM (
    'DIRECTION_GENERALE',
    'DIRECTION_DEPT',
    'COMMISSARIAT_CENTRAL',
    'COMMISSARIAT_ZONE',
    'AGENT'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── 2. Commissariat (unité organisationnelle PNC) ────────────────────────────

CREATE TABLE IF NOT EXISTS "Commissariat" (
  "id"          TEXT        NOT NULL,
  "nom"         TEXT        NOT NULL,
  "code"        TEXT        NOT NULL,
  "departement" "Departement" NOT NULL,
  "adresse"     TEXT,
  "parentId"    TEXT,
  "lat"         DOUBLE PRECISION,
  "lng"         DOUBLE PRECISION,
  "actif"       BOOLEAN     NOT NULL DEFAULT true,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Commissariat_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "Commissariat_code_key" ON "Commissariat"("code");
CREATE INDEX IF NOT EXISTS "Commissariat_departement_idx" ON "Commissariat"("departement");
CREATE INDEX IF NOT EXISTS "Commissariat_parentId_idx" ON "Commissariat"("parentId");

-- Self-referential FK (hierarchy)
DO $$ BEGIN
  ALTER TABLE "Commissariat" ADD CONSTRAINT "Commissariat_parentId_fkey"
    FOREIGN KEY ("parentId") REFERENCES "Commissariat"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── 3. User — new hierarchy columns ─────────────────────────────────────────

ALTER TABLE "User"
  ADD COLUMN IF NOT EXISTS "grade"             "GradePNC",
  ADD COLUMN IF NOT EXISTS "niveauHierarchique" "NiveauHierarchique" NOT NULL DEFAULT 'AGENT',
  ADD COLUMN IF NOT EXISTS "commissariatId"    TEXT;

CREATE INDEX IF NOT EXISTS "User_commissariatId_idx" ON "User"("commissariatId");
CREATE INDEX IF NOT EXISTS "User_niveauHierarchique_idx" ON "User"("niveauHierarchique");

DO $$ BEGIN
  ALTER TABLE "User" ADD CONSTRAINT "User_commissariatId_fkey"
    FOREIGN KEY ("commissariatId") REFERENCES "Commissariat"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── 4. AuditLog — userAgent column ──────────────────────────────────────────

ALTER TABLE "AuditLog"
  ADD COLUMN IF NOT EXISTS "userAgent" TEXT;

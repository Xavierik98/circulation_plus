-- ============================================================
-- Migration : fonctionnalités Congo-Brazzaville
-- - 12 départements (enum Departement)
-- - Mode paiement (enum PaymentMode)
-- - Champs Fine : lieuPrecis, departementInfraction, documentsSeizes, convocationRequise
-- - Champ User : departement (affectation agent)
-- - Champ Payment : mode, quittanceNumero, quittanceDate, agentTresor
-- ============================================================

-- Enums
CREATE TYPE "Departement" AS ENUM (
  'BRAZZAVILLE', 'POINTE_NOIRE', 'BOUENZA', 'CUVETTE', 'CUVETTE_OUEST',
  'KOUILOU', 'LEKOUMOU', 'LIKOUALA', 'NIARI', 'PLATEAUX', 'POOL', 'SANGHA'
);

CREATE TYPE "PaymentMode" AS ENUM ('MOBILE_MONEY', 'TRESOR_PUBLIC');

-- User : département d'affectation des agents
ALTER TABLE "User"
  ADD COLUMN "departement" "Departement";

-- Fine : lieu d'infraction + refus signature enrichi
ALTER TABLE "Fine"
  ADD COLUMN "departementInfraction" "Departement",
  ADD COLUMN "lieuPrecis"            TEXT,
  ADD COLUMN "documentsSeizes"       JSONB,
  ADD COLUMN "convocationRequise"    BOOLEAN NOT NULL DEFAULT false;

-- Payment : rendre opérateur/téléphone/transactionId optionnels,
--           ajouter mode et champs Trésor public
ALTER TABLE "Payment"
  ALTER COLUMN "operateur"      DROP NOT NULL,
  ALTER COLUMN "telephone"      DROP NOT NULL,
  ALTER COLUMN "transactionId"  DROP NOT NULL,
  ADD COLUMN "mode"             "PaymentMode" NOT NULL DEFAULT 'MOBILE_MONEY',
  ADD COLUMN "quittanceNumero"  TEXT,
  ADD COLUMN "quittanceDate"    TIMESTAMP(3),
  ADD COLUMN "agentTresor"      TEXT;

-- Index sur quittanceNumero
CREATE UNIQUE INDEX "Payment_quittanceNumero_key"
  ON "Payment"("quittanceNumero")
  WHERE "quittanceNumero" IS NOT NULL;

-- Migration: ajout montantDeveloppeur sur Fine
-- 1 000 XAF de frais plateforme Circulation+ (séparé du montant officiel de l'amende)

ALTER TABLE "Fine" ADD COLUMN IF NOT EXISTS "montantDeveloppeur" INTEGER NOT NULL DEFAULT 1000;

-- Recalcule montantTotal pour les fines existantes (montantAmende + 1000)
UPDATE "Fine" SET "montantTotal" = "montantAmende" + 1000 WHERE "montantDeveloppeur" = 1000;

COMMENT ON COLUMN "Fine"."montantDeveloppeur" IS '1 000 XAF — frais plateforme Circulation+ versés aux développeurs';
COMMENT ON COLUMN "Fine"."montantTotal" IS 'montantAmende + montantDeveloppeur + montantMajoration — montant total payé par le contrevenant';

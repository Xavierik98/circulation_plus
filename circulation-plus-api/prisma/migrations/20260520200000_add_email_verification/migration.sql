-- AlterTable: add emailVerified (default true so existing rows stay valid)
ALTER TABLE "User" ADD COLUMN "emailVerified" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "User" ADD COLUMN "emailVerificationToken" TEXT;

-- CreateIndex: unique constraint on token
CREATE UNIQUE INDEX "User_emailVerificationToken_key" ON "User"("emailVerificationToken");

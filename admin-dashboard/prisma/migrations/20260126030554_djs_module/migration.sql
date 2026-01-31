-- CreateTable
CREATE TABLE "Dj" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "instagram" TEXT,
    "bio" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateIndex
CREATE INDEX "Dj_status_idx" ON "Dj"("status");

-- CreateIndex
CREATE INDEX "Dj_createdAt_idx" ON "Dj"("createdAt");

-- CreateEnum
CREATE TYPE "Role" AS ENUM ('ADMIN', 'DJ', 'LISTENER');

-- CreateEnum
CREATE TYPE "DjStatus" AS ENUM ('PENDING', 'APPROVED', 'BLOCKED');

-- CreateEnum
CREATE TYPE "MixStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'LISTENER',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DjProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "bio" TEXT NOT NULL DEFAULT '',
    "location" TEXT,
    "status" "DjStatus" NOT NULL DEFAULT 'PENDING',
    "genres" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DjProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Mix" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL DEFAULT '',
    "genre" TEXT NOT NULL DEFAULT '',
    "audioUrl" TEXT NOT NULL,
    "coverUrl" TEXT NOT NULL,
    "isClean" BOOLEAN NOT NULL DEFAULT true,
    "djId" TEXT NOT NULL,
    "status" "MixStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Mix_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "DjProfile_userId_key" ON "DjProfile"("userId");

-- CreateIndex
CREATE INDEX "Mix_djId_idx" ON "Mix"("djId");

-- CreateIndex
CREATE INDEX "Mix_status_createdAt_idx" ON "Mix"("status", "createdAt");

-- AddForeignKey
ALTER TABLE "DjProfile" ADD CONSTRAINT "DjProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Mix" ADD CONSTRAINT "Mix_djId_fkey" FOREIGN KEY ("djId") REFERENCES "DjProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

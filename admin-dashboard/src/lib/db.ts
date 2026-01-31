import { PrismaClient } from '@/generated/prisma/client';
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3';
import path from 'node:path';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

function resolveSqliteFileFromEnv() {
  const raw = (process.env.DATABASE_URL ?? '').trim();
  if (raw.startsWith('file:')) {
    const maybePath = raw.slice('file:'.length);
    const normalized = maybePath.replace(/^\/+/, '/');
    if (!normalized) return path.join(process.cwd(), 'dev.db');
    return path.isAbsolute(normalized)
      ? normalized
      : path.join(process.cwd(), normalized.replace(/^\.\//, ''));
  }
  return path.join(process.cwd(), 'dev.db');
}

const sqliteFile = resolveSqliteFileFromEnv();
const adapter = new PrismaBetterSqlite3({ url: sqliteFile });

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({ adapter });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

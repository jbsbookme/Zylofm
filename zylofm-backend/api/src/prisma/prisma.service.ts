import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

function shouldUseSslForDatabase(connectionString: string): boolean {
  const envMode = (process.env.PGSSLMODE ?? '').trim().toLowerCase();
  if (envMode === 'require' || envMode === 'verify-full' || envMode === 'verify-ca') return true;

  try {
    const url = new URL(connectionString);
    const sslmode = (url.searchParams.get('sslmode') ?? '').trim().toLowerCase();
    if (sslmode === 'require' || sslmode === 'verify-full' || sslmode === 'verify-ca') return true;
  } catch {
    // ignore parse errors; we'll default to non-SSL
  }

  return false;
}

/**
 * PrismaService
 *
 * - Single PrismaClient instance for the whole Nest app.
 * - Adds shutdown hooks so Nest can close cleanly.
 */
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly pool: Pool;

  constructor() {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString || connectionString.trim().length === 0) {
      throw new Error('DATABASE_URL is required to initialize Prisma (Postgres).');
    }

    const useSsl = shouldUseSslForDatabase(connectionString);
    const pool = new Pool({
      connectionString,
      ...(useSsl ? { ssl: { rejectUnauthorized: false } } : {}),
    });
    super({ adapter: new PrismaPg(pool) });
    this.pool = pool;
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
    await this.pool.end();
  }
}

import 'dotenv/config';
import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

/**
 * Prisma seed (PASO 8.3)
 *
 * Creates the initial ADMIN user.
 *
 * Env vars:
 * - ADMIN_EMAIL
 * - ADMIN_PASSWORD
 *
 * Notes:
 * - Roles are an enum (Role.ADMIN/DJ/LISTENER), no separate table required.
 */
async function main() {
  const email = (process.env.ADMIN_EMAIL ?? '').trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD ?? '';

  if (!email || !password) {
    throw new Error(
      'Missing ADMIN_EMAIL / ADMIN_PASSWORD. Set them in .env before running seed.',
    );
  }

  if (password.trim().length < 10) {
    throw new Error('ADMIN_PASSWORD too short (min 10 chars).');
  }

  const prisma = new PrismaClient();

  try {
    const passwordHash = await bcrypt.hash(password, 10);

    // Upsert so seed can be re-run safely.
    const admin = await prisma.user.upsert({
      where: { email },
      update: {
        passwordHash,
        role: Role.ADMIN,
      },
      create: {
        email,
        passwordHash,
        role: Role.ADMIN,
      },
      select: { id: true, email: true, role: true },
    });

    // eslint-disable-next-line no-console
    console.log('Seed OK:', admin);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});

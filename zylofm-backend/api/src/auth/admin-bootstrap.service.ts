import { Injectable, OnModuleInit } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

function isTruthy(value: string | undefined): boolean {
  if (!value) return false;
  const v = value.trim().toLowerCase();
  return v === '1' || v === 'true' || v === 'yes' || v === 'y' || v === 'on';
}

@Injectable()
export class AdminBootstrapService implements OnModuleInit {
  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit(): Promise<void> {
    if (!isTruthy(process.env.AUTO_SEED_ADMIN)) return;

    const email = (process.env.ADMIN_EMAIL ?? '').trim().toLowerCase();
    const password = process.env.ADMIN_PASSWORD ?? '';

    // If not configured, do nothing (keeps deployments from crashing).
    if (!email || !password) return;

    if (password.trim().length < 10) {
      throw new Error('ADMIN_PASSWORD too short (min 10 chars).');
    }

    const passwordHash = await bcrypt.hash(password, 10);

    await this.prisma.user.upsert({
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
      select: { id: true },
    });
  }
}

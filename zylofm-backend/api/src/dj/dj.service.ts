import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { DjStatus, Role } from '../common/types';
import { PrismaService } from '../prisma/prisma.service';

/**
 * DjService (PASO 8.3)
 *
 * - DJ can only access/update their own profile through /dj/me
 * - Public routes expose only DjProfile public fields
 */
@Injectable()
export class DjService {
  constructor(private readonly prisma: PrismaService) {}

  async createMe(
    user: { sub: string; role: Role },
    params: {
      displayName: string;
      bio?: string;
      location?: string;
      genres?: string[];
    },
  ) {
    const existing = await this.prisma.djProfile.findUnique({ where: { userId: user.sub } });
    if (existing) throw new ConflictException('DJ profile already exists');

    const u = await this.prisma.user.findUnique({ where: { id: user.sub } });
    if (!u) throw new NotFoundException('User not found');
    if ((u.role as any) === Role.ADMIN) throw new ForbiddenException('Admin cannot become DJ');

    const profile = await this.prisma.djProfile.create({
      data: {
        userId: user.sub,
        displayName: params.displayName.trim(),
        bio: (params.bio ?? '').trim(),
        location: params.location?.trim() ?? null,
        genres: params.genres ?? [],
        status: DjStatus.PENDING as any,
      },
    });

    await this.prisma.user.update({ where: { id: user.sub }, data: { role: Role.DJ as any } });
    return profile;
  }

  async getMe(user: { sub: string; role: Role }) {
    if (user.role !== Role.DJ) throw new ForbiddenException('DJ only');

    const profile = await this.prisma.djProfile.findUnique({ where: { userId: user.sub } });
    if (!profile) throw new NotFoundException('DJ profile not found');
    return profile;
  }

  async updateMe(
    user: { sub: string; role: Role },
    patch: {
      displayName?: string;
      bio?: string;
      location?: string | null;
      genres?: string[];
    },
  ) {
    if (user.role !== Role.DJ) throw new ForbiddenException('DJ only');

    const profile = await this.prisma.djProfile.findUnique({ where: { userId: user.sub } });
    if (!profile) throw new NotFoundException('DJ profile not found');

    return this.prisma.djProfile.update({
      where: { id: profile.id },
      data: {
        displayName: patch.displayName,
        bio: patch.bio,
        location: patch.location === undefined ? undefined : patch.location,
        genres: patch.genres,
      },
    });
  }

  async getPublicById(id: string) {
    const profile = await this.prisma.djProfile.findUnique({ where: { id } });
    if (!profile) throw new NotFoundException('DJ not found');
    return profile;
  }

  async listPublic() {
    return this.prisma.djProfile.findMany({
      where: { status: DjStatus.APPROVED as any },
      orderBy: { createdAt: 'desc' },
    });
  }
}

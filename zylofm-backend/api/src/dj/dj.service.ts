import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
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

  async getMe(user: { sub: string; role: Role }) {
    if (user.role !== Role.DJ) throw new ForbiddenException('DJ only');

    const profile = await this.prisma.djProfile.findUnique({
      where: { userId: user.sub },
      select: {
        id: true,
        displayName: true,
        bio: true,
        location: true,
        genres: true,
        createdAt: true,
        updatedAt: true,
      },
    });

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

    // Ensure the profile exists first.
    const existing = await this.prisma.djProfile.findUnique({
      where: { userId: user.sub },
      select: { id: true },
    });
    if (!existing) throw new NotFoundException('DJ profile not found');

    const profile = await this.prisma.djProfile.update({
      where: { userId: user.sub },
      data: {
        displayName: patch.displayName,
        bio: patch.bio,
        location: patch.location,
        genres: patch.genres,
      },
      select: {
        id: true,
        displayName: true,
        bio: true,
        location: true,
        genres: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return profile;
  }

  async getPublicById(id: string) {
    const profile = await this.prisma.djProfile.findUnique({
      where: { id },
      select: {
        id: true,
        displayName: true,
        bio: true,
        location: true,
        genres: true,
      },
    });

    if (!profile) throw new NotFoundException('DJ not found');
    return profile;
  }

  async listPublic() {
    return this.prisma.djProfile.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        displayName: true,
        bio: true,
        location: true,
        genres: true,
      },
    });
  }
}

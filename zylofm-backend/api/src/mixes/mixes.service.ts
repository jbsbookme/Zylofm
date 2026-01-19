import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { MixStatus, MixVisibility, Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/**
 * MixesService (PASO 8.4)
 *
 * Rules:
 * - Unlisted does not appear in public lists.
 * - Takedown is never visible publicly.
 * - DJ can only manage their own mixes.
 * - DJ must be approved (DjProfile.approved) to publish.
 */
@Injectable()
export class MixesService {
  constructor(private readonly prisma: PrismaService) {}

  async createDraft(params: {
    user: { sub: string; role: Role };
    title: string;
    description?: string;
    visibility?: MixVisibility;
  }) {
    if (params.user.role !== Role.DJ) throw new ForbiddenException('DJ only');

    const mix = await this.prisma.mix.create({
      data: {
        title: params.title.trim(),
        description: (params.description ?? '').trim(),
        visibility: params.visibility ?? MixVisibility.PUBLIC,
        status: MixStatus.DRAFT,
        djUserId: params.user.sub,
      },
      select: {
        id: true,
        title: true,
        description: true,
        djUserId: true,
        status: true,
        visibility: true,
        createdAt: true,
      },
    });

    return mix;
  }

  async updateMetadata(params: {
    user: { sub: string; role: Role };
    id: string;
    title?: string;
    description?: string;
    visibility?: MixVisibility;
  }) {
    if (params.user.role !== Role.DJ) throw new ForbiddenException('DJ only');

    const existing = await this.prisma.mix.findUnique({
      where: { id: params.id },
      select: { id: true, djUserId: true, status: true },
    });

    if (!existing) throw new NotFoundException('Mix not found');
    if (existing.djUserId !== params.user.sub) throw new ForbiddenException();
    if (existing.status === MixStatus.TAKEDOWN) {
      throw new ForbiddenException('Mix is taken down');
    }

    const mix = await this.prisma.mix.update({
      where: { id: params.id },
      data: {
        title: params.title?.trim(),
        description: params.description?.trim(),
        visibility: params.visibility,
      },
      select: {
        id: true,
        title: true,
        description: true,
        djUserId: true,
        status: true,
        visibility: true,
        createdAt: true,
      },
    });

    return mix;
  }

  async publish(params: { user: { sub: string; role: Role }; id: string }) {
    if (params.user.role !== Role.DJ) throw new ForbiddenException('DJ only');

    const mix = await this.prisma.mix.findUnique({
      where: { id: params.id },
      select: { id: true, djUserId: true, status: true },
    });

    if (!mix) throw new NotFoundException('Mix not found');
    if (mix.djUserId !== params.user.sub) throw new ForbiddenException();
    if (mix.status === MixStatus.TAKEDOWN) {
      throw new ForbiddenException('Mix is taken down');
    }

    const djProfile = await this.prisma.djProfile.findUnique({
      where: { userId: params.user.sub },
      select: { approved: true },
    });

    if (!djProfile?.approved) {
      throw new ForbiddenException('DJ not approved to publish');
    }

    return this.prisma.mix.update({
      where: { id: params.id },
      data: { status: MixStatus.PUBLISHED },
      select: {
        id: true,
        title: true,
        description: true,
        djUserId: true,
        status: true,
        visibility: true,
        createdAt: true,
      },
    });
  }

  async listMine(user: { sub: string; role: Role }) {
    if (user.role !== Role.DJ) throw new ForbiddenException('DJ only');

    return this.prisma.mix.findMany({
      where: { djUserId: user.sub },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        title: true,
        description: true,
        djUserId: true,
        status: true,
        visibility: true,
        createdAt: true,
      },
    });
  }

  async listPublic() {
    return this.prisma.mix.findMany({
      where: {
        status: MixStatus.PUBLISHED,
        visibility: MixVisibility.PUBLIC,
      },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        title: true,
        description: true,
        djUserId: true,
        status: true,
        visibility: true,
        createdAt: true,
      },
    });
  }

  async getPublicById(id: string) {
    const mix = await this.prisma.mix.findUnique({
      where: { id },
      select: {
        id: true,
        title: true,
        description: true,
        djUserId: true,
        status: true,
        visibility: true,
        createdAt: true,
      },
    });

    if (!mix) throw new NotFoundException('Mix not found');

    // TAKEDOWN: never visible.
    if (mix.status === MixStatus.TAKEDOWN) throw new NotFoundException('Mix not found');

    // DRAFT: never public.
    if (mix.status !== MixStatus.PUBLISHED) throw new NotFoundException('Mix not found');

    // UNLISTED: accessible by link (id), but not listable.
    if (mix.visibility === MixVisibility.UNLISTED || mix.visibility === MixVisibility.PUBLIC) {
      return mix;
    }

    // Defensive default.
    throw new NotFoundException('Mix not found');
  }

  async adminTakedown(id: string) {
    const existing = await this.prisma.mix.findUnique({
      where: { id },
      select: { id: true },
    });
    if (!existing) throw new NotFoundException('Mix not found');

    return this.prisma.mix.update({
      where: { id },
      data: { status: MixStatus.TAKEDOWN },
      select: {
        id: true,
        title: true,
        description: true,
        djUserId: true,
        status: true,
        visibility: true,
        createdAt: true,
      },
    });
  }
}

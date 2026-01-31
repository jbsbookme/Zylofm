import { Controller, Get, NotFoundException, Param, Post, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Role, DjStatus } from '../common/types';
import { Roles } from '../common/roles';
import { RolesGuard } from '../common/roles.guard';
import { PrismaService } from '../prisma/prisma.service';

/**
 * AdminDjsController (PASO 9.1)
 *
 * Admin controls DJ approval/blocking.
 */
@Controller('admin/djs')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminDjsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  list(@Query('status') status?: string) {
    const s = (status ?? '').trim().toLowerCase();

    const where =
      s === 'pending'
        ? { status: DjStatus.PENDING as any }
        : s === 'approved'
          ? { status: DjStatus.APPROVED as any }
          : s === 'blocked'
            ? { status: DjStatus.BLOCKED as any }
            : {};

    return this.prisma.djProfile.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { id: true, email: true, role: true } } },
    });
  }

  @Post(':id/approve')
  async approve(@Param('id') id: string) {
    const dj = await this.prisma.djProfile.findUnique({ where: { id } });
    if (!dj) throw new NotFoundException('DJ not found');
    return this.prisma.djProfile.update({
      where: { id },
      data: { status: DjStatus.APPROVED as any },
    });
  }

  @Post(':id/block')
  async block(@Param('id') id: string) {
    const dj = await this.prisma.djProfile.findUnique({ where: { id } });
    if (!dj) throw new NotFoundException('DJ not found');
    return this.prisma.djProfile.update({
      where: { id },
      data: { status: DjStatus.BLOCKED as any },
    });
  }

  // Alias for dashboard UX.
  @Post(':id/reject')
  reject(@Param('id') id: string) {
    return this.block(id);
  }
}

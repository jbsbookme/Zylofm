import { Controller, Param, Post, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/roles';
import { RolesGuard } from '../common/roles.guard';
import { MixesService } from '../mixes/mixes.service';

/**
 * AdminMixesController (PASO 8.4)
 *
 * Admin can takedown any mix.
 */
@Controller('admin/mixes')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminMixesController {
  constructor(private readonly mixes: MixesService) {}

  @Post(':id/takedown')
  takedown(@Param('id') id: string) {
    return this.mixes.adminTakedown(id);
  }
}

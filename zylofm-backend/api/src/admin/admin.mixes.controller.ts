import { Controller, Param, Post, UseGuards } from '@nestjs/common';
import { Role } from '../common/types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/roles';
import { RolesGuard } from '../common/roles.guard';
import { MixesService } from '../mixes/mixes.service';

/**
 * AdminMixesController (PASO 8.4)
 *
 * PASO 9.1: Admin controls approval.
 */
@Controller('admin/mixes')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminMixesController {
  constructor(private readonly mixes: MixesService) {}

  @Post(':id/approve')
  approve(@Param('id') id: string) {
    return this.mixes.adminApprove(id);
  }

  @Post(':id/reject')
  reject(@Param('id') id: string) {
    return this.mixes.adminReject(id);
  }

  @Post(':id/takedown')
  takedown(@Param('id') id: string) {
    return this.mixes.adminTakedown(id);
  }
}

import { Controller, Get, UseGuards } from '@nestjs/common';
import { Role } from '../common/types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/roles';
import { RolesGuard } from '../common/roles.guard';

/**
 * AdminController (PASO 8.3)
 *
 * Everything under /admin/* must be ADMIN only.
 * This file exists mainly to validate RBAC wiring.
 */
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  @Get('ping')
  ping() {
    return { ok: true, scope: 'admin' };
  }
}

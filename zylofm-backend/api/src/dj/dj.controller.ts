import { Body, Controller, Get, Param, Patch, Post, Request, UseGuards } from '@nestjs/common';
import { Role } from '../common/types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { JwtPayload } from '../auth/jwt.strategy';
import { Roles } from '../common/roles';
import { RolesGuard } from '../common/roles.guard';
import { CreateDjProfileDto } from './dto/create-dj-profile.dto';
import { UpdateDjMeDto } from './dto/update-dj-me.dto';
import { DjService } from './dj.service';

/**
 * DJ endpoints (PASO 8.3)
 *
 * MVP:
 * - GET   /dj/me       (DJ only)
 * - PATCH /dj/me       (DJ only)
 * - GET   /dj/:id      (public)
 * - GET   /djs         (public list) -> implemented in DjsController
 */
@Controller('dj')
export class DjController {
  constructor(private readonly djs: DjService) {}

  // PASO 9.1: DJ onboarding.
  // After calling this, re-login to get a token with role=DJ.
  @UseGuards(JwtAuthGuard)
  @Post('me')
  createMe(@Request() req: { user: JwtPayload }, @Body() dto: CreateDjProfileDto) {
    const displayName = dto.displayName.trim();
    const bio = dto.bio?.trim();
    const location = dto.location?.trim();
    const genres = dto.genres?.map((g) => g.trim()).filter((g) => g.length > 0);

    return this.djs.createMe(req.user, {
      displayName,
      bio,
      location,
      genres,
    });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.DJ)
  @Get('me')
  getMe(@Request() req: { user: JwtPayload }) {
    return this.djs.getMe(req.user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.DJ)
  @Patch('me')
  updateMe(@Request() req: { user: JwtPayload }, @Body() dto: UpdateDjMeDto) {
    // Light normalization (no heavy logic).
    const displayName = dto.displayName?.trim();
    const bio = dto.bio?.trim();
    const location = dto.location?.trim();
    const genres = dto.genres
      ?.map((g) => g.trim())
      .filter((g) => g.length > 0);

    return this.djs.updateMe(req.user, {
      displayName,
      bio,
      location,
      genres,
    });
  }

  @Get(':id')
  getPublic(@Param('id') id: string) {
    return this.djs.getPublicById(id);
  }
}

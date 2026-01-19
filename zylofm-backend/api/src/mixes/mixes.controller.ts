import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { JwtPayload } from '../auth/jwt.strategy';
import { Roles } from '../common/roles';
import { RolesGuard } from '../common/roles.guard';
import { CreateMixDto } from './dto/create-mix.dto';
import { UpdateMixDto } from './dto/update-mix.dto';
import { MixesService } from './mixes.service';

/**
 * MixesController (PASO 8.4)
 *
 * DJ protected:
 * - POST  /mixes            -> create DRAFT
 * - PATCH /mixes/:id        -> edit metadata
 * - POST  /mixes/:id/publish -> publish (requires approved DJ)
 * - GET   /mixes/me         -> list my mixes
 *
 * Public:
 * - GET /mixes              -> only PUBLISHED + PUBLIC
 * - GET /mixes/:id          -> PUBLISHED + (PUBLIC or UNLISTED)
 */
@Controller()
export class MixesController {
  constructor(private readonly mixes: MixesService) {}

  // --- DJ endpoints (protected) ---

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.DJ)
  @Post('mixes')
  create(@Request() req: { user: JwtPayload }, @Body() dto: CreateMixDto) {
    return this.mixes.createDraft({
      user: req.user,
      title: dto.title,
      description: dto.description,
      visibility: dto.visibility,
    });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.DJ)
  @Patch('mixes/:id')
  update(
    @Request() req: { user: JwtPayload },
    @Param('id') id: string,
    @Body() dto: UpdateMixDto,
  ) {
    return this.mixes.updateMetadata({
      user: req.user,
      id,
      title: dto.title,
      description: dto.description,
      visibility: dto.visibility,
    });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.DJ)
  @Post('mixes/:id/publish')
  publish(@Request() req: { user: JwtPayload }, @Param('id') id: string) {
    return this.mixes.publish({ user: req.user, id });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.DJ)
  @Get('mixes/me')
  me(@Request() req: { user: JwtPayload }) {
    return this.mixes.listMine(req.user);
  }

  // --- Public endpoints ---

  @Get('mixes')
  listPublic() {
    return this.mixes.listPublic();
  }

  @Get('mixes/:id')
  getPublic(@Param('id') id: string) {
    return this.mixes.getPublicById(id);
  }
}

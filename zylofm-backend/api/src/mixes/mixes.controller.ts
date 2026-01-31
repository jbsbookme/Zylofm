import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Request,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/optional-jwt-auth.guard';
import { JwtPayload } from '../auth/jwt.strategy';
import { Role } from '../common/types';
import { Roles } from '../common/roles';
import { RolesGuard } from '../common/roles.guard';
import { ApproveMixDto } from './dto/approve-mix.dto';
import { UploadMixDto } from './dto/upload-mix.dto';
import { MixesService } from './mixes.service';

/**
 * MixesController (PASO 1)
 *
 * Required endpoints:
 * - POST   /mixes/upload
 * - GET    /mixes/pending
 * - POST   /mixes/approve/:id
 * - GET    /mixes/public
 * - GET    /dj/:id/mixes
 */
@Controller()
export class MixesController {
  constructor(private readonly mixes: MixesService) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.DJ, Role.ADMIN)
  @Post('mixes/upload')
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'audio', maxCount: 1 },
      { name: 'cover', maxCount: 1 },
    ]),
  )
  upload(
    @Request() req: { user: JwtPayload },
    @Body() dto: UploadMixDto,
    @UploadedFiles()
    files: {
      audio?: Express.Multer.File[];
      cover?: Express.Multer.File[];
    },
  ) {
    return this.mixes.upload({
      user: req.user,
      title: dto.title,
      djId: dto.djId,
      description: dto.description,
      genre: dto.genre,
      isClean: dto.isClean,
      audio: files.audio?.[0],
      cover: files.cover?.[0],
    });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Get('mixes/pending')
  pending() {
    return this.mixes.listPending();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Post('mixes/approve/:id')
  approveOrReject(@Param('id') id: string, @Body() dto: ApproveMixDto) {
    return this.mixes.adminSetStatus(id, dto.status ?? 'approved');
  }

  @Get('mixes/public')
  listPublic() {
    return this.mixes.listPublicApproved();
  }

  // Alias (backwards compatibility)
  @Get('mixes')
  listPublicAlias() {
    return this.mixes.listPublicApproved();
  }

  @UseGuards(OptionalJwtAuthGuard)
  @Get('dj/:id/mixes')
  listDjMixes(
    @Param('id') djId: string,
    @Request() req: { user?: JwtPayload },
  ) {
    return this.mixes.listForDj({ djId, viewer: req.user });
  }
}

import { Body, Controller, Delete, Get, Param, Patch, Post, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Role } from '../common/types';
import { Roles } from '../common/roles';
import { RolesGuard } from '../common/roles.guard';
import { AssistantService } from './assistant.service';
import { PlayAssistantDto } from './dto/play-assistant.dto';
import { CreateAssistantLibraryItemDto } from './dto/create-assistant-library-item.dto';
import { UploadAssistantLibraryAudioDto } from './dto/upload-assistant-library-audio.dto';
import { UpdateAssistantLibraryItemDto } from './dto/update-assistant-library-item.dto';

@Controller('assistant')
export class AssistantController {
  constructor(private readonly assistant: AssistantService) {}

  // Public endpoint for the app: query -> audioUrl ready for just_audio.
  @Post('play')
  play(@Body() dto: PlayAssistantDto) {
    return this.assistant.play({ query: dto.query });
  }

  // Public endpoint: list active assistant tracks for the client app.
  @Get('library/public')
  listPublicLibraryItems() {
    return this.assistant.listPublicLibraryItems();
  }

  // Minimal admin endpoints so the feature is usable without manual DB writes.
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Post('library')
  createLibraryItem(@Body() dto: CreateAssistantLibraryItemDto) {
    return this.assistant.createLibraryItem({
      title: dto.title,
      audioUrl: dto.audioUrl,
      keywords: dto.keywords,
      isActive: dto.isActive,
    });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Get('library')
  listLibraryItems() {
    return this.assistant.listLibraryItems();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Patch('library/:id')
  updateLibraryItem(@Param('id') id: string, @Body() dto: UpdateAssistantLibraryItemDto) {
    return this.assistant.updateLibraryItem(id, {
      title: dto.title,
      keywords: dto.keywords,
      isActive: dto.isActive,
    });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Delete('library/:id')
  deleteLibraryItem(@Param('id') id: string) {
    return this.assistant.deleteLibraryItem(id);
  }

  // PASO 6.5: Admin flow: upload audio -> Cloudinary -> auto-save in assistant_library.
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Post('library/upload')
  @UseInterceptors(FileInterceptor('audio'))
  uploadLibraryAudio(
    @Body() dto: UploadAssistantLibraryAudioDto,
    @UploadedFile() audio?: Express.Multer.File,
  ) {
    return this.assistant.uploadLibraryAudio({
      title: dto.title,
      keywords: dto.keywords,
      isActive: dto.isActive,
      audio,
    });
  }
}

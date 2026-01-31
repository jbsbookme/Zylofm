import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { AdminModule } from './admin/admin.module';
import { DjModule } from './dj/dj.module';
import { MixesModule } from './mixes/mixes.module';
import { PrismaModule } from './prisma/prisma.module';
import { CloudinaryModule } from './cloudinary/cloudinary.module';
import { AssistantModule } from './assistant/assistant.module';

@Module({
  imports: [PrismaModule, CloudinaryModule, AuthModule, AdminModule, DjModule, MixesModule, AssistantModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

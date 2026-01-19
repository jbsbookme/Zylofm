import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { AdminModule } from './admin/admin.module';
import { DjModule } from './dj/dj.module';
import { MixesModule } from './mixes/mixes.module';

@Module({
  imports: [PrismaModule, AuthModule, AdminModule, DjModule, MixesModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

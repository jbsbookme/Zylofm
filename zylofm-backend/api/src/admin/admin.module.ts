import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminController } from './admin.controller';
import { AdminMixesController } from './admin.mixes.controller';
import { MixesModule } from '../mixes/mixes.module';

/**
 * AdminModule (PASO 8.3)
 */
@Module({
  imports: [AuthModule, MixesModule],
  controllers: [AdminController, AdminMixesController],
})
export class AdminModule {}

import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminController } from './admin.controller';
import { AdminDjsController } from './admin.djs.controller';
import { AdminMixesController } from './admin.mixes.controller';
import { MixesModule } from '../mixes/mixes.module';

/**
 * AdminModule (PASO 8.3)
 */
@Module({
  imports: [AuthModule, MixesModule],
  controllers: [AdminController, AdminDjsController, AdminMixesController],
})
export class AdminModule {}

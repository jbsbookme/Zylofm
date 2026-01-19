import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminController } from './admin.controller';

/**
 * AdminModule (PASO 8.3)
 */
@Module({
  imports: [AuthModule],
  controllers: [AdminController],
})
export class AdminModule {}

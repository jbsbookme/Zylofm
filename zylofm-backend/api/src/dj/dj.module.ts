import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DjController } from './dj.controller';
import { DjService } from './dj.service';
import { DjsController } from './djs.controller';

/**
 * DjModule (PASO 8.3)
 */
@Module({
  imports: [AuthModule],
  controllers: [DjController, DjsController],
  providers: [DjService],
})
export class DjModule {}

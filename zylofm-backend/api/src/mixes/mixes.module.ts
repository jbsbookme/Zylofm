import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MixesController } from './mixes.controller';
import { MixesService } from './mixes.service';

/**
 * MixesModule (PASO 8.4)
 */
@Module({
  imports: [AuthModule],
  controllers: [MixesController],
  providers: [MixesService],
  exports: [MixesService],
})
export class MixesModule {}

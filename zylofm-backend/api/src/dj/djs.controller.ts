import { Controller, Get } from '@nestjs/common';
import { DjService } from './dj.service';

/**
 * Public list endpoint (PASO 8.3)
 *
 * - GET /djs
 */
@Controller('djs')
export class DjsController {
  constructor(private readonly djs: DjService) {}

  @Get()
  list() {
    return this.djs.listPublic();
  }
}

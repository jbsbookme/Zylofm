import { ExecutionContext, Injectable } from '@nestjs/common';
import { JwtAuthGuard } from './jwt-auth.guard';

/**
 * OptionalJwtAuthGuard
 *
 * Like JwtAuthGuard, but does not throw if the request has no/invalid token.
 * If a valid token is present, it attaches `req.user`.
 */
@Injectable()
export class OptionalJwtAuthGuard extends JwtAuthGuard {
  // eslint-disable-next-line @typescript-eslint/require-await
  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      const ok = (await super.canActivate(context)) as boolean;
      return ok;
    } catch {
      return true;
    }
  }
}
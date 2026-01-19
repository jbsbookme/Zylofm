import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * JwtAuthGuard
 *
 * Adds `request.user` when a valid Bearer token is provided.
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}

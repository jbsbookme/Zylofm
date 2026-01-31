import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from './types';
import { ROLES_KEY } from './roles';

/**
 * RolesGuard
 *
 * - Reads required roles from @Roles(...)
 * - Compares against request.user.role (set by JwtAuthGuard)
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) return true;

    const request = context.switchToHttp().getRequest();
    const user = request.user as { role?: Role } | undefined;
    const role = user?.role;

    return role != null && requiredRoles.includes(role);
  }
}

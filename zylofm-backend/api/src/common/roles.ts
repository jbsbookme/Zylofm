import { SetMetadata } from '@nestjs/common';
import { Role } from '@prisma/client';

/**
 * Roles decorator used by RolesGuard.
 *
 * Example:
 *   @Roles(Role.ADMIN)
 */
export const ROLES_KEY = 'roles';
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);

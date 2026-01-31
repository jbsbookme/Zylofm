import { SetMetadata } from '@nestjs/common';
import { Role } from './types';

/**
 * Roles decorator used by RolesGuard.
 *
 * Example:
 *   @Roles(Role.ADMIN)
 */
export const ROLES_KEY = 'roles';
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);

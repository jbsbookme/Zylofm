/**
 * Common types (PASO 8.5)
 *
 * In-memory backend must not depend on Prisma runtime.
 * These enums mirror the Prisma enums we will use later.
 */

export enum Role {
  ADMIN = 'ADMIN',
  DJ = 'DJ',
  LISTENER = 'LISTENER',
}

export enum DjStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  BLOCKED = 'BLOCKED',
}

export enum MixStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

export type JwtUser = {
  sub: string;
  email: string;
  role: Role;
};

import { DjStatus, MixStatus, Role } from '../common/types';

/**
 * InMemoryStore (PASO 8.5)
 *
 * A simple singleton store so `npm run start:dev` works without Postgres.
 * Later we will swap implementations (Prisma) without changing routes.
 */
export type UserRecord = {
  id: string;
  email: string;
  passwordHash: string;
  role: Role;
  createdAt: Date;
};

export type DjProfileRecord = {
  id: string;
  userId: string;
  displayName: string;
  bio: string;
  location?: string;
  genres: string[];
  status: DjStatus;
  createdAt: Date;
  updatedAt: Date;
};

export type MixRecord = {
  id: string;
  title: string;
  description: string;
  djUserId: string;
  status: MixStatus;
  createdAt: Date;
};

export class InMemoryStore {
  users: UserRecord[] = [];
  djProfiles: DjProfileRecord[] = [];
  mixes: MixRecord[] = [];
}

let singleton: InMemoryStore | null = null;

export function getStore(): InMemoryStore {
  singleton ??= new InMemoryStore();
  return singleton;
}

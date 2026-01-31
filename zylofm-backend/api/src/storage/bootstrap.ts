import * as bcrypt from 'bcrypt';

import { DjStatus, Role } from '../common/types';
import { getStore } from './in_memory_store';
import { newId } from './ids';

function parseBool(value: string | undefined, defaultValue: boolean): boolean {
  if (value == null) return defaultValue;
  return ['1', 'true', 'yes', 'y', 'on'].includes(value.trim().toLowerCase());
}

/**
 * Seeds a dev ADMIN user and its DJ profile if missing.
 *
 * Env:
 * - ADMIN_EMAIL (default admin@zylo.fm)
 * - ADMIN_PASSWORD (default admin1234)
 * - ADMIN_CREATE_DJ_PROFILE (default true)
 */
export async function bootstrapInMemoryStore(): Promise<void> {
  const store = getStore();
  const adminEmail = (process.env.ADMIN_EMAIL ?? 'admin@zylo.fm').toLowerCase();
  const adminPassword = process.env.ADMIN_PASSWORD ?? 'admin1234';

  const existing = store.users.find((u) => u.email === adminEmail);
  if (!existing) {
    const passwordHash = await bcrypt.hash(adminPassword, 10);

    const adminUserId = newId('usr');
    store.users.push({
      id: adminUserId,
      email: adminEmail,
      passwordHash,
      role: Role.ADMIN,
      createdAt: new Date(),
    });

    if (parseBool(process.env.ADMIN_CREATE_DJ_PROFILE, true)) {
      const now = new Date();
      store.djProfiles.push({
        id: newId('dj'),
        userId: adminUserId,
        displayName: 'Zylo Admin',
        bio: 'Admin DJ profile (dev seed).',
        location: 'Zylo City',
        genres: ['house', 'techno'],
        status: DjStatus.APPROVED,
        createdAt: now,
        updatedAt: now,
      });
    }
  }
}

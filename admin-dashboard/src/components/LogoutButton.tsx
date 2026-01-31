'use client';

import { clearToken } from '@/lib/zylo/auth';

export function LogoutButton() {
  return (
    <button
      type="button"
      className="rounded-lg border border-neutral-800 bg-neutral-900 px-3 py-1.5 text-xs text-neutral-200 hover:bg-neutral-800"
      onClick={async () => {
        clearToken();
        window.location.href = '/login';
      }}
    >
      Logout
    </button>
  );
}

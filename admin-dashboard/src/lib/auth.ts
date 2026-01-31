import { SignJWT, jwtVerify } from 'jose';
import { cookies } from 'next/headers';

export const ADMIN_COOKIE_NAME = 'zylo_admin_session';

type AdminSessionPayload = {
  sub: 'local-admin';
  role: 'ADMIN';
};

function getSecretKey() {
  const secret = (process.env.ADMIN_DASHBOARD_JWT_SECRET ?? '').trim();
  if (!secret) {
    throw new Error('Missing env ADMIN_DASHBOARD_JWT_SECRET');
  }
  return new TextEncoder().encode(secret);
}

export async function signAdminSession() {
  const key = getSecretKey();
  const payload: AdminSessionPayload = { sub: 'local-admin', role: 'ADMIN' };

  return await new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(key);
}

export async function verifyAdminSession(token: string) {
  const key = getSecretKey();
  const { payload } = await jwtVerify(token, key, { algorithms: ['HS256'] });
  const role = payload.role;
  const sub = payload.sub;
  if (role !== 'ADMIN' || sub !== 'local-admin') {
    throw new Error('Invalid session');
  }
  return { sub: 'local-admin' as const, role: 'ADMIN' as const };
}

export async function getAdminFromRequestCookies() {
  const cookieStore = await cookies();
  const token = cookieStore.get(ADMIN_COOKIE_NAME)?.value;
  if (!token) return null;
  try {
    return await verifyAdminSession(token);
  } catch {
    return null;
  }
}

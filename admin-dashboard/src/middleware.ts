import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

function unauthorizedResponse() {
  return new NextResponse('Unauthorized', {
    status: 401,
    headers: {
      'WWW-Authenticate': 'Basic realm="ZyloFM Admin"',
    },
  });
}

function parseBasicAuth(header: string | null): { user: string; pass: string } | null {
  if (!header) return null;
  const [scheme, encoded] = header.split(' ');
  if (!scheme || scheme.toLowerCase() !== 'basic' || !encoded) return null;

  try {
    const decoded = Buffer.from(encoded, 'base64').toString('utf8');
    const idx = decoded.indexOf(':');
    if (idx < 0) return null;
    return { user: decoded.slice(0, idx), pass: decoded.slice(idx + 1) };
  } catch {
    return null;
  }
}

// Optional extra protection for the admin dashboard in production.
// Enable by setting BOTH env vars:
// - ADMIN_BASIC_AUTH_USER
// - ADMIN_BASIC_AUTH_PASSWORD
export function middleware(req: NextRequest) {
  const user = (process.env.ADMIN_BASIC_AUTH_USER ?? '').trim();
  const pass = process.env.ADMIN_BASIC_AUTH_PASSWORD ?? '';

  // If not configured, do nothing (keeps local dev simple).
  if (!user || !pass) return NextResponse.next();

  const auth = parseBasicAuth(req.headers.get('authorization'));
  if (!auth) return unauthorizedResponse();

  if (auth.user !== user || auth.pass !== pass) return unauthorizedResponse();

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};

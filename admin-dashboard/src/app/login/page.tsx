"use client";

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { API_URL } from '@/lib/zylo/config';
import { setToken } from '@/lib/zylo/auth';
import { toErrorMessage } from '@/lib/zylo/http';
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';

export default function LoginPage() {
  const router = useRouter();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  return (
    <main className="min-h-screen">
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col justify-center px-6">
        <div className="text-xs font-semibold tracking-wider text-neutral-400">ZyloFM</div>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight">Admin Login</h1>
        <p className="mt-2 text-sm text-neutral-400">Acceso para administrar música y DJs.</p>

        <Card className="mt-6">
          <CardHeader>
            <div>
              <CardTitle className="text-base">Sign in</CardTitle>
              <CardDescription className="mt-1">Usa tu usuario admin del backend.</CardDescription>
            </div>
          </CardHeader>
          <CardBody>
            <form
          className="space-y-3"
          onSubmit={async (e) => {
            e.preventDefault();
            setSubmitting(true);
            setError(null);
            try {
              const form = e.currentTarget;
              const fd = new FormData(form);
              const email = (fd.get('email') ?? '').toString().trim();
              const password = (fd.get('password') ?? '').toString();

              const res = await fetch(`${API_URL}/auth/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password }),
              });

              if (!res.ok) {
                const data = await res.json().catch(() => ({}));
                const msg =
                  (typeof data?.message === 'string' && data.message) ||
                  (Array.isArray(data?.message) ? data.message.join(', ') : '') ||
                  data?.error ||
                  'Login failed';
                throw new Error(msg);
              }

              const data = (await res.json()) as { access_token?: string };
              if (!data.access_token) throw new Error('Login ok but missing access_token');
              setToken(data.access_token);
              router.replace('/admin');
            } catch (err: unknown) {
              setError(toErrorMessage(err, 'Login failed'));
            } finally {
              setSubmitting(false);
            }
          }}
        >
          <label className="block text-sm text-neutral-300">
            Email
            <div className="mt-2">
              <Input
              name="email"
              type="email"
              autoComplete="username"
              placeholder="admin@zylo.fm"
              required
              />
            </div>
          </label>
          <label className="block text-sm text-neutral-300">
            Password
            <div className="mt-2">
              <Input
              name="password"
              type="password"
              autoComplete="current-password"
              placeholder="Tu password de admin"
              required
              />
            </div>
          </label>
          <Button type="submit" variant="primary" disabled={submitting} className="w-full">
            {submitting ? 'Entrando…' : 'Entrar'}
          </Button>

          {error ? <p className="text-sm text-red-300">{error}</p> : null}

          <p className="text-xs text-neutral-500">
            API: <span className="text-neutral-200">{API_URL}</span> (configurable via <span className="text-neutral-200">NEXT_PUBLIC_API_URL</span>).
          </p>
        </form>
          </CardBody>
        </Card>
      </div>
    </main>
  );
}


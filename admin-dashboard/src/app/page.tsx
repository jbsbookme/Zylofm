"use client";

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { getToken } from '@/lib/zylo/auth';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card';
import { API_URL } from '@/lib/zylo/config';

export default function HomePage() {
  const router = useRouter();

  useEffect(() => {
    const token = getToken();
    router.replace(token ? '/admin' : '/login');
  }, [router]);

  return (
    <main className="min-h-screen">
      <div className="mx-auto flex min-h-screen w-full max-w-2xl flex-col justify-center px-6">
        <div className="text-xs font-semibold tracking-wider text-neutral-400">ZyloFM</div>
        <h1 className="mt-2 text-4xl font-semibold tracking-tight">Admin Dashboard</h1>
        <p className="mt-2 text-sm text-neutral-400">Panel visual premium para la radio y el assistant.</p>

        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <Card className="overflow-hidden">
            <CardHeader>
              <div>
                <CardTitle className="text-base">Entrar</CardTitle>
                <CardDescription className="mt-1">Login admin para gestionar biblioteca y DJs.</CardDescription>
              </div>
            </CardHeader>
            <CardBody className="pt-0">
              <Link href="/login">
                <Button variant="primary">Go to Login</Button>
              </Link>
            </CardBody>
          </Card>

          <Card className="overflow-hidden">
            <CardHeader>
              <div>
                <CardTitle className="text-base">Status</CardTitle>
                <CardDescription className="mt-1">API target actual del dashboard.</CardDescription>
              </div>
            </CardHeader>
            <CardBody className="pt-0">
              <div className="rounded-2xl border border-white/10 bg-black/20 p-3 text-xs text-neutral-400">
                <div className="font-semibold text-neutral-200">{API_URL}</div>
                <div className="mt-1">Se configura con NEXT_PUBLIC_API_URL.</div>
              </div>
              <div className="mt-3 text-xs text-neutral-500">Redirigiendo…</div>
            </CardBody>
          </Card>
        </div>
      </div>
    </main>
  );
}

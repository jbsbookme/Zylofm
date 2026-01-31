'use client';

import { useEffect, useMemo, useState } from 'react';
import { apiFetch, apiJson, toErrorMessage, type ApiError } from '@/lib/zylo/http';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';

type DjRow = {
  id: string;
  displayName: string;
  location: string | null;
  genres: string[];
  status: 'PENDING' | 'APPROVED' | 'BLOCKED';
  createdAt: string;
  user?: { id: string; email: string; role: string };
};

export default function AdminDjsPage() {
  const [items, setItems] = useState<DjRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const pending = useMemo(() => items.filter((d) => d.status === 'PENDING'), [items]);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const data = await apiJson<DjRow[]>('/admin/djs?status=pending', { cache: 'no-store' });
      setItems(Array.isArray(data) ? data : []);
    } catch (e: unknown) {
      const msg = (e as Partial<ApiError>)?.message;
      setError(typeof msg === 'string' && msg.trim() ? msg : toErrorMessage(e, 'Failed to load DJs'));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void refresh();
  }, []);

  return (
    <section className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Pending DJs</h1>
          <p className="mt-1 text-sm text-neutral-400">{pending.length} pending</p>
        </div>
        <Button type="button" variant="secondary" onClick={() => void refresh()}>
          Refresh
        </Button>
      </div>

      {error ? (
        <div className="rounded-xl border border-red-900/40 bg-red-950/20 p-4 text-sm text-red-200">{error}</div>
      ) : null}

      <Card className="overflow-hidden">
        <CardHeader>
          <div>
            <CardTitle className="text-base">Queue</CardTitle>
            <CardDescription className="mt-1">Aprueba o rechaza solicitudes pendientes.</CardDescription>
          </div>
          {loading ? <div className="text-xs text-neutral-400">Loading…</div> : null}
        </CardHeader>

        <CardBody className="pt-0">
          <div className="divide-y divide-white/10">
          {!loading && pending.length === 0 ? (
            <div className="px-4 py-10 text-sm text-neutral-400">No pending DJs.</div>
          ) : null}

          {pending.map((dj) => (
            <div key={dj.id} className="grid gap-3 py-4 lg:grid-cols-[1fr_240px] lg:items-center">
              <div className="min-w-0">
                <div className="truncate font-medium text-neutral-100">{dj.displayName}</div>
                <div className="mt-1 text-xs text-neutral-400">
                  {dj.user?.email ? dj.user.email : 'No email'} {dj.location ? `· ${dj.location}` : ''}
                </div>
                <div className="mt-1 flex flex-wrap gap-1">
                  {(dj.genres ?? []).slice(0, 6).map((g) => (
                    <Badge key={g} tone="neutral">
                      {g}
                    </Badge>
                  ))}
                </div>
                <div className="mt-2 text-xs text-neutral-500">{new Date(dj.createdAt).toLocaleString()}</div>
              </div>

              <div className="flex flex-wrap gap-2 lg:justify-end">
                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  onClick={async () => {
                    setError(null);
                    try {
                      const res = await apiFetch(`/admin/djs/${dj.id}/approve`, { method: 'POST' });
                      if (!res.ok) throw new Error((await res.text().catch(() => '')) || 'Approve failed');
                      await refresh();
                    } catch (e: unknown) {
                      setError(toErrorMessage(e, 'Approve failed'));
                    }
                  }}
                >
                  Approve
                </Button>

                <Button
                  type="button"
                  variant="danger"
                  size="sm"
                  onClick={async () => {
                    if (!confirm('Reject (block) this DJ?')) return;
                    setError(null);
                    try {
                      const res = await apiFetch(`/admin/djs/${dj.id}/reject`, { method: 'POST' });
                      if (!res.ok) throw new Error((await res.text().catch(() => '')) || 'Reject failed');
                      await refresh();
                    } catch (e: unknown) {
                      setError(toErrorMessage(e, 'Reject failed'));
                    }
                  }}
                >
                  Reject
                </Button>
              </div>
            </div>
          ))}
          </div>
        </CardBody>
      </Card>
    </section>
  );
}

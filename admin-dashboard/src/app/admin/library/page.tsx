
'use client';

import { useEffect, useMemo, useState } from 'react';
import { apiFetch, apiJson, toErrorMessage, type ApiError } from '@/lib/zylo/http';
import { extractTrackMeta } from '@/components/track/TrackMetaCarousel';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

type AssistantLibraryItem = {
  id: string;
  title: string;
  audioUrl: string;
  keywords: string[];
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
};

function filterExtraKeywords(keywords: string[] | undefined) {
  const list = Array.isArray(keywords) ? keywords : [];
  const { artist, genre } = extractTrackMeta(list);
  const artistLc = artist?.toLowerCase() ?? null;
  const genreLc = genre?.toLowerCase() ?? null;

  return list.filter((k) => {
    const v = String(k).toLowerCase();
    if (v.startsWith('artist:') || v.startsWith('genre:')) return false;
    if (artistLc && v === artistLc) return false;
    if (genreLc && v === genreLc) return false;
    return true;
  });
}

function splitKeywordsForEdit(keywords: string[] | undefined) {
  const list = Array.isArray(keywords) ? keywords : [];
  const { artist, genre } = extractTrackMeta(list);
  const extra = filterExtraKeywords(list);
  return { artist: artist ?? '', genre: genre ?? '', extra: extra.join(', ') };
}

function buildKeywordsForSave(params: { artist: string; genre: string; extra: string }): string[] {
  const out: string[] = [];
  const a = params.artist.trim();
  const g = params.genre.trim();
  if (a) out.push(a, `artist:${a}`);
  if (g) out.push(g, `genre:${g}`);

  const extra = (params.extra ?? '')
    .split(/[\n,]+/g)
    .map((s) => s.trim())
    .filter(Boolean);
  out.push(...extra);
  return out;
}

export default function LibraryPage() {
  const [items, setItems] = useState<AssistantLibraryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [editingId, setEditingId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState('');
  const [editArtist, setEditArtist] = useState('');
  const [editGenre, setEditGenre] = useState('');
  const [editExtraKeywords, setEditExtraKeywords] = useState('');
  const [saving, setSaving] = useState(false);

  const activeCount = useMemo(() => items.filter((i) => i.isActive).length, [items]);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const data = await apiJson<AssistantLibraryItem[]>('/assistant/library', { cache: 'no-store' });
      setItems(Array.isArray(data) ? data : []);
    } catch (e: unknown) {
      const msg = (e as Partial<ApiError>)?.message;
      setError(typeof msg === 'string' && msg.trim() ? msg : toErrorMessage(e, 'Failed to load library'));
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
          <h1 className="text-2xl font-semibold tracking-tight">Music Library</h1>
          <p className="mt-1 text-sm text-neutral-400">
            {activeCount}/{items.length} active
          </p>
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
            <CardTitle className="text-base">Tracks</CardTitle>
            <CardDescription className="mt-1">Activa/desactiva, edita metadata y prueba preview.</CardDescription>
          </div>
          {loading ? <div className="text-xs text-neutral-400">Loading…</div> : null}
        </CardHeader>

        <CardBody className="pt-0">
          <div className="divide-y divide-white/10">
          {!loading && items.length === 0 ? (
            <div className="px-4 py-10 text-sm text-neutral-400">No tracks yet. Go to Upload Track.</div>
          ) : null}

          {items.map((item) => {
            const { artist, genre } = extractTrackMeta(item.keywords);
            return (
              <div key={item.id} className="grid gap-3 py-4 lg:grid-cols-[1fr_320px_260px] lg:items-center">
                <div className="min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <div className="truncate font-medium text-neutral-100">{item.title}</div>
                    <Badge tone={item.isActive ? 'success' : 'neutral'}>{item.isActive ? 'Active' : 'Inactive'}</Badge>
                  </div>

                  {artist || genre ? (
                    <div className="mt-1 text-xs text-neutral-400">{[artist, genre].filter(Boolean).join(' · ')}</div>
                  ) : null}

                  <div className="mt-2 text-xs text-neutral-500">Updated: {new Date(item.updatedAt).toLocaleString()}</div>

                  {editingId === item.id ? (
                    <div className="mt-3 rounded-2xl border border-white/10 bg-black/20 p-4">
                      <div className="grid gap-3 md:grid-cols-2">
                        <label className="block text-xs text-neutral-300">
                          Título
                          <div className="mt-1">
                            <Input value={editTitle} onChange={(e) => setEditTitle(e.currentTarget.value)} />
                          </div>
                        </label>
                        <label className="block text-xs text-neutral-300">
                          Artista
                          <div className="mt-1">
                            <Input value={editArtist} onChange={(e) => setEditArtist(e.currentTarget.value)} />
                          </div>
                        </label>
                        <label className="block text-xs text-neutral-300">
                          Género
                          <div className="mt-1">
                            <Input value={editGenre} onChange={(e) => setEditGenre(e.currentTarget.value)} />
                          </div>
                        </label>
                        <label className="block text-xs text-neutral-300">
                          Keywords extra
                          <div className="mt-1">
                            <Input
                              value={editExtraKeywords}
                              onChange={(e) => setEditExtraKeywords(e.currentTarget.value)}
                              placeholder="amor, romántica, 2024"
                            />
                          </div>
                        </label>
                      </div>

                      <div className="mt-3 flex flex-wrap gap-2">
                        <Button
                          type="button"
                          variant="primary"
                          size="sm"
                          disabled={saving}
                          onClick={async () => {
                            setError(null);
                            setSaving(true);
                            try {
                              await apiJson(`/assistant/library/${item.id}`, {
                                method: 'PATCH',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({
                                  title: editTitle,
                                  keywords: buildKeywordsForSave({
                                    artist: editArtist,
                                    genre: editGenre,
                                    extra: editExtraKeywords,
                                  }),
                                }),
                              });
                              setEditingId(null);
                              await refresh();
                            } catch (e: unknown) {
                              const msg = (e as Partial<ApiError>)?.message;
                              setError(typeof msg === 'string' && msg.trim() ? msg : toErrorMessage(e, 'Failed to update'));
                            } finally {
                              setSaving(false);
                            }
                          }}
                        >
                          {saving ? 'Saving…' : 'Save'}
                        </Button>

                        <Button type="button" variant="secondary" size="sm" disabled={saving} onClick={() => setEditingId(null)}>
                          Cancel
                        </Button>
                      </div>

                      <div className="mt-2 text-[11px] text-neutral-500">
                        Nota: el backend guarda keywords en minúsculas para el match.
                      </div>
                    </div>
                  ) : null}
                </div>

                <audio
                  className="w-full"
                  controls
                  preload="none"
                  src={item.audioUrl}
                  data-title={item.title}
                  data-artist={artist ?? ''}
                  data-genre={genre ?? ''}
                />

                <div className="flex flex-wrap gap-2 lg:justify-end">
                  <Button
                    type="button"
                    variant="secondary"
                    size="sm"
                    onClick={() => {
                      const { artist: a, genre: g, extra } = splitKeywordsForEdit(item.keywords);
                      setEditingId(item.id);
                      setEditTitle(item.title);
                      setEditArtist(a);
                      setEditGenre(g);
                      setEditExtraKeywords(extra);
                    }}
                  >
                    Edit
                  </Button>

                  <Button
                    type="button"
                    variant="secondary"
                    size="sm"
                    onClick={async () => {
                      setError(null);
                      try {
                        await apiJson(`/assistant/library/${item.id}`, {
                          method: 'PATCH',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({ isActive: !item.isActive }),
                        });
                        await refresh();
                      } catch (e: unknown) {
                        const msg = (e as Partial<ApiError>)?.message;
                        setError(typeof msg === 'string' && msg.trim() ? msg : toErrorMessage(e, 'Failed to update'));
                      }
                    }}
                  >
                    {item.isActive ? 'Deactivate' : 'Activate'}
                  </Button>

                  <Button
                    type="button"
                    variant="danger"
                    size="sm"
                    onClick={async () => {
                      if (!confirm('Delete this track?')) return;
                      setError(null);
                      const res = await apiFetch(`/assistant/library/${item.id}`, { method: 'DELETE' });
                      if (!res.ok) {
                        const text = await res.text().catch(() => '');
                        setError(text || 'Failed to delete');
                        return;
                      }
                      await refresh();
                    }}
                  >
                    Delete
                  </Button>
                </div>
              </div>
            );
          })}
          </div>
        </CardBody>
      </Card>
    </section>
  );
}

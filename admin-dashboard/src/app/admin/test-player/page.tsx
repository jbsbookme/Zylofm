'use client';

import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { apiFetch } from '@/lib/zylo/http';
import { TrackMetaCarousel, extractTrackMeta } from '@/components/track/TrackMetaCarousel';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

type PlayOk = {
  status: 'ok';
  query: string;
  audioUrl: string;
  match: { id: string; title: string; keywords: string[] };
};

type PlayState =
  | { state: 'idle' }
  | { state: 'loading' }
  | { state: 'nomatch' }
  | { state: 'error'; message: string }
  | { state: 'ok'; data: PlayOk };

export default function TestPlayerPage() {
  const searchParams = useSearchParams();
  const [query, setQuery] = useState('');
  const [playState, setPlayState] = useState<PlayState>({ state: 'idle' });

  const canPlay = useMemo(() => query.trim().length > 0, [query]);

  useEffect(() => {
    const q = (searchParams.get('q') ?? '').trim();
    if (!q) return;
    setQuery((prev) => (prev.trim() ? prev : q));
  }, [searchParams]);

  return (
    <section className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Test Player</h1>
        <p className="mt-1 text-sm text-neutral-400">POST /assistant/play → muestra match + preview.</p>
      </div>

      <Card>
        <CardHeader>
          <div>
            <CardTitle className="text-base">Search</CardTitle>
            <CardDescription className="mt-1">Tip: prueba queries de playlists, artista o género.</CardDescription>
          </div>
        </CardHeader>
        <CardBody>
          <label className="block text-sm text-neutral-300">
            Search query
            <div className="mt-2">
              <Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="amor" />
            </div>
          </label>

          <div className="mt-3 flex flex-wrap items-center gap-2">
            <Button
              type="button"
              variant="primary"
              disabled={!canPlay || playState.state === 'loading'}
              onClick={async () => {
                const q = query.trim();
                if (!q) return;
                setPlayState({ state: 'loading' });

                try {
                  const res = await apiFetch('/assistant/play', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ query: q }),
                  });

                  if (res.status === 404) {
                    setPlayState({ state: 'nomatch' });
                    return;
                  }

                  if (!res.ok) {
                    const text = await res.text().catch(() => '');
                    setPlayState({ state: 'error', message: text || `HTTP ${res.status}` });
                    return;
                  }

                  const data = (await res.json()) as PlayOk;
                  setPlayState({ state: 'ok', data });
                } catch (e: unknown) {
                  const msg = e && typeof e === 'object' && 'message' in e ? (e as { message?: unknown }).message : undefined;
                  setPlayState({
                    state: 'error',
                    message: typeof msg === 'string' && msg.trim() ? msg : 'Request failed',
                  });
                }
              }}
            >
              {playState.state === 'loading' ? 'Playing…' : 'Play'}
            </Button>

            <Button
              type="button"
              variant="secondary"
              onClick={() => {
                setQuery('');
                setPlayState({ state: 'idle' });
              }}
            >
              Clear
            </Button>
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>
          <div>
            <CardTitle className="text-base">Result</CardTitle>
            <CardDescription className="mt-1">Match + preview audio.</CardDescription>
          </div>
        </CardHeader>
        <CardBody>
          {playState.state === 'idle' ? <div className="text-sm text-neutral-400">Enter a query and hit Play.</div> : null}
          {playState.state === 'loading' ? <div className="text-sm text-neutral-400">Searching…</div> : null}
          {playState.state === 'nomatch' ? (
            <div className="text-sm text-neutral-200">
              <div className="font-semibold">No match</div>
              <div className="mt-1 text-neutral-400">Try different keywords or activate tracks in Library.</div>
            </div>
          ) : null}
          {playState.state === 'error' ? (
            <div className="text-sm text-red-300">
              <div className="font-semibold">Error</div>
              <div className="mt-1 whitespace-pre-wrap">{playState.message}</div>
            </div>
          ) : null}
          {playState.state === 'ok' ? (
            <div className="space-y-3">
              <div>
                <div className="text-sm font-semibold text-neutral-200">Match</div>
                <TrackMetaCarousel title={playState.data.match.title} keywords={playState.data.match.keywords} />
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {(playState.data.match.keywords ?? []).map((k) => (
                    <Badge key={k} tone="neutral">
                      {k}
                    </Badge>
                  ))}
                </div>
              </div>
              {(() => {
                const meta = extractTrackMeta(playState.data.match.keywords);
                return (
                  <audio
                    className="w-full"
                    controls
                    preload="none"
                    src={playState.data.audioUrl}
                    data-title={playState.data.match.title}
                    data-artist={meta.artist ?? ''}
                    data-genre={meta.genre ?? ''}
                  />
                );
              })()}
              <div className="text-xs text-neutral-500 break-all">{playState.data.audioUrl}</div>
            </div>
          ) : null}
        </CardBody>
      </Card>
    </section>
  );
}

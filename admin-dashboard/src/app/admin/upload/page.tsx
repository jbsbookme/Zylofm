'use client';

import { useState } from 'react';
import { apiFetch, toErrorMessage, type ApiError } from '@/lib/zylo/http';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';

type UploadResult = {
  id: string;
  title: string;
  audioUrl: string;
  keywords: string[];
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
};

export default function UploadPage() {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<UploadResult | null>(null);
  const [title, setTitle] = useState('');
  const [titleTouched, setTitleTouched] = useState(false);
  const [artist, setArtist] = useState('');
  const [genre, setGenre] = useState('');
  const [keywords, setKeywords] = useState('');
  const [fileInputKey, setFileInputKey] = useState(0);

  const deriveTitleFromFilename = (filename: string) => {
    const noExt = filename.replace(/\.[^/.]+$/, '');
    return noExt.replace(/[_-]+/g, ' ').trim();
  };

  const buildKeywords = () => {
    const parts: string[] = [];

    const clean = (value: string) => value.trim();
    const push = (value: string) => {
      const v = clean(value);
      if (v) parts.push(v);
    };

    // Include raw values for plain searching ("omega", "merengue") and tagged variants for display.
    push(artist);
    push(genre);
    if (artist.trim()) push(`artist:${clean(artist)}`);
    if (genre.trim()) push(`genre:${clean(genre)}`);
    push(keywords);

    // Deduplicate (case-insensitive) while preserving order.
    const seen = new Set<string>();
    const out: string[] = [];
    for (const p of parts
      .flatMap((p) => p.split(/[\n,]+/g))
      .map((p) => p.trim())
      .filter(Boolean)) {
      const key = p.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(p);
    }

    return out.join(', ');
  };

  return (
    <section className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Upload Track</h1>
        <p className="mt-1 text-sm text-neutral-400">Uploads to Cloudinary via backend: POST /assistant/library/upload</p>
      </div>

      <Card>
        <CardHeader>
          <div>
            <CardTitle className="text-base">New track</CardTitle>
            <CardDescription className="mt-1">Incluye artista/género/keywords para mejor match.</CardDescription>
          </div>
        </CardHeader>
        <CardBody>
          <form
        className="grid gap-3 md:grid-cols-2"
        onSubmit={async (e) => {
          e.preventDefault();
          setSubmitting(true);
          setError(null);
          setResult(null);

          try {
            const form = e.currentTarget;
            const fd = new FormData(form);

            // Overwrite keywords with a composed list so the assistant can match by artist/genre too.
            fd.set('keywords', buildKeywords());

            // Backend upload DTO only allows: title, keywords, audio, isActive.
            // Avoid sending UI-only fields that would be rejected by whitelist validation.
            fd.delete('artist');
            fd.delete('genre');

            const audio = fd.get('audio');
            if (!(audio instanceof File) || audio.size === 0) throw new Error('Audio file required');

            const res = await apiFetch('/assistant/library/upload', {
              method: 'POST',
              body: fd,
            });

            if (!res.ok) {
              const text = await res.text().catch(() => '');
              throw new Error(text || `Upload failed (HTTP ${res.status})`);
            }

            const data = (await res.json()) as UploadResult;
            setResult(data);
            setTitle('');
            setTitleTouched(false);
            setArtist('');
            setGenre('');
            setKeywords('');
            setFileInputKey((k) => k + 1);
          } catch (e: unknown) {
            const msg = (e as Partial<ApiError>)?.message;
            setError(typeof msg === 'string' && msg.trim() ? msg : toErrorMessage(e, 'Upload failed'));
          } finally {
            setSubmitting(false);
          }
        }}
      >
        <label className="block text-sm text-neutral-300">
          Title
          <div className="mt-2">
            <Input
            name="title"
            type="text"
            required
            maxLength={120}
            placeholder="Nombre de la canción"
            value={title}
            onChange={(e) => {
              if (!titleTouched) setTitleTouched(true);
              setTitle(e.currentTarget.value);
            }}
            />
          </div>
          <div className="mt-1 text-xs text-neutral-500">
            Tip: el assistant hace match usando <span className="text-neutral-300">Title</span> y <span className="text-neutral-300">Keywords</span> (aquí incluimos Artista/Género automáticamente).
          </div>
        </label>

        <label className="block text-sm text-neutral-300">
          Artista
          <div className="mt-2">
            <Input
            type="text"
            maxLength={120}
            placeholder="Ej: Romeo Santos"
            value={artist}
            onChange={(e) => setArtist(e.currentTarget.value)}
            />
          </div>
        </label>

        <label className="block text-sm text-neutral-300">
          Género
          <div className="mt-2">
            <Input
            type="text"
            maxLength={120}
            placeholder="Ej: Bachata, Reggaetón, Salsa"
            value={genre}
            onChange={(e) => setGenre(e.currentTarget.value)}
            />
          </div>
        </label>

        <label className="block text-sm text-neutral-300">
          Keywords extra (opcional)
          <div className="mt-2">
            <Input
            name="keywords"
            type="text"
            maxLength={400}
            placeholder="Ej: amor, romántica, 2024"
            value={keywords}
            onChange={(e) => setKeywords(e.currentTarget.value)}
            />
          </div>
        </label>

        <label className="block text-sm text-neutral-300">
          File (mp3/wav)
          <input
            key={fileInputKey}
            name="audio"
            type="file"
            accept="audio/mpeg,audio/wav,.mp3,.wav"
            required
            className="mt-2 w-full rounded-lg border border-neutral-800 bg-neutral-950 px-3 py-2 text-neutral-100"
            onChange={(e) => {
              const file = e.currentTarget.files?.[0];
              if (!file) return;
              if (!titleTouched && !title.trim()) {
                setTitle(deriveTitleFromFilename(file.name));
              }
            }}
          />
        </label>

        <label className="mt-7 flex items-center gap-2 text-sm text-neutral-300">
          <input name="isActive" type="checkbox" defaultChecked className="h-4 w-4 rounded border-neutral-700 bg-neutral-950" />
          Active
        </label>

        <div className="md:col-span-2">
          <Button type="submit" variant="primary" disabled={submitting}>
            {submitting ? 'Uploading…' : 'Upload'}
          </Button>

          {error ? <div className="mt-3 text-sm text-red-300">{error}</div> : null}

          {result ? (
            <div className="mt-4 rounded-2xl border border-white/10 bg-black/20 p-4">
              <div className="text-sm font-semibold text-neutral-100">Uploaded</div>
              <div className="mt-1 text-sm text-neutral-300">{result.title}</div>
              <div className="mt-1 text-xs text-neutral-500">Keywords: {result.keywords.join(', ')}</div>
              <audio className="mt-3 w-full" controls preload="none" src={result.audioUrl} />
            </div>
          ) : null}
        </div>
      </form>
        </CardBody>
      </Card>
    </section>
  );
}

'use client';

import { useEffect, useMemo, useState } from 'react';

type Props = {
  title: string;
  keywords?: string[];
};

export function getTaggedValue(keywords: string[] | undefined, tag: 'artist' | 'genre') {
  const list = Array.isArray(keywords) ? keywords : [];
  const prefix = `${tag}:`;
  const hit = list.find((k) => typeof k === 'string' && k.toLowerCase().startsWith(prefix));
  if (!hit) return null;
  const value = hit.slice(prefix.length).trim();
  return value || null;
}

export function extractTrackMeta(keywords: string[] | undefined) {
  return {
    artist: getTaggedValue(keywords, 'artist'),
    genre: getTaggedValue(keywords, 'genre'),
  };
}

function MetaCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-neutral-900 bg-neutral-950/70 px-3 py-2">
      <div className="text-[11px] font-semibold tracking-wide text-neutral-500">{label}</div>
      <div className="mt-1 text-sm text-neutral-100 whitespace-pre-wrap break-words">{value}</div>
    </div>
  );
}

export function TrackMetaCarousel({ title, keywords }: Props) {
  const { artist, genre } = extractTrackMeta(keywords);

  const slides = useMemo(() => {
    const parts = [title.trim(), artist?.trim() ?? '', genre?.trim() ?? ''].filter(Boolean);
    const combined = parts.join(' · ');

    const out: Array<{ label: string; value: string }> = [];
    if (combined) out.push({ label: 'Now', value: combined });
    if (title.trim()) out.push({ label: 'Título', value: title.trim() });
    if (artist?.trim()) out.push({ label: 'Artista', value: artist.trim() });
    if (genre?.trim()) out.push({ label: 'Género', value: genre.trim() });
    return out;
  }, [artist, genre, title]);

  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (slides.length <= 1) return;
    const id = window.setInterval(() => {
      setIndex((i) => (i + 1) % slides.length);
    }, 2500);
    return () => window.clearInterval(id);
  }, [slides.length]);

  useEffect(() => {
    setIndex(0);
  }, [slides]);

  const current = slides[index];
  if (!current) return null;
  return (
    <div className="mt-2">
      <MetaCard label={current.label} value={current.value} />
    </div>
  );
}

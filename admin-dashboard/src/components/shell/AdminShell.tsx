'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';
import { clearToken, getToken } from '@/lib/zylo/auth';
import { API_URL } from '@/lib/zylo/config';
import { EXTERNAL_LINKS } from '@/lib/zylo/links';

function IconExternal(props: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className={props.className ?? ''}>
      <path
        fill="currentColor"
        d="M14 3h7v7h-2V6.41l-9.29 9.3-1.42-1.42 9.3-9.29H14V3zM5 5h6v2H7v10h10v-4h2v6H5V5z"
      />
    </svg>
  );
}

function IconPlay(props: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className={props.className ?? ''}>
      <path fill="currentColor" d="M8 5v14l11-7z" />
    </svg>
  );
}

function IconPause(props: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className={props.className ?? ''}>
      <path fill="currentColor" d="M6 5h4v14H6zm8 0h4v14h-4z" />
    </svg>
  );
}

function IconStop(props: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className={props.className ?? ''}>
      <path fill="currentColor" d="M6 6h12v12H6z" />
    </svg>
  );
}

function NavItem({ href, label }: { href: string; label: string }) {
  const pathname = usePathname();
  const active = pathname === href || pathname?.startsWith(href + '/');

  return (
    <Link
      href={href}
      className={
        active
          ? 'group relative rounded-xl bg-white/8 px-3 py-2 text-sm text-white border border-white/10'
          : 'rounded-xl px-3 py-2 text-sm text-neutral-300 hover:bg-white/6 hover:text-white'
      }
    >
      {active ? (
        <span className="absolute inset-y-2 left-2 w-1 rounded-full bg-gradient-to-b from-violet-300 to-cyan-300" />
      ) : null}
      <span className={active ? 'pl-3' : ''}>{label}</span>
    </Link>
  );
}

function ExternalLink({ href, label }: { href: string; label: string }) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      className="group flex items-center justify-between gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs font-semibold text-neutral-200 hover:bg-white/8"
    >
      <span className="truncate">{label}</span>
      <IconExternal className="h-4 w-4 text-neutral-400 group-hover:text-neutral-200" />
    </a>
  );
}

export function AdminShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const token = getToken();

  const currentAudioRef = useRef<HTMLAudioElement | null>(null);
  const [nowPlaying, setNowPlaying] = useState<{ title: string; artist: string; genre: string } | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [ended, setEnded] = useState(false);

  useEffect(() => {
    if (!token) router.replace('/login');
  }, [router, token]);

  useEffect(() => {
    const onPlay = (e: Event) => {
      const target = e.target;
      if (!(target instanceof HTMLAudioElement)) return;

      const audios = Array.from(document.querySelectorAll('audio'));
      for (const audio of audios) {
        if (audio !== target && !audio.paused) {
          audio.pause();
        }
      }

      currentAudioRef.current = target;
      setIsPlaying(true);
      setEnded(false);
      setNowPlaying({
        title: target.dataset.title || 'Reproduciendo…',
        artist: target.dataset.artist || '',
        genre: target.dataset.genre || '',
      });
    };

    const onPauseOrEnded = (e: Event) => {
      const target = e.target;
      if (!(target instanceof HTMLAudioElement)) return;
      if (currentAudioRef.current !== target) return;
      if (e.type === 'ended') {
        setEnded(true);
      }
      setIsPlaying(false);
    };

    // Capture phase so it fires even if play is triggered internally.
    document.addEventListener('play', onPlay, true);
    document.addEventListener('pause', onPauseOrEnded, true);
    document.addEventListener('ended', onPauseOrEnded, true);
    return () => {
      document.removeEventListener('play', onPlay, true);
      document.removeEventListener('pause', onPauseOrEnded, true);
      document.removeEventListener('ended', onPauseOrEnded, true);
    };
  }, []);

  // If the underlying audio element disappears (navigation, list rerender, etc.),
  // clear the bar so controls don't act on a stale element.
  useEffect(() => {
    const id = window.setInterval(() => {
      const audio = currentAudioRef.current;
      if (!audio) return;
      if (!audio.isConnected) {
        currentAudioRef.current = null;
        setNowPlaying(null);
        setIsPlaying(false);
        setEnded(false);
      }
    }, 1500);
    return () => window.clearInterval(id);
  }, []);

  const combinedNowPlaying = nowPlaying
    ? [nowPlaying.title.trim(), nowPlaying.artist.trim(), nowPlaying.genre.trim()].filter(Boolean).join(' ')
    : '';

  const shouldMarquee = combinedNowPlaying.trim().length >= 28;

  if (!token) {
    return (
      <div className="min-h-screen bg-neutral-950 text-neutral-100">
        <div className="mx-auto max-w-6xl px-6 py-10 text-sm text-neutral-400">Cargando…</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen text-neutral-100">
      <div className="mx-auto grid w-full max-w-7xl grid-cols-1 gap-6 px-5 py-6 md:grid-cols-[280px_1fr]">
        <aside className="relative rounded-3xl border border-white/10 bg-[rgba(10,11,16,0.55)] p-4 backdrop-blur-xl shadow-[0_1px_0_0_rgba(255,255,255,0.06)_inset,0_24px_60px_-40px_rgba(0,0,0,0.85)] md:sticky md:top-6 md:h-[calc(100vh-48px)]">
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 rounded-2xl bg-gradient-to-br from-violet-400/80 to-cyan-300/70 shadow-[0_18px_40px_-28px_rgba(34,211,238,0.55)]" />
              <div>
                <div className="text-xs font-semibold tracking-wide text-neutral-400">ZyloFM</div>
                <div className="text-lg font-semibold tracking-tight">Admin Console</div>
              </div>
            </div>

            <button
              type="button"
              className="rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs font-semibold text-neutral-200 hover:bg-white/8"
              onClick={() => {
                clearToken();
                router.replace('/login');
              }}
            >
              Logout
            </button>
          </div>

          <div className="mt-5 grid gap-1">
            <div className="px-3 pb-1 text-[11px] font-semibold tracking-wider text-neutral-500">LIBRARY</div>
            <NavItem href="/admin" label="Overview" />
            <NavItem href="/admin/library" label="Music Library" />
            <NavItem href="/admin/upload" label="Upload Track" />

            <div className="mt-3 px-3 pb-1 text-[11px] font-semibold tracking-wider text-neutral-500">TOOLS</div>
            <NavItem href="/admin/test-player" label="Test Player" />
            <NavItem href="/admin/djs" label="Pending DJs" />
            <NavItem href="/admin/playlists" label="Playlists" />
          </div>

          <div className="mt-6">
            <div className="px-3 pb-1 text-[11px] font-semibold tracking-wider text-neutral-500">CONNECT</div>
            <div className="grid gap-2">
              {EXTERNAL_LINKS.length > 0 ? (
                EXTERNAL_LINKS.map((l) => <ExternalLink key={l.id} href={l.href} label={l.label} />)
              ) : (
                <div className="rounded-2xl border border-white/10 bg-black/20 p-3 text-xs text-neutral-400">
                  Add links via env: <span className="text-neutral-200">NEXT_PUBLIC_RADIO_24_7_URL</span>,{' '}
                  <span className="text-neutral-200">NEXT_PUBLIC_WHATSAPP_URL</span>, etc.
                </div>
              )}
            </div>
          </div>

          <div className="mt-6 rounded-2xl border border-white/10 bg-black/20 p-3 text-xs text-neutral-400">
            API target: <span className="text-neutral-200">{API_URL}</span>
          </div>
        </aside>

        <main
          className={
            'relative rounded-3xl border border-white/10 bg-[rgba(10,11,16,0.45)] p-6 backdrop-blur-xl shadow-[0_1px_0_0_rgba(255,255,255,0.06)_inset,0_24px_60px_-40px_rgba(0,0,0,0.85)]' +
            (nowPlaying ? ' pb-28' : '')
          }
        >
          {children}
        </main>
      </div>

      {nowPlaying ? (
        <div className="fixed inset-x-0 bottom-0 z-50 border-t border-white/10 bg-[rgba(8,9,13,0.80)] backdrop-blur-xl">
          <div className="mx-auto flex w-full max-w-7xl items-center gap-3 px-5 py-3">
            <button
              type="button"
              aria-label={isPlaying ? 'Pausar' : ended ? 'Reproducir de nuevo' : 'Reanudar'}
              title={isPlaying ? 'Pausar' : ended ? 'Replay' : 'Resume'}
              className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-violet-400 via-fuchsia-300 to-cyan-300 px-3 py-2 text-xs font-semibold text-neutral-950 hover:brightness-105"
              onClick={() => {
                const audio = currentAudioRef.current;
                if (!audio) return;
                if (isPlaying) {
                  audio.pause();
                  return;
                }
                if (ended) audio.currentTime = 0;
                void audio.play();
              }}
            >
              {isPlaying ? <IconPause className="h-4 w-4" /> : <IconPlay className="h-4 w-4" />}
              <span>{isPlaying ? 'Pause' : ended ? 'Replay' : 'Resume'}</span>
            </button>

            <div className="flex-1">
              <div className="rounded-2xl border border-white/10 bg-black/25 px-3 py-2">
                {shouldMarquee ? (
                  <div className="overflow-hidden">
                    <div className="zylo-marquee text-sm text-neutral-100 whitespace-nowrap">
                      <span className="pr-10">{combinedNowPlaying || nowPlaying.title}</span>
                      <span className="pr-10">{combinedNowPlaying || nowPlaying.title}</span>
                    </div>
                  </div>
                ) : (
                  <div className="text-sm text-neutral-100 break-words">{combinedNowPlaying || nowPlaying.title}</div>
                )}
              </div>
            </div>

            <button
              type="button"
              aria-label="Detener"
              title="Stop"
              className="inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs font-semibold text-neutral-200 hover:bg-white/8"
              onClick={() => {
                const audio = currentAudioRef.current;
                if (!audio) return;
                // Stop = pause + reset + hide bar.
                audio.pause();
                audio.currentTime = 0;
                currentAudioRef.current = null;
                setNowPlaying(null);
                setEnded(false);
                setIsPlaying(false);
              }}
            >
              <IconStop className="h-4 w-4" />
              <span>Stop</span>
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}

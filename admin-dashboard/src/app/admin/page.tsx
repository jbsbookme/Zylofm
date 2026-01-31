import Link from 'next/link';
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { FEATURED_PLAYLISTS } from '@/lib/playlists';
import { EXTERNAL_LINKS } from '@/lib/zylo/links';

export default function AdminHomePage() {
  return (
    <section className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Dashboard</h1>
        <p className="mt-1 text-sm text-neutral-400">Control de biblioteca, pruebas de playback y aprobación de DJs.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Link href="/admin/library" className="block">
          <Card className="h-full hover:border-white/15 transition">
            <CardHeader>
              <div>
                <CardTitle className="text-base">Music Library</CardTitle>
                <CardDescription className="mt-1">List / toggle / delete</CardDescription>
              </div>
            </CardHeader>
            <CardBody className="pt-0">
              <div className="text-xs text-neutral-400">Gestiona tracks activos e info.</div>
            </CardBody>
          </Card>
        </Link>

        <Link href="/admin/upload" className="block">
          <Card className="h-full hover:border-white/15 transition">
            <CardHeader>
              <div>
                <CardTitle className="text-base">Upload Track</CardTitle>
                <CardDescription className="mt-1">/assistant/library/upload</CardDescription>
              </div>
            </CardHeader>
            <CardBody className="pt-0">
              <div className="text-xs text-neutral-400">Sube audio con artista/género/keywords.</div>
            </CardBody>
          </Card>
        </Link>

        <Link href="/admin/test-player" className="block">
          <Card className="h-full hover:border-white/15 transition">
            <CardHeader>
              <div>
                <CardTitle className="text-base">Test Player</CardTitle>
                <CardDescription className="mt-1">Query → audioUrl</CardDescription>
              </div>
            </CardHeader>
            <CardBody className="pt-0">
              <div className="text-xs text-neutral-400">Prueba match del assistant rápido.</div>
            </CardBody>
          </Card>
        </Link>

        <Link href="/admin/djs" className="block">
          <Card className="h-full hover:border-white/15 transition">
            <CardHeader>
              <div>
                <CardTitle className="text-base">Pending DJs</CardTitle>
                <CardDescription className="mt-1">Approve / reject</CardDescription>
              </div>
            </CardHeader>
            <CardBody className="pt-0">
              <div className="text-xs text-neutral-400">Revisa solicitudes y géneros.</div>
            </CardBody>
          </Card>
        </Link>
      </div>

      <div className="grid gap-4 lg:grid-cols-[1.25fr_0.75fr]">
        <Card>
          <CardHeader>
            <div>
              <CardTitle className="text-base">Featured Playlists</CardTitle>
              <CardDescription className="mt-1">Con fotos + shortcut a Test Player.</CardDescription>
            </div>
            <Link href="/admin/playlists">
              <Button variant="secondary" size="sm">View all</Button>
            </Link>
          </CardHeader>
          <CardBody>
            <div className="grid gap-3 sm:grid-cols-2">
              {FEATURED_PLAYLISTS.slice(0, 4).map((p) => (
                <Link key={p.id} href={`/admin/test-player?q=${encodeURIComponent(p.query)}`} className="group block">
                  <div className="overflow-hidden rounded-2xl border border-white/10 bg-black/20 hover:border-white/15 transition">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={p.imageSrc} alt={p.title} className="h-28 w-full object-cover" loading="lazy" />
                    <div className="p-3">
                      <div className="font-semibold text-neutral-100">{p.title}</div>
                      <div className="mt-0.5 text-xs text-neutral-400">{p.description}</div>
                      <div className="mt-2 text-[11px] text-neutral-500">Try: <span className="text-neutral-200">{p.query}</span></div>
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <div>
              <CardTitle className="text-base">Redes & Radio</CardTitle>
              <CardDescription className="mt-1">WhatsApp + enlaces externos (24/7).</CardDescription>
            </div>
          </CardHeader>
          <CardBody>
            {EXTERNAL_LINKS.length > 0 ? (
              <div className="grid gap-2">
                {EXTERNAL_LINKS.map((l) => (
                  <a
                    key={l.id}
                    href={l.href}
                    target="_blank"
                    rel="noreferrer"
                    className="rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-neutral-200 hover:bg-white/8"
                  >
                    {l.label}
                  </a>
                ))}
              </div>
            ) : (
              <div className="text-sm text-neutral-400">
                Configura en <span className="text-neutral-200">admin-dashboard/.env.local</span>:
                <div className="mt-2 text-xs text-neutral-500">
                  NEXT_PUBLIC_RADIO_24_7_URL, NEXT_PUBLIC_WHATSAPP_URL, NEXT_PUBLIC_INSTAGRAM_URL…
                </div>
              </div>
            )}
          </CardBody>
        </Card>
      </div>
    </section>
  );
}

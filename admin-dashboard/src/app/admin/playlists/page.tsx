import Link from 'next/link';
import { FEATURED_PLAYLISTS } from '@/lib/playlists';
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';

export default function PlaylistsPage() {
  return (
    <section className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Playlists</h1>
        <p className="mt-1 text-sm text-neutral-400">Covers + shortcuts para probar queries en el assistant.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURED_PLAYLISTS.map((p) => (
          <Card key={p.id} className="overflow-hidden">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={p.imageSrc}
              alt={p.title}
              className="h-40 w-full object-cover"
              loading="lazy"
            />
            <CardHeader className="py-4">
              <div>
                <CardTitle className="text-base">{p.title}</CardTitle>
                <CardDescription className="mt-1 text-[12px]">{p.description}</CardDescription>
              </div>
            </CardHeader>
            <CardBody className="pt-0">
              <div className="flex flex-wrap items-center gap-2">
                <Link href={`/admin/test-player?q=${encodeURIComponent(p.query)}`}>
                  <Button variant="primary" size="sm">Try in Test Player</Button>
                </Link>
                <div className="text-xs text-neutral-400">Query: <span className="text-neutral-200">{p.query}</span></div>
              </div>
            </CardBody>
          </Card>
        ))}
      </div>
    </section>
  );
}

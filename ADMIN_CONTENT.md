# Admin Content (PASO 3)

ZyloFM ahora consume DJs, mixes, radio y destacados desde una fuente *admin-driven*.

## Fuente de contenido

Por defecto se carga desde:
- `assets/admin/content.json`

Opcionalmente, puedes apuntar a un endpoint JSON (sin backend complejo) usando `--dart-define`:

```bash
flutter run --dart-define=ZyloContentUrl=https://TU_DOMINIO/content.json
```

Regla de carga:
1) Si `ZyloContentUrl` existe y responde `200..299` con JSON válido → se usa ese contenido.
2) Si falla (timeout / error / JSON inválido) → fallback al asset `assets/admin/content.json`.

## Estructura del JSON

Archivo: `assets/admin/content.json`

Campos principales:
- `radio`: título + `streamUrl` + `coverUrl` + copy
- `djs`: lista de DJs
- `mixes`: lista de mixes
- `highlights`: ids para destacar (opcional)

Ejemplo mínimo:

```json
{
  "version": 1,
  "radio": {
    "title": "Radio ZyloFM",
    "streamUrl": "https://tu-stream",
    "coverUrl": "https://tu-cover",
    "tagline": "Copy corto",
    "badgeText": "RADIO • LIVE"
  },
  "djs": [{ "id": "dj_1", "name": "DJ Uno", "blurb": "..." }],
  "mixes": [{
    "id": "mix_1",
    "title": "Nombre del mix",
    "djId": "dj_1",
    "blurb": "...",
    "hlsUrl": "https://tu-hls.m3u8",
    "coverUrl": "https://tu-cover",
    "durationSec": 1800,
    "featured": true
  }],
  "highlights": {
    "heroMixId": "mix_1",
    "featuredMixIds": ["mix_1"],
    "featuredDjIds": ["dj_1"]
  }
}
```

## Cómo cambia el contenido (admin)

### Opción A — Editar el JSON del proyecto
1) Edita `assets/admin/content.json`
2) Ejecuta `flutter pub get` (si cambiaste assets en `pubspec.yaml`)
3) Corre la app: `flutter run`

### Opción B — Publicar un JSON remoto (recomendado)
- Sube `content.json` a un hosting simple (S3, Cloudflare R2, GitHub Pages, Netlify, Vercel, etc.)
- Lanza la app con:

```bash
flutter run --dart-define=ZyloContentUrl=https://tu-host/content.json
```

## Notas
- No se toca audio/player: el JSON solo alimenta lo que se ve en Home y los URLs que se pasan al audio handler.
- `durationSec` es en segundos.

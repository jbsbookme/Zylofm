# Admin Content (PASO 5)

ZyloFM consume DJs, mixes, radio y destacados desde una fuente *admin-driven* local.

## Fuente de contenido

Por defecto se carga desde:
- `assets/admin/content.json`

En PASO 5, este archivo es la **única** fuente de verdad (sin backend).

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

## Notas
- No se toca audio/player: el JSON solo alimenta lo que se ve en Home y los URLs que se pasan al audio handler.
- `durationSec` es en segundos.

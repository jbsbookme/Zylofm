# PASO 8.4 — Mix CRUD mínimo (sin audio/upload)

## 1) Modelo Mix en Prisma

Agregado en `prisma/schema.prisma`:

- `Mix`
- `MixStatus: DRAFT | PUBLISHED | TAKEDOWN`
- `MixVisibility: PUBLIC | UNLISTED`

Además:
- `DjProfile.approved` (bool) para bloquear publish si no está aprobado.

Migración (requiere Postgres accesible):

```bash
cd zylofm-backend/api
npx prisma migrate dev --name mixes
```

## 2) Endpoints DJ (protegidos)

Requieren Bearer token + `Role.DJ`.

- `POST /mixes` -> crea mix en `DRAFT`
- `PATCH /mixes/:id` -> edita metadata
- `POST /mixes/:id/publish` -> cambia a `PUBLISHED` (solo si `DjProfile.approved = true`)
- `GET /mixes/me` -> lista mis mixes

## 3) Endpoints públicos

- `GET /mixes` -> solo `PUBLISHED + PUBLIC`
- `GET /mixes/:id` -> `PUBLISHED + (PUBLIC o UNLISTED)`

## 4) Reglas (enforcement)

- DJ no aprobado: no puede publicar.
- UNLISTED: no aparece en listas públicas.
- TAKEDOWN: no aparece en listas, y tampoco se puede consultar por id.
- Admin: puede takedown cualquier mix con:
  - `POST /admin/mixes/:id/takedown` (ADMIN only)

## No incluido (PASO 9)

- Upload audio
- HLS
- Likes / playlists
- Comentarios

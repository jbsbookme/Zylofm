# PASO 8.3 — Seed + RBAC + DJ endpoints (MVP)

## 1) Seed inicial

### Roles base

Los roles base existen como enum en Prisma (`Role.ADMIN`, `Role.DJ`, `Role.LISTENER`).
No hay tabla extra de roles.

### Crear ADMIN

Se agregó un seed en `prisma/seed.ts` que **upsertea** un usuario ADMIN.

Variables requeridas (en `.env`, no se commitea):

- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`

Ejecutar (cuando la DB esté accesible):

```bash
cd zylofm-backend/api
npx prisma migrate dev --name init
npm run seed
```

## 2) RBAC

- Se usa `@Roles(...)` + `RolesGuard`.
- Todo bajo `/admin/*` requiere `Role.ADMIN`.
- `/dj/me` está protegido y solo permite `Role.DJ`.

## 3) Endpoints básicos (MVP)

### DJ (privado)

- `GET /dj/me`
- `PATCH /dj/me`

### Público

- `GET /dj/:id`
- `GET /djs`

## Notas

- No se toca Flutter.
- No se ejecuta `migrate dev` en este entorno si no hay Postgres corriendo.

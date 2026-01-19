# PASO 8.2 — Auth + Prisma (UI/frontend untouched)

## Qué incluye

- Prisma schema inicial con:
  - `Role` enum: `ADMIN`, `DJ`, `LISTENER`
  - `User` (email, passwordHash, role)
  - `DjProfile` (1:1 con User)
- Auth con JWT:
  - `POST /auth/register`
  - `POST /auth/login`
  - `GET /auth/me` (Bearer token)
- Validación de DTOs con `class-validator` + `ValidationPipe`

## Archivos clave

- Prisma schema: `prisma/schema.prisma`
- Auth:
  - `src/auth/auth.module.ts`
  - `src/auth/auth.controller.ts`
  - `src/auth/auth.service.ts`
  - `src/auth/jwt.strategy.ts`
- Prisma DI:
  - `src/prisma/prisma.module.ts`
  - `src/prisma/prisma.service.ts`

## Variables de entorno

En `.env` (ya creado):

- `DATABASE_URL="postgresql://postgres:zylo123@localhost:5432/zylofm?schema=public"`
- `JWT_SECRET="cambia_esto_por_algo_largo"`

> Nota: Nest carga `.env` vía `import 'dotenv/config'` en `src/main.ts`.

## Migraciones ("dejar listo" sin Docker)

En este entorno no hay Postgres corriendo, por lo que `prisma migrate dev` no puede ejecutarse aún.

Cuando tengas una base accesible (Docker o Postgres local), corre:

```bash
cd zylofm-backend/api
npx prisma migrate dev --name init
```

## Pruebas rápidas

### Register

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@zylo.fm","password":"password123","displayName":"DJ Test"}'
```

### Login

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@zylo.fm","password":"password123"}'
```

### Me

```bash
curl http://localhost:3000/auth/me \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

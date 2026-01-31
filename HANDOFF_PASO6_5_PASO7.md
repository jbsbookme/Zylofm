# Handoff ZyloFM — Estado PASO 6 / 6.5 → Próximo PASO 7

Fecha: 2026-01-24

## Qué está hecho

### PASO 1 (Mixes: subir → aprobar → publicar)
- Backend (NestJS + Prisma + Postgres):
  - DJs suben mixes, admin revisa/Aprueba/Rechaza.
  - Sólo mixes aprobados aparecen en endpoints públicos y en la app.
- Flutter:
  - Upload de mix (multipart), listas públicas, DJ profile con mixes aprobados.
  - Admin screen para revisar pendientes.

### PASO 5/6 (Asistente básico: query → audioUrl)
- Backend:
  - Librería de “assistant_library” en DB (tabla `AssistantLibraryItem`).
  - Endpoint público `POST /assistant/play` que hace matching simple por texto/keywords y retorna `{ audioUrl }`.
- Flutter:
  - Input de asistente en Home y reproducción con `just_audio`/`audio_service` (`playFromUrl`).

### PASO 6.5 (Admin sube audio → Cloudinary → auto-save en assistant_library)
- Backend:
  - Endpoint ADMIN multipart: `POST /assistant/library/upload`
    - Valida mp3/wav
    - Upload a Cloudinary folder `zylofm/assistant_library`
    - Crea `AssistantLibraryItem` automáticamente con `audioUrl` y `keywords`
  - Endpoints ADMIN:
    - `GET /assistant/library` lista items
    - `POST /assistant/library` (manual create por URL)
- Flutter:
  - Pantalla Admin para:
    - login como admin
    - pick mp3/wav
    - subir a `/assistant/library/upload`
    - listar items y preview (reproducir)

## Bloqueo que tuvimos (y cómo evitarlo)
- El fallo típico al probar upload es:
  - `HTTP 400` con mensaje “Cloudinary not configured…”
- Causa: `.env` equivocado o aún con placeholders `xxxxx`.
- El backend sí carga dotenv (en `zylofm-backend/api/src/main.ts` se importa `dotenv/config`).

## Checklist de verificación (para cerrar PASO 6.5 como OK)

### 1) Verificar `.env` correcto (sin exponer secretos)
Desde la carpeta del backend:

```bash
cd zylofm-backend/api

grep -n "^CLOUDINARY_" .env | sed -E 's/(CLOUDINARY_API_KEY=).+$/\1***redacted***/; s/(CLOUDINARY_API_SECRET=).+$/\1***redacted***/'
```

Asegúrate que:
- `CLOUDINARY_CLOUD_NAME` NO sea `xxxxx`
- `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` NO sean `xxxxx`
- `CLOUDINARY_UPLOAD_PRESET=zylofm_unsigned`

### 2) Reinicio limpio del backend

```bash
cd zylofm-backend/api
lsof -nP -iTCP:3000 -sTCP:LISTEN
# kill -9 <PID>

npm run start:dev
```

### 3) Smoke test end-to-end por API

Login admin:

```bash
curl -sS -o /tmp/zylo_login.json -w "login_http=%{http_code}\n" \
  -X POST http://localhost:3000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@zylo.fm","password":"admin123456"}'

ADMIN_TOKEN=$(python3 -c 'import json;print(json.load(open("/tmp/zylo_login.json"))["access_token"])')
```

Generar WAV pequeño:

```bash
python3 - <<'PY'
import wave,struct,math
p='/tmp/zylo_assistant.wav'
w=wave.open(p,'w')
w.setnchannels(1)
w.setsampwidth(2)
w.setframerate(44100)
frames=[]
for i in range(int(44100*0.25)):
    val=int(12000*math.sin(2*math.pi*440*i/44100))
    frames.append(struct.pack('<h',val))
w.writeframes(b''.join(frames))
w.close()
print('made',p)
PY
```

Upload (debe devolver 201 + `audioUrl` de Cloudinary):

```bash
curl -sS -o /tmp/assistant_upload.json -w "upload_http=%{http_code}\n" \
  -X POST http://localhost:3000/assistant/library/upload \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "audio=@/tmp/zylo_assistant.wav" \
  -F "title=Assistant Test Tone" \
  -F "keywords=afro,beep,test,tone" \
  -F "isActive=true"

cat /tmp/assistant_upload.json
```

Listar librería (debe incluir el item):

```bash
curl -sS -o /tmp/assistant_list.json -w "list_http=%{http_code}\n" \
  http://localhost:3000/assistant/library \
  -H "Authorization: Bearer $ADMIN_TOKEN"

head -c 1200 /tmp/assistant_list.json
```

Play query (debe devolver `{ audioUrl }` reproducible):

```bash
curl -sS -o /tmp/assistant_play.json -w "play_http=%{http_code}\n" \
  -X POST http://localhost:3000/assistant/play \
  -H 'Content-Type: application/json' \
  -d '{"query":"beep tone test"}'

cat /tmp/assistant_play.json
```

### Criterio para decir “PASO 6.5 OK”
- Upload: `upload_http=201`
- El JSON de upload contiene `audioUrl` que empieza con `https://res.cloudinary.com/…`
- `/assistant/library` lista el item
- `/assistant/play` devuelve un `audioUrl` funcional

## Próximo: PASO 7 (voz / micrófono / UX del asistente)
Objetivo propuesto para arrancar mañana:
- Flutter: grabación desde micrófono (permisos + UI/UX)
- Backend: endpoint para recibir audio (multipart), guardar en Cloudinary (posible folder `zylofm/assistant_queries`), y conectar con el asistente (según definición del PASO 7).

Antes de implementar, definir:
- iOS/Android permisos y librería de grabación elegida (p.ej. `record`, `flutter_sound`, etc.)
- Formato de audio (wav vs m4a) y tamaño/tiempo máximo
- Flujo UX: push-to-talk vs botón grabar/parar + estado “transcribiendo / buscando / reproduciendo”

# Google Play — Store Content (JBookMe / ZyloFM)

## 1) Descripción corta (≤ 80 caracteres)

**Opción A (ZyloFM)**
- Radio 24/7 y mixes: reproduce, descubre y comparte tu vibe.

**Opción B (JBookMe)**
- Agenda tu barbería y descubre contenido exclusivo en tu ciudad.

> Nota: elige UNA opción y úsala tal cual para cumplir el límite.

---

## 2) Descripción larga (Android)

### Opción A (ZyloFM — radio + mixes)

ZyloFM es tu app de audio para acompañarte todo el día.

- Radio 24/7 con energía real
- Mixes en streaming con controles de reproducción
- Descubre contenido y mantente al día con lo nuevo
- Experiencia simple, rápida y con diseño moderno

Ideal para entrenar, manejar o trabajar: abre la app, presiona play y listo.

**Soporte**: Si algo no carga, revisa tu conexión e inténtalo de nuevo.

### Opción B (JBookMe — comunidad + servicios)

JBookMe te ayuda a organizarte y conectar.

- Agenda y gestiona tus citas de forma sencilla
- Mantente informado con notificaciones importantes
- Contenido y novedades dentro de la app
- Experiencia clara, rápida y pensada para el día a día

Diseñada para usuarios que quieren comodidad y para profesionales que valoran el orden.

---

## 3) Texto de privacidad simple (Android)

**Privacidad**

Tu privacidad importa.

- Solo usamos la información necesaria para que la app funcione.
- No vendemos tu información personal.
- Podemos recopilar datos técnicos (por ejemplo, fallos/diagnóstico) para mejorar estabilidad.
- Si usas funciones como reproducción de audio en segundo plano o notificaciones, el sistema puede requerir permisos para habilitarlas.

**Contacto**: Para preguntas de privacidad o solicitudes de eliminación de datos, escribe a: soporte@zylofm.com (ajusta si usas otro correo).

---

## 4) Checklist de permisos que Google Play puede cuestionar

> Marca únicamente los que realmente usa tu build final. Incluyo el “por qué” para la justificación en Play Console.

**Permisos típicos para ZyloFM (audio/streaming)**
- `INTERNET` — streaming de radio/mixes y llamadas a la API.
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK` — reproducción en segundo plano con notificación.
- `POST_NOTIFICATIONS` (Android 13+) — mostrar controles/alertas.
- `WAKE_LOCK` (si aplica) — evitar cortes durante reproducción.
- `ACCESS_NETWORK_STATE` (si aplica) — detectar conectividad y mostrar mensajes.

**Permisos típicos si hay upload/selección de archivos**
- `READ_MEDIA_AUDIO` (Android 13+) — seleccionar audio local para subir.
- `READ_EXTERNAL_STORAGE` (Android 12 o menor) — compatibilidad con selección de archivos.

**Permisos “sensibles” (solo si están habilitados)**
- `RECORD_AUDIO` — búsqueda por voz / grabación (NO recomendado si no es esencial).
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — solo si la app muestra servicios por cercanía.
- `BLUETOOTH_CONNECT` (Android 12+) — si controlas dispositivos BT explícitamente.

**Checklist de revisión (para evitar rechazos)**
- No pidas permisos “por si acaso”.
- Explica el beneficio al usuario antes del prompt del sistema.
- En Play Console, al declarar “Data safety”, alinea permisos con uso real.

# 🎵 ZyloFM - Aplicación Móvil Flutter

## 📋 Requisitos Previos

Antes de ejecutar la aplicación, asegúrate de tener instalado:

1. **Flutter SDK** (versión 3.3.0 o superior)
   - Descarga desde: https://flutter.dev/docs/get-started/install
   - Verifica la instalación: `flutter doctor`

2. **Android Studio** o **Xcode** (para iOS)
   - Android Studio: https://developer.android.com/studio
   - Xcode (solo Mac): desde App Store

3. **Dispositivo o Emulador**
   - Emulador Android desde Android Studio
   - Simulador iOS desde Xcode (solo Mac)
   - O un dispositivo físico conectado por USB

## 🚀 Instalación y Ejecución

### Paso 1: Extraer el proyecto
Descomprime el archivo ZIP en la ubicación que prefieras.

### Paso 2: Abrir terminal en la carpeta del proyecto
```bash
cd zylo_fm_app
```

### Paso 3: Instalar dependencias
```bash
flutter pub get
```

### Paso 4: Verificar dispositivos disponibles
```bash
flutter devices
```

### Paso 5: Ejecutar la aplicación
```bash
flutter run
```

### iOS (iPhone físico) + Backend en tu Mac

Si estás corriendo el backend/admin-dashboard en tu Mac, **en iPhone no sirve `localhost`** (porque `localhost` sería el teléfono).

1) Asegúrate de que tu iPhone y tu Mac estén en la misma Wi‑Fi.

2) Obtén el IP de tu Mac (ejemplo): `192.168.0.121`.

3) Ejecuta el cliente Flutter pasando las URLs reales:
```bash
flutter run \
   --dart-define=ZYLO_API_BASE_URL=http://192.168.0.121:3000 \
   --dart-define=ADMIN_DASHBOARD_BASE_URL=http://192.168.0.121:3001
```

Si no carga nada o los botones no responden, normalmente es porque el iPhone no puede llegar al backend (IP incorrecto / firewall / backend apagado).

O para un dispositivo específico:
```bash
flutter run -d <device_id>
```

## 🌐 Producción “bien hecho” con 2 dominios (recomendado)

La forma más estable para que funcione en **iPhone (iOS)** y **Android** (sin pelearte con Wi‑Fi/Firewall) es usar **HTTPS + dominios públicos**.

- Dominio 1 (Admin Dashboard): `https://admin.tudominio.com`
- Dominio 2 (API backend): `https://api.tu-otro-dominio.com`

### Ejemplo con tus dominios

- App/API: `zylofm.com` → recomendamos `https://api.zylofm.com`
- Admin: `jblatinmusic.net` → recomendamos `https://admin.jblatinmusic.net`

### 1) Backend (API)

- Despliega el backend NestJS en un servidor/hosting (Render/Fly/Railway/DigitalOcean/etc.).
- Configura variables de entorno (ejemplo en: [zylofm-backend/api/.env.example](zylofm-backend/api/.env.example)).
- Importantísimo para el Admin Dashboard en web: define `CORS_ORIGINS` con el origen del dashboard.

Ejemplo:

- `CORS_ORIGINS=https://admin.tudominio.com`

Con tus dominios:

- `CORS_ORIGINS=https://admin.jblatinmusic.net`

### 2) Admin Dashboard (web)

- Despliega `admin-dashboard/` (por ejemplo en Vercel).
- En el hosting, define:

- `NEXT_PUBLIC_API_URL=https://api.tu-otro-dominio.com`

Seguridad recomendada (dominio privado admin):

- Activa una segunda capa (Basic Auth) en el hosting del Admin Dashboard:
   - `ADMIN_BASIC_AUTH_USER=...`
   - `ADMIN_BASIC_AUTH_PASSWORD=...`

Esto evita que cualquiera pueda siquiera ver la UI si descubre la URL.

Con tus dominios:

- `NEXT_PUBLIC_API_URL=https://api.zylofm.com`

Ejemplo en: [admin-dashboard/.env.example](admin-dashboard/.env.example)

### 3) Flutter (iOS/Android)

El cliente móvil NO debería usar `localhost`. En producción debe apuntar a tu API por HTTPS.

Para probar en un iPhone/Android ya con tu API pública:

```bash
flutter run \
   --dart-define=ZYLO_API_BASE_URL=https://api.tu-otro-dominio.com

Con tus dominios:

```bash
flutter run \
   --dart-define=ZYLO_API_BASE_URL=https://api.zylofm.com
```

Opcional (solo si quieres que la app también consulte endpoints públicos del Admin Dashboard, como radio/DJs):

```bash
flutter run \
   --dart-define=ZYLO_API_BASE_URL=https://api.zylofm.com \
   --dart-define=ADMIN_DASHBOARD_BASE_URL=https://admin.jblatinmusic.net
```
```

Con esto, la sección **Biblioteca** y todo lo público se alimenta del backend real.

## 📱 Características de la App

✅ **Reproductor de Audio Global**
- Reproducción de mixes HLS (audio de alta calidad)
- Reproducción de radio en vivo
- Audio en segundo plano (background)
- Controles en pantalla de bloqueo

✅ **MiniPlayer Persistente**
- Barra inferior siempre visible cuando hay audio
- Controles rápidos: play/pause
- Toca para abrir pantalla completa

✅ **Pantalla NowPlaying**
- Cover art grande
- Barra de progreso (solo para mixes)
- Controles completos: play/pause, skip ±15s, stop
- Indicadores de estado en tiempo real

✅ **Pantalla Principal**
- Lista de mixes disponibles
- Botón de Radio en Vivo
- Interfaz intuitiva y moderna

## 🎨 Estructura del Proyecto

```
zylo_fm_app/
├── lib/
│   ├── main.dart                    # Punto de entrada
│   ├── audio/
│   │   └── zylo_audio_handler.dart  # Lógica de reproducción
│   ├── screens/
│   │   ├── home_screen.dart         # Pantalla principal
│   │   └── now_playing_screen.dart  # Pantalla de reproducción
│   └── widgets/
│       └── mini_player.dart         # MiniPlayer persistente
├── android/                          # Configuración Android
├── ios/                              # Configuración iOS
└── pubspec.yaml                      # Dependencias
```

## 🔧 Personalización

### Contenido admin (sin backend complejo)
El contenido (radio, DJs, mixes y destacados) se controla desde:
- `assets/admin/content.json`

Guía completa: `ADMIN_CONTENT.md`.

### Cambiar tema de colores:
Edita `lib/main.dart` en la sección `theme` del MaterialApp.

### Agregar/editar DJs y mixes:
Edita `assets/admin/content.json` siguiendo el schema documentado en `ADMIN_CONTENT.md`.

## 🐛 Solución de Problemas

**Error: "No devices found"**
- Asegúrate de tener un emulador ejecutándose o un dispositivo conectado
- Ejecuta `flutter doctor` para verificar la configuración

**Error al instalar dependencias**
- Ejecuta `flutter clean` y luego `flutter pub get`

**Audio no funciona en Android**
- Verifica que los permisos estén configurados en AndroidManifest.xml
- Ya están incluidos en el proyecto

**Problemas con iOS**
- Ejecuta `cd ios && pod install` antes de correr la app

## 📞 Soporte

Para más información sobre Flutter:
- Documentación oficial: https://flutter.dev/docs
- Comunidad: https://flutter.dev/community

## 🎉 ¡Listo!

Tu aplicación ZyloFM está lista para usar. Disfruta de la música! 🎧

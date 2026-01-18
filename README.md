# ZyloFM - Aplicación Flutter de Streaming de Música

Aplicación móvil completa para streaming de mixes HLS y radio en vivo.

## Características

- 🎵 **Reproducción de Mixes HLS** - Streaming de audio de alta calidad
- 📻 **Radio en Vivo** - Transmisión en tiempo real
- 🔒 **Controles de Lockscreen** - Control desde la pantalla de bloqueo
- 🔔 **Notificaciones** - Controles persistentes en la barra de notificaciones
- 🎨 **UI Moderna** - Diseño Material 3 con tema oscuro

## Estructura del Proyecto

```
lib/
  main.dart                          # Punto de entrada
  audio/
    zylo_audio_handler.dart         # Manejador de audio (just_audio + audio_service)
  screens/
    home_screen.dart                # Pantalla principal con lista de mixes
    now_playing_screen.dart         # Pantalla de reproducción completa
  widgets/
    mini_player.dart                # Widget del mini reproductor
```

## Dependencias Principales

- `just_audio: ^0.9.39` - Reproductor de audio
- `audio_service: ^0.18.15` - Servicio de audio en background
- `just_audio_background: ^0.0.1-beta.13` - Integración de background
- `rxdart: ^0.27.7` - Streams reactivos

## Instalación y Ejecución

### Prerequisitos

- Flutter SDK 3.3.0 o superior
- Android Studio / Xcode

### Pasos

1. **Clonar e instalar dependencias:**
   ```bash
   cd zylo_fm_app
   flutter pub get
   ```

2. **Ejecutar en modo debug:**
   ```bash
   flutter run
   ```

3. **Build para Android:**
   ```bash
   flutter build apk --release
   ```

4. **Build para iOS:**
   ```bash
   flutter build ios --release
   ```

## Componentes

### ZyloAudioHandler

Manejador principal de audio que extiende `BaseAudioHandler`:

- `playHlsMix()` - Reproduce mixes en formato HLS
- `playRadio()` - Reproduce streams de radio en vivo
- `skipForward15()` / `skipBack15()` - Saltar 15 segundos
- Estados: idle, loading, playing, paused, buffering, error

### MiniPlayer

Barra inferior persistente que muestra:
- Cover art en miniatura
- Título y artista
- Botón play/pause
- Indicador "EN VIVO" para radio

### NowPlaying Screen

Pantalla completa con:
- Cover art grande (300x300)
- Controles completos
- Barra de progreso (solo mixes)
- Skip ±15 segundos

## Datos Mock

La app incluye datos de prueba:
- 5 mixes de ejemplo con URLs de HLS de prueba
- Stream de radio de ejemplo
- Imágenes de Unsplash como covers

## Configuración de Android

El `AndroidManifest.xml` incluye:
- Permisos de Internet
- Foreground Service para audio
- Media Browser Service
- Media Button Receiver

## Notas de Desarrollo

- Los URLs de HLS de prueba usan streams de Mux
- El stream de radio usa Zeno.fm como ejemplo
- Para producción, reemplazar con URLs reales del backend ZyloFM

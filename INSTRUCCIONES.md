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

O para un dispositivo específico:
```bash
flutter run -d <device_id>
```

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

### Conectar con tu propio backend:
Edita `lib/screens/home_screen.dart` y reemplaza las URLs mock con las de tu API real.

### Cambiar tema de colores:
Edita `lib/main.dart` en la sección `theme` del MaterialApp.

### Agregar más mixes:
Modifica el array `mockMixes` en `lib/screens/home_screen.dart`.

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

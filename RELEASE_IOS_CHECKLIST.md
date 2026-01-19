# ZyloFM — Checklist iOS / TestFlight

> Objetivo: dejar el proyecto listo para archivar, exportar y subir a TestFlight (sin depender de cambios en Apple Team).

## 1) Configuración base (una vez)
- Bundle ID correcto (debe coincidir con App ID en Apple Developer): `com.zylofm.app`
- Nombre visible iOS: `ZyloFM`
- Background audio habilitado en `Info.plist` (`UIBackgroundModes` incluye `audio`)
- Icon + splash verificados en `ios/Runner/Assets.xcassets`

## 2) Verificación de audio en background/lockscreen
En un iPhone real (preferible) o simulador (limitado):
- Reproducir un mix y bloquear pantalla: el audio NO se corta.
- Abrir Control Center / Lock Screen:
  - Play/Pause funciona.
  - Para mixes: aparecen Rewind/Forward (intervalos) y la barra de progreso.
  - Para radio: NO aparece seek/skip (solo Play/Pause y Stop).
- Con audífonos (AirPods o cable): Play/Pause y siguiente/prev según aplique.
- Interrupciones:
  - Llamada entrante / Siri: la app pausa/recupera sin quedar “colgada”.

## 3) Metadata del player (Now Playing)
- Mixes:
  - Title = nombre del mix
  - Artist = DJ
  - Album = `ZyloFM Mix`
  - Cover se muestra (si el `artUri` es accesible)
- Radio:
  - Title = `Radio ZyloFM`
  - Artist = `ZyloFM`
  - Album = `EN VIVO`
  - Cover se muestra (si el `artUri` es accesible)

> Nota: si el cover es remoto y falla en lockscreen, usar un URL estable/CDN o migrar a un asset local en una iteración futura.

## 4) Calidad del build (antes de archivar)
- `flutter analyze` sin issues.
- `flutter test` pasando.
- `flutter build ios --release --no-codesign` pasa.

## 5) Archive + Export (cuando Apple Developer esté listo)
- Xcode → abrir `ios/Runner.xcworkspace`
- Signing & Capabilities:
  - Team correcto
  - Automatic signing ON
- Product → Archive
- Organizer → Distribute App:
  - App Store Connect → Upload

## 6) App Store Connect / TestFlight
- App creada con el mismo bundle id.
- Build aparece en Processing y luego queda disponible.
- Completar “Test Information” (email, notes, etc.).
- Agregar testers internos.

## 7) Release sanity (UI)
- Home y Now Playing: contraste y legibilidad OK en brillo bajo.
- Mini-player: no tapa safe-area; no se solapa con gestures.
- Estado Loading/Buffering: feedback claro y consistente.

## 8) Antes de App Store Review (extra)
- Metadata en App Store Connect:
  - Nombre, subtítulo y descripción coherentes.
  - Keywords (si aplica) y categoría.
  - Screenshots correctos por dispositivo.
  - “Promotional text”/rating configurados.
- Cumplimiento y estabilidad:
  - La app no crashea al abrir, reproducir, bloquear/desbloquear.
  - Background audio se mantiene si el usuario inició reproducción.
  - No se inicia audio automáticamente al abrir (solo bajo acción del usuario).
  - Manejo de red: si no hay conexión, mostrar error y no quedar colgada.
- Privacidad:
  - Si en el futuro se agrega tracking/analytics, completar App Privacy.
  - Verificar que no se solicitan permisos innecesarios.
- Revisión rápida de políticas:
  - Contenido: el stream no debe tener material que infrinja derechos.
  - Evitar claims engañosos ("24/7" solo si es real).

/// ZyloFM - Aplicación de streaming de música
/// Punto de entrada principal de la aplicación

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'audio/zylo_audio_handler.dart';
import 'screens/home_screen.dart';

/// AudioHandler global accesible desde cualquier parte de la app
late final ZyloAudioHandler audioHandler;

Future<void> main() async {
  // Asegurar que los bindings de Flutter están inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar AudioService con nuestro ZyloAudioHandler
  audioHandler = await AudioService.init(
    builder: () => ZyloAudioHandler(),
    config: const AudioServiceConfig(
      // Configuración para Android
      androidNotificationChannelId: 'com.zylofm.app.playback',
      androidNotificationChannelName: 'ZyloFM Playback',
      androidNotificationChannelDescription: 'Controles de reproducción de ZyloFM',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
      // Configuración general
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      fastForwardInterval: Duration(seconds: 15),
      rewindInterval: Duration(seconds: 15),
      preloadArtwork: true,
    ),
  );

  // Ejecutar la aplicación
  runApp(const ZyloFMApp());
}

class ZyloFMApp extends StatelessWidget {
  const ZyloFMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZyloFM',
      debugShowCheckedModeBanner: false,
      
      // Tema oscuro por defecto (ideal para apps de música)
      themeMode: ThemeMode.dark,
      
      // Tema claro
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      
      // Tema oscuro
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Pantalla inicial
      home: HomeScreen(audioHandler: audioHandler),
    );
  }
}

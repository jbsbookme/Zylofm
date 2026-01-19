// ZyloAudioHandler - Manejador de audio para ZyloFM
// Extiende BaseAudioHandler con soporte para mixes HLS y radio en vivo

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

/// Estados posibles del reproductor
enum ZyloPlayerState {
  idle,      // Sin reproducir nada
  loading,   // Cargando audio
  playing,   // Reproduciendo
  paused,    // Pausado
  buffering, // Buffering (conexión lenta)
  error,     // Error en reproducción
}

/// Tipo de contenido actual
enum ZyloContentType {
  none,
  mix,
  radio,
}

class ZyloAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  Future<void>? _audioSessionConfigured;
  
  // Streams para UI
  final BehaviorSubject<ZyloPlayerState> _playerState = 
      BehaviorSubject.seeded(ZyloPlayerState.idle);
  final BehaviorSubject<ZyloContentType> _contentType = 
      BehaviorSubject.seeded(ZyloContentType.none);
  final BehaviorSubject<Duration> _position = 
      BehaviorSubject.seeded(Duration.zero);
  final BehaviorSubject<Duration> _duration = 
      BehaviorSubject.seeded(Duration.zero);
  final BehaviorSubject<Duration> _bufferedPosition = 
      BehaviorSubject.seeded(Duration.zero);

  // Getters para streams públicos
  Stream<ZyloPlayerState> get playerStateStream => _playerState.stream;
  Stream<ZyloContentType> get contentTypeStream => _contentType.stream;
  Stream<Duration> get positionStream => _position.stream;
  Stream<Duration> get durationStream => _duration.stream;
  Stream<Duration> get bufferedPositionStream => _bufferedPosition.stream;
  
  // Valores actuales
  ZyloPlayerState get currentState => _playerState.value;
  ZyloContentType get currentContentType => _contentType.value;
  Duration get currentPosition => _position.value;
  Duration get currentDuration => _duration.value;
  bool get isPlaying => _player.playing;
  bool get isLiveContent => _contentType.value == ZyloContentType.radio;

  ZyloAudioHandler() {
    _ensureAudioSessionConfigured();
    _initializeListeners();
  }

  Future<void> _ensureAudioSessionConfigured() {
    return _audioSessionConfigured ??= _configureAudioSession();
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (e) {
      if (kDebugMode) debugPrint('AudioSession configure failed: $e');
    }
  }

  Future<void> _ensureAudioSessionActive() async {
    try {
      await _ensureAudioSessionConfigured();
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (e) {
      if (kDebugMode) debugPrint('AudioSession setActive failed: $e');
    }
  }

  void _initializeListeners() {
    // Escuchar eventos de reproducción para notificaciones del sistema
    _player.playbackEventStream.listen(
      _broadcastPlaybackState,
      onError: (Object e, StackTrace st) {
        _playerState.add(ZyloPlayerState.error);
        if (kDebugMode) debugPrint('Error en playback: $e');
      },
    );

    // Escuchar cambios de estado de procesamiento
    _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.loading:
          _playerState.add(ZyloPlayerState.loading);
          break;
        case ProcessingState.buffering:
          _playerState.add(ZyloPlayerState.buffering);
          break;
        case ProcessingState.ready:
          _playerState.add(
            _player.playing ? ZyloPlayerState.playing : ZyloPlayerState.paused,
          );
          break;
        case ProcessingState.completed:
          // Al completar, reiniciar al inicio y pausar
          _player.seek(Duration.zero);
          _player.pause();
          _playerState.add(ZyloPlayerState.paused);
          break;
        case ProcessingState.idle:
          _playerState.add(ZyloPlayerState.idle);
          break;
      }
    });

    // Escuchar posición actual
    _player.positionStream.listen((position) {
      _position.add(position);
    });

    // Escuchar duración total
    _player.durationStream.listen((duration) {
      _duration.add(duration ?? Duration.zero);
    });

    // Escuchar posición del buffer
    _player.bufferedPositionStream.listen((buffered) {
      _bufferedPosition.add(buffered);
    });

    // Escuchar cambios de playing/paused
    _player.playingStream.listen((playing) {
      if (_player.processingState == ProcessingState.ready) {
        _playerState.add(
          playing ? ZyloPlayerState.playing : ZyloPlayerState.paused,
        );
      }
    });
  }

  /// Reproduce un mix HLS
  /// [mixId] - ID único del mix
  /// [title] - Título del mix
  /// [djName] - Nombre del DJ
  /// [hlsUrl] - URL del archivo HLS master.m3u8
  /// [coverUrl] - URL de la imagen de portada (opcional)
  /// [durationSec] - Duración en segundos (opcional)
  Future<void> playHlsMix({
    required String mixId,
    required String title,
    required String djName,
    required String hlsUrl,
    String? coverUrl,
    int? durationSec,
  }) async {
    await _ensureAudioSessionActive();
    _playerState.add(ZyloPlayerState.loading);
    _contentType.add(ZyloContentType.mix);

    // Actualizar mediaItem para notificaciones del sistema
    mediaItem.add(MediaItem(
      id: mixId,
      title: title,
      artist: djName,
      artUri: coverUrl != null ? Uri.parse(coverUrl) : null,
      duration: durationSec != null ? Duration(seconds: durationSec) : null,
      extras: {
        'type': 'mix',
        'hlsUrl': hlsUrl,
        'isLive': false,
      },
    ));

    try {
      await _player.setUrl(hlsUrl);
      await _player.play();
    } catch (e) {
      _playerState.add(ZyloPlayerState.error);
      if (kDebugMode) debugPrint('Error al reproducir mix: $e');
      rethrow;
    }
  }

  /// Reproduce radio en vivo
  /// [title] - Nombre de la estación
  /// [streamUrl] - URL del stream de audio
  /// [coverUrl] - URL de la imagen (opcional)
  Future<void> playRadio({
    required String title,
    required String streamUrl,
    String? coverUrl,
  }) async {
    await _ensureAudioSessionActive();
    _playerState.add(ZyloPlayerState.loading);
    _contentType.add(ZyloContentType.radio);

    // Actualizar mediaItem para notificaciones del sistema
    mediaItem.add(MediaItem(
      id: 'radio_live',
      title: title,
      artist: 'Radio en Vivo',
      artUri: coverUrl != null ? Uri.parse(coverUrl) : null,
      extras: {
        'type': 'radio',
        'streamUrl': streamUrl,
        'isLive': true,
      },
    ));

    try {
      await _player.setUrl(streamUrl);
      await _player.play();
    } catch (e) {
      _playerState.add(ZyloPlayerState.error);
      if (kDebugMode) debugPrint('Error al reproducir radio: $e');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    await _ensureAudioSessionActive();
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _playerState.add(ZyloPlayerState.idle);
    _contentType.add(ZyloContentType.none);
    mediaItem.add(null);
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    // No permitir seek en radio en vivo
    if (_contentType.value == ZyloContentType.radio) return;
    await _player.seek(position);
  }

  /// Adelantar 15 segundos (solo para mixes, no radio)
  Future<void> skipForward15() async {
    if (_contentType.value == ZyloContentType.radio) return;
    
    final newPosition = _player.position + const Duration(seconds: 15);
    final duration = _player.duration ?? Duration.zero;
    
    if (duration > Duration.zero && newPosition >= duration) {
      await _player.seek(duration - const Duration(seconds: 1));
    } else {
      await _player.seek(newPosition);
    }
  }

  /// Retroceder 15 segundos (solo para mixes, no radio)
  Future<void> skipBack15() async {
    if (_contentType.value == ZyloContentType.radio) return;
    
    final newPosition = _player.position - const Duration(seconds: 15);
    await _player.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  /// Broadcast del estado al sistema para controles de lockscreen
  void _broadcastPlaybackState(PlaybackEvent event) {
    final playing = _player.playing;
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _mapProcessingState(_player.processingState),
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _playerState.close();
    await _contentType.close();
    await _position.close();
    await _duration.close();
    await _bufferedPosition.close();
  }
}

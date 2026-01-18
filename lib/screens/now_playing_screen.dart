/// NowPlaying Screen - Pantalla completa del reproductor
/// Muestra controles completos, artwork grande y progreso

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../audio/zylo_audio_handler.dart';

class NowPlayingScreen extends StatelessWidget {
  final ZyloAudioHandler audioHandler;

  const NowPlayingScreen({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<ZyloContentType>(
          stream: audioHandler.contentTypeStream,
          builder: (context, snapshot) {
            final type = snapshot.data ?? ZyloContentType.none;
            return Text(
              type == ZyloContentType.radio ? 'Radio en Vivo' : 'Reproduciendo',
              style: const TextStyle(fontSize: 16),
            );
          },
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              
              // Cover art grande
              _buildLargeCoverArt(),
              
              const SizedBox(height: 32),
              
              // Info del track
              _buildTrackInfo(),
              
              const SizedBox(height: 24),
              
              // Indicador de estado
              _buildStateIndicator(),
              
              const SizedBox(height: 16),
              
              // Barra de progreso (solo para mixes)
              _buildProgressBar(),
              
              const SizedBox(height: 24),
              
              // Controles principales
              _buildMainControls(),
              
              const SizedBox(height: 16),
              
              // Botón stop
              _buildStopButton(context),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCoverArt() {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        
        return Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: mediaItem?.artUri != null
                ? Image.network(
                    mediaItem!.artUri.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                  )
                : _buildPlaceholderCover(),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade900,
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white38,
        size: 100,
      ),
    );
  }

  Widget _buildTrackInfo() {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        
        return Column(
          children: [
            // Título
            Text(
              mediaItem?.title ?? 'Sin título',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Artista con badge de EN VIVO si aplica
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (mediaItem?.extras?['isLive'] == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'EN VIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    mediaItem?.artist ?? 'Artista desconocido',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStateIndicator() {
    return StreamBuilder<ZyloPlayerState>(
      stream: audioHandler.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? ZyloPlayerState.idle;
        
        String? statusText;
        Color? statusColor;
        
        switch (state) {
          case ZyloPlayerState.loading:
            statusText = 'Cargando...';
            statusColor = Colors.amber;
            break;
          case ZyloPlayerState.buffering:
            statusText = 'Buffering...';
            statusColor = Colors.orange;
            break;
          case ZyloPlayerState.error:
            statusText = 'Error de reproducción';
            statusColor = Colors.red;
            break;
          default:
            break;
        }
        
        if (statusText == null) return const SizedBox(height: 20);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor?.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == ZyloPlayerState.loading || 
                  state == ZyloPlayerState.buffering)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (state == ZyloPlayerState.error)
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<ZyloContentType>(
      stream: audioHandler.contentTypeStream,
      builder: (context, typeSnapshot) {
        final contentType = typeSnapshot.data ?? ZyloContentType.none;
        
        // No mostrar progreso para radio en vivo
        if (contentType == ZyloContentType.radio) {
          return const SizedBox(height: 60);
        }
        
        return StreamBuilder<Duration>(
          stream: audioHandler.positionStream,
          builder: (context, posSnapshot) {
            return StreamBuilder<Duration>(
              stream: audioHandler.durationStream,
              builder: (context, durSnapshot) {
                return StreamBuilder<Duration>(
                  stream: audioHandler.bufferedPositionStream,
                  builder: (context, bufSnapshot) {
                    final position = posSnapshot.data ?? Duration.zero;
                    final duration = durSnapshot.data ?? Duration.zero;
                    final buffered = bufSnapshot.data ?? Duration.zero;
                    
                    return Column(
                      children: [
                        // Barra de progreso
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            value: duration.inMilliseconds > 0
                                ? position.inMilliseconds
                                    .clamp(0, duration.inMilliseconds)
                                    .toDouble()
                                : 0,
                            max: duration.inMilliseconds > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1,
                            onChanged: (value) {
                              audioHandler.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            },
                          ),
                        ),
                        
                        // Tiempos
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMainControls() {
    return StreamBuilder<ZyloPlayerState>(
      stream: audioHandler.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? ZyloPlayerState.idle;
        final isPlaying = state == ZyloPlayerState.playing;
        final isLoading = state == ZyloPlayerState.loading || 
                          state == ZyloPlayerState.buffering;

        return StreamBuilder<ZyloContentType>(
          stream: audioHandler.contentTypeStream,
          builder: (context, typeSnapshot) {
            final contentType = typeSnapshot.data ?? ZyloContentType.none;
            final isLive = contentType == ZyloContentType.radio;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Skip back 15s (solo para mixes)
                IconButton(
                  icon: const Icon(Icons.replay_10, size: 36),
                  onPressed: isLive ? null : () => audioHandler.skipBack15(),
                  color: isLive 
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3)
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // Play/Pause button grande
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 42,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              audioHandler.pause();
                            } else {
                              audioHandler.play();
                            }
                          },
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // Skip forward 15s (solo para mixes)
                IconButton(
                  icon: const Icon(Icons.forward_10, size: 36),
                  onPressed: isLive ? null : () => audioHandler.skipForward15(),
                  color: isLive 
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3)
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStopButton(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.stop_rounded),
      label: const Text('Detener'),
      onPressed: () {
        audioHandler.stop();
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
}

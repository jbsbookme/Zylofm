// NowPlaying Screen - Pantalla completa del reproductor
// Muestra controles completos, artwork grande y progreso

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../audio/zylo_audio_handler.dart';
import '../theme/zylo_theme.dart';
import '../widgets/pulsing_ring.dart';
import '../widgets/zylo_backdrop.dart';

class NowPlayingScreen extends StatelessWidget {
  final ZyloAudioHandler audioHandler;

  const NowPlayingScreen({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZyloColors.black,
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
              type == ZyloContentType.radio ? 'Radio ZyloFM' : 'Ahora Suena',
              style: const TextStyle(fontSize: 16),
            );
          },
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: ZyloBackdrop(intensity: 1.0),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(),
                  _buildLargeCoverArt(),
                  const SizedBox(height: 26),
                  _buildTrackInfo(),
                  const SizedBox(height: 18),
                  _buildStateIndicator(),
                  const SizedBox(height: 14),
                  _buildProgressBar(),
                  const SizedBox(height: 18),
                  _buildMainControls(),
                  const SizedBox(height: 10),
                  _buildStopButton(context),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeCoverArt() {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              ...ZyloFx.glow(ZyloColors.electricBlue, blur: 34),
              ...ZyloFx.glow(ZyloColors.zyloYellow, blur: 28),
              BoxShadow(
                color: Colors.black.withAlphaF(0.65),
                blurRadius: 40,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
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
        gradient: ZyloFx.neonSheen(opacity: 1),
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
                      color: ZyloColors.liveRed.withAlphaF(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: ZyloColors.liveRed.withAlphaF(0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: ZyloColors.liveRed, size: 8),
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
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
            statusText = 'Conectando…';
            statusColor = ZyloColors.zyloYellow;
            break;
          case ZyloPlayerState.buffering:
            statusText = 'Cargando…';
            statusColor = ZyloColors.electricBlue;
            break;
          case ZyloPlayerState.error:
            statusText = 'Error de reproducción';
            statusColor = const Color(0xFFFF4D4D);
            break;
          default:
            break;
        }
        
        if (statusText == null) return const SizedBox(height: 20);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor?.withAlphaF(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor!.withAlphaF(0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == ZyloPlayerState.loading || 
                  state == ZyloPlayerState.buffering)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: statusColor,
                  ),
                ),
              if (state == ZyloPlayerState.error)
                const Icon(Icons.error_outline, size: 14, color: Color(0xFFFF4D4D)),
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
                final position = posSnapshot.data ?? Duration.zero;
                final duration = durSnapshot.data ?? Duration.zero;

                return Column(
                  children: [
                        // Barra de progreso
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: ZyloColors.zyloYellow,
                            inactiveTrackColor: const Color(0xFF2A2A36),
                            thumbColor: ZyloColors.zyloYellow,
                            overlayColor: ZyloColors.zyloYellow.withAlphaF(0.12),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
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
                      ? Colors.white24
                      : Colors.white70,
                ),
                
                const SizedBox(width: 16),
                
                // Play/Pause button grande
                PulsingRing(
                  isActive: isPlaying && !isLoading,
                  color: isPlaying ? ZyloColors.zyloYellow : ZyloColors.electricBlue,
                  size: 84,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPlaying ? ZyloColors.zyloYellow : ZyloColors.electricBlue,
                      boxShadow: ZyloFx.glow(
                        isPlaying ? ZyloColors.zyloYellow : ZyloColors.electricBlue,
                        blur: 30,
                      ),
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeOut,
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                key: ValueKey<bool>(isPlaying),
                                size: 44,
                                color: isPlaying ? Colors.black : Colors.white,
                              ),
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
                ),
                
                const SizedBox(width: 16),
                
                // Skip forward 15s (solo para mixes)
                IconButton(
                  icon: const Icon(Icons.forward_10, size: 36),
                  onPressed: isLive ? null : () => audioHandler.skipForward15(),
                  color: isLive 
                      ? Colors.white24
                      : Colors.white70,
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
        foregroundColor: Colors.white70,
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

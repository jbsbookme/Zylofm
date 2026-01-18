/// MiniPlayer Widget - Barra inferior persistente del reproductor
/// Muestra información del track actual y controles básicos

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../audio/zylo_audio_handler.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  final ZyloAudioHandler audioHandler;

  const MiniPlayer({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;
        
        // No mostrar si no hay nada reproduciéndose
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<ZyloPlayerState>(
          stream: audioHandler.playerStateStream,
          builder: (context, stateSnapshot) {
            final playerState = stateSnapshot.data ?? ZyloPlayerState.idle;
            
            // No mostrar en estado idle
            if (playerState == ZyloPlayerState.idle) {
              return const SizedBox.shrink();
            }

            return GestureDetector(
              onTap: () => _navigateToNowPlaying(context),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cover art pequeño
                    _buildCoverArt(mediaItem),
                    
                    // Información del track
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaItem.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                // Badge de "EN VIVO" para radio
                                if (mediaItem.extras?['isLive'] == true) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'EN VIVO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    mediaItem.artist ?? 'Artista desconocido',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Indicador de estado (loading/buffering)
                    _buildStateIndicator(playerState),
                    
                    // Botón play/pause
                    _buildPlayPauseButton(playerState),
                    
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoverArt(MediaItem mediaItem) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[800],
      ),
      child: mediaItem.artUri != null
          ? Image.network(
              mediaItem.artUri.toString(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
            )
          : _buildPlaceholderCover(),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: Colors.deepPurple.shade800,
      child: const Icon(
        Icons.music_note,
        color: Colors.white54,
        size: 28,
      ),
    );
  }

  Widget _buildStateIndicator(ZyloPlayerState state) {
    if (state == ZyloPlayerState.loading || state == ZyloPlayerState.buffering) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPlayPauseButton(ZyloPlayerState state) {
    final isPlaying = state == ZyloPlayerState.playing;
    final isLoading = state == ZyloPlayerState.loading || 
                      state == ZyloPlayerState.buffering;

    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 32,
      ),
      onPressed: isLoading
          ? null
          : () {
              if (isPlaying) {
                audioHandler.pause();
              } else {
                audioHandler.play();
              }
            },
    );
  }

  void _navigateToNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NowPlayingScreen(audioHandler: audioHandler),
      ),
    );
  }
}

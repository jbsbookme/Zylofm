// MiniPlayer Widget - Barra inferior persistente del reproductor
// Muestra información del track actual y controles básicos

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../audio/zylo_audio_handler.dart';
import '../screens/now_playing_screen.dart';
import '../theme/zylo_theme.dart';
import 'equalizer_bars.dart';
import 'pulsing_ring.dart';

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
                height: 74,
                decoration: BoxDecoration(
                  color: ZyloColors.panel.withAlphaF(0.96),
                  border: const Border(
                    top: BorderSide(color: Color(0xFF1C1C28), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlphaF(0.55),
                      blurRadius: 24,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProgressLine(context, mediaItem),
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          _buildCoverArt(mediaItem),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextBlock(context, mediaItem),
                          ),
                          _buildNowPlayingIndicator(playerState),
                          _buildPlayPauseButton(playerState),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNowPlayingIndicator(ZyloPlayerState state) {
    if (state == ZyloPlayerState.loading || state == ZyloPlayerState.buffering) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final isActive = state == ZyloPlayerState.playing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: EqualizerBars(
        isActive: isActive,
        color: isActive ? ZyloColors.zyloYellow : Colors.white24,
        height: 16,
        bars: 5,
      ),
    );
  }

  Widget _buildProgressLine(BuildContext context, MediaItem mediaItem) {
    return StreamBuilder<ZyloContentType>(
      stream: audioHandler.contentTypeStream,
      builder: (context, typeSnapshot) {
        final type = typeSnapshot.data ?? ZyloContentType.none;
        final isLive = type == ZyloContentType.radio || mediaItem.extras?['isLive'] == true;

        if (isLive) {
          return Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ZyloColors.liveRed.withAlphaF(0.0),
                  ZyloColors.liveRed.withAlphaF(0.9),
                  ZyloColors.liveRed.withAlphaF(0.0),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<Duration>(
          stream: audioHandler.positionStream,
          builder: (context, posSnapshot) {
            return StreamBuilder<Duration>(
              stream: audioHandler.durationStream,
              builder: (context, durSnapshot) {
                final p = posSnapshot.data ?? Duration.zero;
                final d = durSnapshot.data ?? Duration.zero;

                final progress = d.inMilliseconds <= 0
                    ? 0.0
                    : (p.inMilliseconds / d.inMilliseconds).clamp(0.0, 1.0);

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 3,
                    color: const Color(0xFF1C1C28),
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ZyloColors.electricBlue,
                              ZyloColors.zyloYellow,
                              ZyloColors.neonGreen,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTextBlock(BuildContext context, MediaItem mediaItem) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaItem.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            if (mediaItem.extras?['isLive'] == true) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ZyloColors.liveRed.withAlphaF(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ZyloColors.liveRed.withAlphaF(0.35)),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.7),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                mediaItem.artist ?? '—',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoverArt(MediaItem mediaItem) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: ZyloColors.panel2,
        boxShadow: ZyloFx.glow(ZyloColors.electricBlue, blur: 14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: mediaItem.artUri != null
            ? Image.network(
                mediaItem.artUri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
              )
            : _buildPlaceholderCover(),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(gradient: ZyloFx.neonSheen(opacity: 0.9)),
      child: const Icon(
        Icons.music_note,
        color: Colors.white54,
        size: 28,
      ),
    );
  }

  Widget _buildPlayPauseButton(ZyloPlayerState state) {
    final isPlaying = state == ZyloPlayerState.playing;
    final isLoading = state == ZyloPlayerState.loading || 
                      state == ZyloPlayerState.buffering;

    return PulsingRing(
      isActive: isPlaying && !isLoading,
      color: isPlaying ? ZyloColors.zyloYellow : ZyloColors.electricBlue,
      size: 46,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPlaying ? ZyloColors.zyloYellow : ZyloColors.electricBlue,
          boxShadow: ZyloFx.glow(isPlaying ? ZyloColors.zyloYellow : ZyloColors.electricBlue),
        ),
        child: IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 26,
            color: isPlaying ? Colors.black : Colors.white,
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
        ),
      ),
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

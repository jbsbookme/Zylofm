// Home Screen - Pantalla principal de ZyloFM
// Muestra la lista de mixes y acceso a radio en vivo

import 'package:flutter/material.dart';
import '../audio/zylo_audio_handler.dart';
import '../widgets/mini_player.dart';
import '../widgets/zylo_backdrop.dart';
import 'now_playing_screen.dart';
import '../theme/zylo_theme.dart';

/// Modelo de datos para un mix
class MixItem {
  final String id;
  final String title;
  final String djName;
  final String hlsUrl;
  final String? coverUrl;
  final int durationSec;

  const MixItem({
    required this.id,
    required this.title,
    required this.djName,
    required this.hlsUrl,
    this.coverUrl,
    required this.durationSec,
  });

  String get formattedDuration {
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class HomeScreen extends StatelessWidget {
  final ZyloAudioHandler audioHandler;

  const HomeScreen({super.key, required this.audioHandler});

  // Datos mock para testing
  static const List<MixItem> _mockMixes = [
    MixItem(
      id: 'mix-001',
      title: 'Deep House Vibes',
      djName: 'DJ Luna',
      hlsUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      coverUrl: 'https://i.ytimg.com/vi/aA1WiiVgbqQ/maxresdefault.jpg',
      durationSec: 2730, // 45:30
    ),
    MixItem(
      id: 'mix-002',
      title: 'Techno Nights',
      djName: 'DJ Storm',
      hlsUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
      durationSec: 3135, // 52:15
    ),
    MixItem(
      id: 'mix-003',
      title: 'Chill Beats',
      djName: 'DJ Zen',
      hlsUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
      durationSec: 2325, // 38:45
    ),
    MixItem(
      id: 'mix-004',
      title: 'Progressive Journey',
      djName: 'DJ Nova',
      hlsUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      coverUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400',
      durationSec: 3600, // 60:00
    ),
    MixItem(
      id: 'mix-005',
      title: 'Sunset Session',
      djName: 'DJ Aurora',
      hlsUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
      durationSec: 2850, // 47:30
    ),
  ];

  // URL de ejemplo para radio en vivo (stream de prueba)
  static const String _radioStreamUrl = 'https://stream.zeno.fm/0r0xa792kwzuv';
  static const String _radioCoverUrl = 'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=400';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: ZyloColors.black,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ZyloBackdrop(intensity: 0.95),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _buildHeader(context),
                  ),
                ),
              ),

              // Card grande de Radio ZyloFM (Live)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                  child: _buildLiveHeroCard(context),
                ),
              ),

              // Featured Mixes horizontal
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _buildSectionHeader(context, title: 'Mixes Destacados'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 210,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final mix = _mockMixes[index % _mockMixes.length];
                      return _buildFeaturedMixCard(context, mix);
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: _mockMixes.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // DJs (lista simple con play rápido)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _buildSectionHeader(context, title: 'DJs en Cabina'),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final djName = _uniqueDjs[index];
                    final mix = _mockMixes.firstWhere((m) => m.djName == djName);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _buildDjRow(context, djName: djName, mix: mix),
                    );
                  },
                  childCount: _uniqueDjs.length,
                ),
              ),

              // Espacio para el MiniPlayer
              SliverToBoxAdapter(
                child: SizedBox(height: 84 + bottomInset),
              ),
            ],
          ),

          // MiniPlayer persistente en la parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(audioHandler: audioHandler),
          ),
        ],
      ),
    );
  }

  static List<String> get _uniqueDjs {
    final seen = <String>{};
    final djs = <String>[];
    for (final m in _mockMixes) {
      if (seen.add(m.djName)) djs.add(m.djName);
    }
    return djs;
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
              children: const [
                TextSpan(text: 'Zylo'),
                TextSpan(text: 'FM'),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: ZyloColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1C1C28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ZyloColors.neonGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveHeroCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _playRadio(context),
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            gradient: ZyloFx.neonSheen(opacity: 1),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.18,
                  child: Image.network(
                    _radioCoverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xCC000000),
                        Color(0x88000000),
                        Color(0xCC000000),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: ZyloColors.liveRed.withAlphaF(0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: ZyloColors.liveRed.withAlphaF(0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: ZyloColors.liveRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'RADIO • LIVE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Radio ZyloFM',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Negro total. Energía neón. 24/7.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ZyloColors.zyloYellow,
                        boxShadow: ZyloFx.glow(ZyloColors.zyloYellow),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedMixCard(BuildContext context, MixItem mix) {
    return SizedBox(
      width: 165,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _playMix(context, mix),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: mix.coverUrl != null
                          ? Image.network(
                              mix.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildMixPlaceholder(),
                            )
                          : _buildMixPlaceholder(),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xAA000000),
                              Color(0xFF000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ZyloColors.electricBlue.withAlphaF(0.92),
                          boxShadow: ZyloFx.glow(ZyloColors.electricBlue),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mix.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mix.djName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                          ),
                        ),
                        Text(
                          mix.formattedDuration,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDjRow(BuildContext context, {required String djName, required MixItem mix}) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _playMix(context, mix),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      ZyloColors.electricBlue.withAlphaF(0.35),
                      ZyloColors.neonGreen.withAlphaF(0.18),
                      ZyloColors.zyloYellow.withAlphaF(0.22),
                    ],
                  ),
                  boxShadow: ZyloFx.glow(ZyloColors.electricBlue, blur: 16),
                ),
                child: Center(
                  child: Text(
                    djName.isNotEmpty ? djName.trim().substring(0, 1).toUpperCase() : 'D',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      djName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mix.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ZyloColors.panel2,
                  border: Border.all(color: const Color(0xFF252535)),
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMixPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: ZyloFx.neonSheen(opacity: 0.9),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white38,
        size: 28,
      ),
    );
  }

  Future<void> _playMix(BuildContext context, MixItem mix) async {
    try {
      await audioHandler.playHlsMix(
        mixId: mix.id,
        title: mix.title,
        djName: mix.djName,
        hlsUrl: mix.hlsUrl,
        coverUrl: mix.coverUrl,
        durationSec: mix.durationSec,
      );
      
      // Navegar a NowPlaying
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NowPlayingScreen(audioHandler: audioHandler),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reproducir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playRadio(BuildContext context) async {
    try {
      await audioHandler.playRadio(
        title: 'Radio ZyloFM',
        streamUrl: _radioStreamUrl,
        coverUrl: _radioCoverUrl,
      );
      
      // Navegar a NowPlaying
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NowPlayingScreen(audioHandler: audioHandler),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reproducir radio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

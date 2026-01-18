/// Home Screen - Pantalla principal de ZyloFM
/// Muestra la lista de mixes y acceso a radio en vivo

import 'package:flutter/material.dart';
import '../audio/zylo_audio_handler.dart';
import '../widgets/mini_player.dart';
import 'now_playing_screen.dart';

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
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'ZyloFM',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Botón Radio en Vivo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildRadioButton(context),
                ),
              ),

              // Título de sección
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'Mixes Destacados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Lista de mixes
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mix = _mockMixes[index];
                    return _buildMixTile(context, mix);
                  },
                  childCount: _mockMixes.length,
                ),
              ),

              // Espacio para el MiniPlayer
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
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

  Widget _buildRadioButton(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _playRadio(context),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade700,
                Colors.red.shade900,
              ],
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              
              // Icono animado de radio
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.radio,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'EN VIVO',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Radio ZyloFM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Música las 24 horas',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Icon(
                Icons.play_circle_filled,
                size: 48,
                color: Colors.white,
              ),
              
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMixTile(BuildContext context, MixItem mix) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _playMix(context, mix),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Cover art
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: mix.coverUrl != null
                        ? Image.network(
                            mix.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildMixPlaceholder(),
                          )
                        : _buildMixPlaceholder(),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Info del mix
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mix.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mix.djName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mix.formattedDuration,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Botón play
                IconButton(
                  icon: Icon(
                    Icons.play_circle_outline,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _playMix(context, mix),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMixPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade600,
            Colors.deepPurple.shade900,
          ],
        ),
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

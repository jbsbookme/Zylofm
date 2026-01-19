// Home Screen - Pantalla principal de ZyloFM
// Muestra la lista de mixes y acceso a radio en vivo

import 'package:flutter/material.dart';
import '../audio/zylo_audio_handler.dart';
import '../content/admin_content_models.dart';
import '../content/admin_content_repository.dart';
import '../widgets/mini_player.dart';
import '../widgets/zylo_backdrop.dart';
import 'now_playing_screen.dart';
import '../theme/zylo_theme.dart';

class HomeScreen extends StatefulWidget {
  final ZyloAudioHandler audioHandler;

  const HomeScreen({super.key, required this.audioHandler});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<AdminContent> _contentFuture;

  ZyloAudioHandler get audioHandler => widget.audioHandler;

  @override
  void initState() {
    super.initState();

    const remoteUrl = String.fromEnvironment('ZyloContentUrl');
    _contentFuture = AdminContentRepository(
      remoteUrl: remoteUrl.isEmpty ? null : remoteUrl,
    ).load();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return FutureBuilder<AdminContent>(
      future: _contentFuture,
      builder: (context, snapshot) {
        final content = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;

        final featuredMixes = content?.featuredMixes ?? const <AdminMix>[];
        final allDjs = content?.djs ?? const <AdminDj>[];
        final featuredDjIds = content?.highlights.featuredDjIds ?? const <String>[];
        final djs = featuredDjIds.isNotEmpty
            ? allDjs.where((d) => featuredDjIds.contains(d.id)).toList(growable: false)
            : allDjs;

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

                  if (snapshot.hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _buildContentErrorBanner(),
                      ),
                    ),

                  // Card grande de Radio ZyloFM (Live)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      child: content == null
                          ? _buildLiveHeroCardLoading(context)
                          : _buildLiveHeroCard(context, content.radio),
                    ),
                  ),

                  // Featured Mixes horizontal
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _buildSectionHeader(context, title: 'Mixes Destacados'),
                    ),
                  ),
                  if (featuredMixes.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: _buildEmptyState(
                          loading: loading,
                          text: 'No hay mixes configurados.',
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 210,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final mix = featuredMixes[index];
                            return _buildFeaturedMixCard(context, mix);
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: featuredMixes.length,
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

                  if (djs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _buildEmptyState(
                          loading: loading,
                          text: 'No hay DJs configurados.',
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final dj = djs[index];
                          final mix = content?.mixForDj(dj.id);
                          if (mix == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _buildDjRow(context, dj: dj, mix: mix),
                          );
                        },
                        childCount: djs.length,
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
      },
    );
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

  Widget _buildLiveHeroCardLoading(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          gradient: ZyloFx.neonSheen(opacity: 1),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveHeroCard(BuildContext context, AdminRadio radio) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: radio.streamUrl.trim().isEmpty ? null : () => _playRadio(context, radio),
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
                  child: (radio.coverUrl != null && radio.coverUrl!.trim().isNotEmpty)
                      ? Image.network(
                          radio.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
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
                                Text(
                                  radio.badgeText,
                                  style: const TextStyle(
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
                            radio.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            radio.tagline,
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

  Widget _buildFeaturedMixCard(BuildContext context, AdminMix mix) {
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
                    Text(
                      mix.blurb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                    ),
                    const SizedBox(height: 6),
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

  Widget _buildDjRow(BuildContext context, {required AdminDj dj, required AdminMix mix}) {
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
                    dj.name.isNotEmpty ? dj.name.trim().substring(0, 1).toUpperCase() : 'D',
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
                      dj.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dj.blurb.isNotEmpty ? dj.blurb : 'En cabina ahora.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mix.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
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

  Future<void> _playMix(BuildContext context, AdminMix mix) async {
    if (mix.hlsUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este mix no tiene URL configurada.'),
        ),
      );
      return;
    }

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

  Future<void> _playRadio(BuildContext context, AdminRadio radio) async {
    if (radio.streamUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La radio no tiene streamUrl configurado.'),
        ),
      );
      return;
    }

    try {
      await audioHandler.playRadio(
        title: radio.title,
        streamUrl: radio.streamUrl,
        coverUrl: radio.coverUrl,
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

  Widget _buildContentErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D4D).withAlphaF(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF4D4D).withAlphaF(0.30)),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Color(0xFFFF4D4D), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No se pudo cargar contenido admin (endpoint/asset).',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool loading, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: Row(
        children: [
          if (loading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

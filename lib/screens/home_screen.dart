// Home Screen - Pantalla principal de ZyloFM
// Muestra la lista de mixes y acceso a radio en vivo

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/zylo_api.dart';
import '../api/zylo_api_config.dart';
import '../audio/zylo_audio_handler.dart';
import '../content/admin_content_models.dart';
import '../content/backend_content_repository.dart';
import '../services/voice_assistant_service.dart';
import '../ui/assistant/assistant_input.dart';
import '../widgets/mini_player.dart';
import '../widgets/zylo_backdrop.dart';
import 'dj_profile_screen.dart';
import 'dj_registration_screen.dart';
import 'admin_panel_screen.dart';
import 'now_playing_screen.dart';
import '../theme/zylo_theme.dart';

class HomeScreen extends StatefulWidget {
  final ZyloAudioHandler audioHandler;

  const HomeScreen({super.key, required this.audioHandler});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<AdminContent> _contentFuture;
  late Future<List<ApiAssistantLibraryItem>> _assistantLibraryFuture;
  Future<bool>? _radioOnlineFuture;
  String? _radioUrlForProbe;
  final VoiceAssistantService _voiceAssistantService = VoiceAssistantService();
  bool _voiceBusy = false;

  ZyloAudioHandler get audioHandler => widget.audioHandler;

  @override
  void initState() {
    super.initState();
    _reloadContent();
  }

  void _reloadContent() {
    setState(() {
      _contentFuture = const BackendContentRepository(baseUrl: zyloApiBaseUrl).load();
      _assistantLibraryFuture = ZyloApi(baseUrl: zyloApiBaseUrl).listAssistantLibraryPublic().catchError((_) => const <ApiAssistantLibraryItem>[]);
      _radioOnlineFuture = null;
      _radioUrlForProbe = null;
    });
  }

  (String? artist, String? genre) _extractMetaFromKeywords(List<String> keywords) {
    String? artist;
    String? genre;
    for (final k in keywords) {
      final v = k.trim();
      final lc = v.toLowerCase();
      if (artist == null && lc.startsWith('artist:')) {
        final value = v.substring('artist:'.length).trim();
        if (value.isNotEmpty) artist = value;
      }
      if (genre == null && lc.startsWith('genre:')) {
        final value = v.substring('genre:'.length).trim();
        if (value.isNotEmpty) genre = value;
      }
      if (artist != null && genre != null) break;
    }
    return (artist, genre);
  }

  Future<bool> _probeRadioOnline(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;

    final client = http.Client();
    try {
      // Prefer HEAD to avoid downloading an endless stream.
      final headReq = http.Request('HEAD', uri);
      final headResp = await client.send(headReq).timeout(const Duration(seconds: 3));
      if (headResp.statusCode >= 200 && headResp.statusCode < 400) {
        return true;
      }
    } catch (_) {
      // Some streaming servers reject HEAD; fall back to a tiny ranged GET.
    }

    try {
      final getReq = http.Request('GET', uri);
      getReq.headers['Range'] = 'bytes=0-0';
      final getResp = await client.send(getReq).timeout(const Duration(seconds: 3));
      await getResp.stream.drain();
      return getResp.statusCode >= 200 && getResp.statusCode < 400;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  void _openDjProfile(BuildContext context, AdminDj dj) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DJProfileScreen(
          audioHandler: audioHandler,
          djId: dj.id,
        ),
      ),
    );
  }

  Future<void> _handleVoiceAssistant() async {
    if (_voiceBusy) return;
    setState(() => _voiceBusy = true);

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escuchando...')),
      );

      final query = await _voiceAssistantService.listenOnce();
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (query == null || query.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se detectó voz. Intenta de nuevo.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buscando: "$query"')),
      );

      final audioUrl = await const BackendContentRepository(baseUrl: zyloApiBaseUrl).assistantPlay(query);
      if (!mounted) return;

      if (audioUrl == null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No encontré un audio para esa frase.')),
        );
        return;
      }

      await audioHandler.playFromUrl(audioUrl, title: query, artist: 'Assistant');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de voz: $e')),
      );
    } finally {
      if (mounted) setState(() => _voiceBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return FutureBuilder<AdminContent>(
      future: _contentFuture,
      builder: (context, snapshot) {
        final content = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;

        final featuredMixesAll = content?.featuredMixes ?? const <AdminMix>[];
        final featuredMixes = featuredMixesAll.length > 7
            ? featuredMixesAll.take(7).toList(growable: false)
            : featuredMixesAll;

        final newSets = content == null
            ? const <AdminMix>[]
            : content.mixes.where((m) => !m.featured).toList(growable: false);
        final allDjs = content?.djs ?? const <AdminDj>[];
        final featuredDjIds = content?.highlights.featuredDjIds ?? const <String>[];
        final djs = featuredDjIds.isNotEmpty
            ? allDjs.where((d) => featuredDjIds.contains(d.id)).toList(growable: false)
            : allDjs;

        if (content != null && content.radio.streamUrl.trim().isNotEmpty) {
          if (_radioUrlForProbe != content.radio.streamUrl) {
            _radioUrlForProbe = content.radio.streamUrl;
            _radioOnlineFuture = _probeRadioOnline(content.radio.streamUrl);
          }
        }

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

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: AssistantInput(audioHandler: audioHandler),
                    ),
                  ),

                  if (snapshot.hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _buildContentErrorBanner(onRetry: _reloadContent),
                      ),
                    ),

                  // Card grande de Radio ZyloFM (Live)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      child: content == null
                          ? _buildLiveHeroCardLoading(context)
                          : _buildLiveHeroCard(context, content.radio, onlineFuture: _radioOnlineFuture),
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
                          icon: Icons.library_music_outlined,
                          text: 'Aún no hay mixes publicados.',
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

                  // Biblioteca (Assistant Library) - canciones sueltas subidas por admin
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _buildSectionHeader(context, title: 'Biblioteca'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<ApiAssistantLibraryItem>>(
                      future: _assistantLibraryFuture,
                      builder: (context, libSnap) {
                        if (libSnap.connectionState != ConnectionState.done) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: _buildEmptyState(
                              loading: true,
                              icon: Icons.library_music_outlined,
                              text: 'Cargando biblioteca…',
                            ),
                          );
                        }

                        final tracks = libSnap.data ?? const <ApiAssistantLibraryItem>[];
                        if (tracks.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: _buildEmptyState(
                              loading: false,
                              icon: Icons.library_music_outlined,
                              text: 'Biblioteca vacía (se llena desde el Admin Dashboard).',
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final t = tracks[index];
                            final meta = _extractMetaFromKeywords(t.keywords);
                            final subtitleParts = <String>[];
                            if (meta.$1 != null && meta.$1!.trim().isNotEmpty) subtitleParts.add(meta.$1!.trim());
                            if (meta.$2 != null && meta.$2!.trim().isNotEmpty) subtitleParts.add(meta.$2!.trim());

                            return Container(
                              decoration: BoxDecoration(
                                color: ZyloColors.panel.withAlphaF(0.55),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF1C1C28)),
                              ),
                              child: ListTile(
                                title: Text(
                                  t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                subtitle: Text(
                                  subtitleParts.isEmpty ? '—' : subtitleParts.join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.play_circle_fill_rounded),
                                  onPressed: () async {
                                    if (t.audioUrl.trim().isEmpty) return;
                                    await audioHandler.playFromUrl(
                                      t.audioUrl,
                                      title: t.title,
                                      artist: meta.$1 ?? 'ZyloFM',
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: tracks.length,
                        );
                      },
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
                          icon: Icons.person_outline,
                          text: 'Aún no hay DJs en cabina.',
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
                            child: _buildDjCard(context, dj: dj, mix: mix),
                          );
                        },
                        childCount: djs.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // Nuevos Sets (opcional)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _buildSectionHeader(context, title: 'Nuevos Sets'),
                    ),
                  ),
                  if (newSets.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _buildComingSoonSets(),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final mix = newSets[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _buildNewSetRow(context, mix),
                          );
                        },
                        childCount: newSets.length > 6 ? 6 : newSets.length,
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
        const SizedBox(width: 10),
        InkWell(
          onTap: _voiceBusy ? null : _handleVoiceAssistant,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ZyloColors.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1C1C28)),
            ),
            child: _voiceBusy
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mic_rounded, color: Colors.white70, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DjRegistrationScreen()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ZyloColors.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1C1C28)),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white70, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ZyloColors.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1C1C28)),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white70, size: 20),
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

  Widget _buildLiveHeroCard(
    BuildContext context,
    AdminRadio radio, {
    required Future<bool>? onlineFuture,
  }) {
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
                          _buildRadioBadge(onlineFuture: onlineFuture, enabled: radio.streamUrl.trim().isNotEmpty),
                          const SizedBox(height: 12),
                          Text(
                            '${radio.title} — ${radio.tagline}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Toca para escuchar ahora',
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
                        boxShadow: [
                          ...ZyloFx.glow(ZyloColors.zyloYellow, blur: 26, spread: 0.6),
                          ...ZyloFx.glow(ZyloColors.zyloYellow, blur: 14),
                        ],
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

  Widget _buildRadioBadge({required Future<bool>? onlineFuture, required bool enabled}) {
    if (!enabled) {
      return _badgePill(
        label: 'OFFLINE',
        dotColor: ZyloColors.zyloYellow.withAlphaF(0.55),
        borderColor: ZyloColors.zyloYellow.withAlphaF(0.20),
        fillColor: ZyloColors.zyloYellow.withAlphaF(0.08),
        textColor: Colors.white70,
        shadowColor: ZyloColors.zyloYellow.withAlphaF(0.10),
      );
    }

    if (onlineFuture == null) {
      return _badgePill(
        label: 'LIVE',
        dotColor: ZyloColors.zyloYellow,
        borderColor: ZyloColors.zyloYellow.withAlphaF(0.45),
        fillColor: ZyloColors.zyloYellow.withAlphaF(0.10),
        textColor: Colors.white,
        shadowColor: ZyloColors.zyloYellow.withAlphaF(0.18),
      );
    }

    return FutureBuilder<bool>(
      future: onlineFuture,
      builder: (context, snapshot) {
        final online = snapshot.data;
        final showOffline = online == false;

        return _badgePill(
          label: showOffline ? 'OFFLINE' : 'LIVE',
          dotColor: showOffline ? ZyloColors.zyloYellow.withAlphaF(0.55) : ZyloColors.zyloYellow,
          borderColor: showOffline
              ? ZyloColors.zyloYellow.withAlphaF(0.20)
              : ZyloColors.zyloYellow.withAlphaF(0.55),
          fillColor: showOffline
              ? ZyloColors.zyloYellow.withAlphaF(0.08)
              : ZyloColors.zyloYellow.withAlphaF(0.12),
          textColor: showOffline ? Colors.white70 : Colors.white,
          shadowColor: showOffline
              ? ZyloColors.zyloYellow.withAlphaF(0.10)
              : ZyloColors.zyloYellow.withAlphaF(0.22),
        );
      },
    );
  }

  Widget _badgePill({
    required String label,
    required Color dotColor,
    required Color borderColor,
    required Color fillColor,
    required Color textColor,
    required Color shadowColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withAlphaF(0.24),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black.withAlphaF(0.55),
                              Colors.black.withAlphaF(0.25),
                              Colors.black.withAlphaF(0.70),
                            ],
                          ),
                        ),
                      ),
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
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: _buildCoverText(mix.djName, mix.title),
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

  Widget _buildDjCard(BuildContext context, {required AdminDj dj, required AdminMix mix}) {
    const djRed = Color(0xFFFF3B30);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openDjProfile(context, dj),
                child: _buildDjAvatar(dj),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openDjProfile(context, dj),
                      child: Text(
                        dj.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dj.blurb.isNotEmpty ? dj.blurb : 'En cabina ahora.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mix.title,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ZyloColors.panel2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF252535)),
                          ),
                          child: Text(
                            mix.formattedDuration,
                            style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: djRed.withAlphaF(0.18),
                  border: Border.all(color: djRed.withAlphaF(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: djRed.withAlphaF(0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
                  onPressed: () => _playMix(context, mix),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDjAvatar(AdminDj dj) {
    const djRed = Color(0xFFFF3B30);
    final fallbackLetter = dj.name.isNotEmpty ? dj.name.trim().substring(0, 1).toUpperCase() : 'D';
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyloColors.panel2,
        border: Border.all(color: djRed.withAlphaF(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: djRed.withAlphaF(0.14),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: dj.avatarUrl != null && dj.avatarUrl!.trim().isNotEmpty
            ? Image.network(
                dj.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _djAvatarFallback(fallbackLetter),
              )
            : _djAvatarFallback(fallbackLetter),
      ),
    );
  }

  Widget _djAvatarFallback(String letter) {
    const djRed = Color(0xFFFF3B30);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            djRed.withAlphaF(0.14),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCoverText(String djName, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlphaF(0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZyloColors.zyloYellow.withAlphaF(0.25)),
        boxShadow: [
          BoxShadow(
            color: ZyloColors.zyloYellow.withAlphaF(0.10),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            djName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: ZyloColors.zyloYellow,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonSets() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_bottom, color: Colors.white60, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Próximamente más sets.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewSetRow(BuildContext context, AdminMix mix) {
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
                  color: ZyloColors.panel2,
                  border: Border.all(color: ZyloColors.zyloYellow.withAlphaF(0.20)),
                ),
                child: const Icon(Icons.music_note, color: Colors.white60, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mix.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mix.djName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: Colors.white38),
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

  Widget _buildContentErrorBanner({required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D4D).withAlphaF(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF4D4D).withAlphaF(0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF4D4D), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No se pudo cargar el contenido. Reintentar',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: ZyloColors.zyloYellow),
            child: const Text('Reintentar'),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool loading, required IconData icon, required String text}) {
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
          ] else ...[
            Icon(icon, color: Colors.white60, size: 18),
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

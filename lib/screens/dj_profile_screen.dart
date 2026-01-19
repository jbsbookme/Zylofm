import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio/zylo_audio_handler.dart';
import '../content/admin_content_models.dart';
import '../content/admin_content_repository.dart';
import '../theme/zylo_theme.dart';
import 'now_playing_screen.dart';

class DJProfileScreen extends StatefulWidget {
  final ZyloAudioHandler audioHandler;
  final String djId;

  const DJProfileScreen({
    super.key,
    required this.audioHandler,
    required this.djId,
  });

  @override
  State<DJProfileScreen> createState() => _DJProfileScreenState();
}

class _DJProfileScreenState extends State<DJProfileScreen> with SingleTickerProviderStateMixin {
  late final Future<AdminContent> _contentFuture;
  late final AnimationController _enterController;

  double _scrollOffset = 0;
  bool _filterInitialized = false;
  _SetsFilter _setsFilter = _SetsFilter.all;

  static const Color _djRed = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();

    _contentFuture = const AdminContentRepository().load();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Perfil DJ'),
        centerTitle: true,
      ),
      body: FutureBuilder<AdminContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildSkeletonPage(context);
          }

          final content = snapshot.data;
          if (content == null) {
            return _buildErrorState(context);
          }

          final dj = content.djs.firstWhere(
            (d) => d.id == widget.djId,
            orElse: () => const AdminDj(id: 'dj', name: 'DJ', blurb: ''),
          );

          final mixesAll = content.mixes.where((m) => m.djId == dj.id).toList(growable: false);

          final mixById = {for (final m in mixesAll) m.id: m};
          List<AdminMix> resolveIds(List<String> ids) {
            final out = <AdminMix>[];
            for (final id in ids) {
              final m = mixById[id];
              if (m != null) out.add(m);
            }
            return out;
          }

          final latestSets = resolveIds(dj.latestMixIds);
          final popularSets = resolveIds(dj.popularMixIds);

          if (!_filterInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _filterInitialized = true;
                if (latestSets.isNotEmpty) {
                  _setsFilter = _SetsFilter.latest;
                } else if (popularSets.isNotEmpty) {
                  _setsFilter = _SetsFilter.popular;
                } else {
                  _setsFilter = _SetsFilter.all;
                }
              });
            });
          }

          final hasCurated = latestSets.isNotEmpty || popularSets.isNotEmpty;

          List<AdminMix> shown;
          String title;
          switch (_setsFilter) {
            case _SetsFilter.latest:
              shown = latestSets.isNotEmpty ? latestSets : mixesAll;
              title = 'Latest Sets';
              break;
            case _SetsFilter.popular:
              shown = popularSets.isNotEmpty ? popularSets : mixesAll;
              title = 'Popular Sets';
              break;
            case _SetsFilter.all:
              shown = mixesAll;
              title = 'Sets';
              break;
          }

          return FadeTransition(
            opacity: CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
                CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.axis != Axis.vertical) return false;
                  final next = n.metrics.pixels;
                  if ((next - _scrollOffset).abs() >= 1.0 && mounted) {
                    setState(() => _scrollOffset = next);
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: Offset(0, (_scrollOffset * 0.10).clamp(0, 22)),
                        child: _buildHeader(context, dj),
                      ),
                      const SizedBox(height: 14),
                      _buildPrimaryActions(context, dj, mixesAll),
                      const SizedBox(height: 14),
                      _buildSectionDivider(),
                      const SizedBox(height: 14),
                      if (mixesAll.isEmpty) ...[
                        _buildSectionTitle('Sets'),
                        const SizedBox(height: 10),
                        _buildEmptySets(),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildSectionTitle(title)),
                            if (hasCurated) _buildSetsFilterChips(latestSets.isNotEmpty, popularSets.isNotEmpty),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildMixList(context, shown),
                      ],
                      const SizedBox(height: 14),
                      _buildSectionDivider(),
                      const SizedBox(height: 14),
                      _buildSectionTitle('Redes'),
                      const SizedBox(height: 10),
                      _buildSocialRow(context, dj),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialRow(BuildContext context, AdminDj dj) {
    return Row(
      children: [
        _socialIcon(
          context,
          label: 'Instagram',
          icon: Icons.camera_alt_rounded,
          url: dj.instagramUrl,
        ),
        const SizedBox(width: 10),
        _socialIcon(
          context,
          label: 'TikTok',
          icon: Icons.music_video_rounded,
          url: dj.tiktokUrl,
        ),
        const SizedBox(width: 10),
        _socialIcon(
          context,
          label: 'YouTube',
          icon: Icons.play_circle_fill_rounded,
          url: dj.youtubeUrl,
        ),
      ],
    );
  }

  Widget _socialIcon(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String? url,
  }) {
    final trimmed = url?.trim() ?? '';
    final enabled = trimmed.isNotEmpty;

    final fg = enabled ? Colors.white70 : Colors.white24;
    final border = enabled ? _djRed.withAlphaF(0.26) : const Color(0xFF1C1C28);

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: enabled ? () => _openExternalUrl(context, trimmed) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ZyloColors.panel.withAlphaF(0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }

  Uri? _parseExternalUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final hasScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final normalized = hasScheme ? trimmed : 'https://$trimmed';
    return Uri.tryParse(normalized);
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = _parseExternalUri(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link inválido.')),
      );
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el link.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el link: $e')),
      );
    }
  }

  Widget _buildSkeletonPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonHeader(),
          const SizedBox(height: 14),
          _buildSkeletonActions(),
          const SizedBox(height: 18),
          _buildSectionTitle('Sets'),
          const SizedBox(height: 10),
          _buildSkeletonList(),
        ],
      ),
    );
  }

  Widget _skeletonBox({
    required double width,
    required double height,
    BorderRadius? radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withAlphaF(0.06),
        borderRadius: radius ?? BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlphaF(0.06)),
      ),
    );
  }

  Widget _buildSkeletonHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _djRed.withAlphaF(0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlphaF(0.06),
              border: Border.all(color: _djRed.withAlphaF(0.22)),
            ),
          ),
          const SizedBox(height: 12),
          _skeletonBox(width: 170, height: 18, radius: BorderRadius.circular(10)),
          const SizedBox(height: 10),
          _skeletonBox(width: 240, height: 12, radius: BorderRadius.circular(10)),
          const SizedBox(height: 8),
          _skeletonBox(width: 220, height: 12, radius: BorderRadius.circular(10)),
        ],
      ),
    );
  }

  Widget _buildSkeletonActions() {
    return Row(
      children: [
        Expanded(
          child: _skeletonBox(width: double.infinity, height: 50, radius: BorderRadius.circular(16)),
        ),
        const SizedBox(width: 10),
        _skeletonBox(width: 46, height: 46, radius: BorderRadius.circular(16)),
        const SizedBox(width: 10),
        _skeletonBox(width: 46, height: 46, radius: BorderRadius.circular(16)),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        return Column(
          children: List.generate(4, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == 3 ? 0 : spacing),
              child: _skeletonBox(
                width: double.infinity,
                height: 78,
                radius: BorderRadius.circular(18),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: ZyloColors.panel.withAlphaF(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1C1C28)),
          ),
          child: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white60, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No se pudo cargar el contenido del DJ.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminDj dj) {
    final bio = dj.blurb.trim();
    final location = dj.location?.trim() ?? '';
    final genres = dj.genres.where((g) => g.trim().isNotEmpty).toList(growable: false);
    final metaPieces = <String>[];
    if (location.isNotEmpty) metaPieces.add(location);
    if (genres.isNotEmpty) metaPieces.add(genres.take(3).join(' • '));
    final metaLine = metaPieces.join('  •  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _djRed.withAlphaF(0.22)),
        boxShadow: [
          BoxShadow(
            color: _djRed.withAlphaF(0.10),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(dj),
          const SizedBox(height: 12),
          Text(
            dj.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (metaLine.isNotEmpty) ...[
            Text(
              metaLine,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ZyloColors.zyloYellow.withAlphaF(0.82),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          if (bio.isNotEmpty)
            Text(
              bio,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            )
          else
            Text(
              'Zylo Resident DJ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AdminDj dj) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyloColors.panel2,
        border: Border.all(color: _djRed.withAlphaF(0.46), width: 1),
        boxShadow: [
          BoxShadow(
            color: _djRed.withAlphaF(0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipOval(
        child: dj.avatarUrl != null && dj.avatarUrl!.trim().isNotEmpty
            ? Image.network(
                dj.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(dj),
              )
            : _avatarFallback(dj),
      ),
    );
  }

  Widget _avatarFallback(AdminDj dj) {
    final letter = dj.name.isNotEmpty ? dj.name.trim().substring(0, 1).toUpperCase() : 'D';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            _djRed.withAlphaF(0.12),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context, AdminDj dj, List<AdminMix> mixes) {
    final canPlay = mixes.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canPlay ? () => _playMix(context, mixes.first) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _djRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: const Text(
              'PLAY DJ SET',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _iconPill(
          icon: Icons.favorite_border_rounded,
          tooltip: 'Me gusta',
          onTap: null,
        ),
        const SizedBox(width: 10),
        _iconPill(
          icon: Icons.ios_share_rounded,
          tooltip: 'Compartir',
          onTap: null,
        ),
      ],
    );
  }

  Widget _iconPill({required IconData icon, required String tooltip, required VoidCallback? onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: ZyloColors.panel.withAlphaF(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1C1C28)),
          ),
          child: Icon(icon, color: onTap == null ? Colors.white24 : Colors.white70, size: 20),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptySets() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: const Row(
        children: [
          Icon(Icons.library_music_outlined, color: Colors.white60, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este DJ aún no tiene sets publicados.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixList(BuildContext context, List<AdminMix> mixes) {
    return Column(
      children: [
        for (int i = 0; i < mixes.length; i++) ...[
          _buildMixListCard(context, mixes[i]),
          if (i != mixes.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildMixListCard(BuildContext context, AdminMix mix) {
    return _PressScale(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _playMix(context, mix),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: ZyloColors.panel.withAlphaF(0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1C1C28)),
        ),
        child: Row(
          children: [
            _buildMixCover(mix),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mix.title,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlphaF(0.40),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _djRed.withAlphaF(0.22)),
                        ),
                        child: Text(
                          mix.formattedDuration,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mix.djName,
                          style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _TapScale(
              onTap: () => _playMix(context, mix),
              child: _buildPlayButton(onPressed: () => _playMix(context, mix)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMixCover(AdminMix mix) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ZyloColors.panel2,
        border: Border.all(color: Colors.white.withAlphaF(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: mix.coverUrl != null && mix.coverUrl!.trim().isNotEmpty
            ? Image.network(
                mix.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildCoverFallback(),
              )
            : _buildCoverFallback(),
      ),
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: ZyloColors.panel2,
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white38, size: 24),
      ),
    );
  }

  Widget _buildPlayButton({required VoidCallback onPressed}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _djRed.withAlphaF(0.20),
        border: Border.all(color: _djRed.withAlphaF(0.40)),
        boxShadow: [
          BoxShadow(
            color: _djRed.withAlphaF(0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withAlphaF(0.00),
            ZyloColors.zyloYellow.withAlphaF(0.16),
            Colors.white.withAlphaF(0.00),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsFilterChips(bool hasLatest, bool hasPopular) {
    ChoiceChip chip(String label, _SetsFilter value, {required bool enabled}) {
      final selected = _setsFilter == value;
      final fg = selected ? ZyloColors.zyloYellow : Colors.white60;
      final border = selected ? ZyloColors.zyloYellow.withAlphaF(0.35) : const Color(0xFF1C1C28);

      return ChoiceChip(
        label: Text(label, style: TextStyle(color: enabled ? fg : Colors.white24, fontWeight: FontWeight.w800)),
        selected: selected,
        onSelected: enabled
            ? (v) {
                if (!v) return;
                setState(() => _setsFilter = value);
              }
            : null,
        backgroundColor: ZyloColors.panel.withAlphaF(0.70),
        selectedColor: ZyloColors.panel.withAlphaF(0.85),
        side: BorderSide(color: enabled ? border : const Color(0xFF1C1C28)),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('Latest', _SetsFilter.latest, enabled: hasLatest),
        const SizedBox(width: 8),
        chip('Popular', _SetsFilter.popular, enabled: hasPopular),
        const SizedBox(width: 8),
        chip('All', _SetsFilter.all, enabled: true),
      ],
    );
  }

  Future<void> _playMix(BuildContext context, AdminMix mix) async {
    if (mix.hlsUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este mix no tiene URL configurada.')),
      );
      return;
    }

    try {
      await widget.audioHandler.playHlsMix(
        mixId: mix.id,
        title: mix.title,
        djName: mix.djName,
        hlsUrl: mix.hlsUrl,
        coverUrl: mix.coverUrl,
        durationSec: mix.durationSec,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NowPlayingScreen(audioHandler: widget.audioHandler),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reproducir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

enum _SetsFilter { latest, popular, all }

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const _PressScale({
    required this.child,
    required this.borderRadius,
    this.onTap,
  });

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? 0.98
        : (_hovered ? 0.995 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius,
            overlayColor: WidgetStateProperty.all(Colors.white.withAlphaF(0.06)),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

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

          final mixes = content.mixes.where((m) => m.djId == dj.id).toList(growable: false);

          return FadeTransition(
            opacity: CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
                CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, dj),
                    const SizedBox(height: 14),
                    _buildPrimaryActions(context, dj, mixes),
                    const SizedBox(height: 18),
                    _buildSectionTitle('Sets'),
                    const SizedBox(height: 10),
                    if (mixes.isEmpty)
                      _buildEmptySets()
                    else
                      _buildMixGallery(context, mixes),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
          _buildSkeletonGrid(),
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

  Widget _buildSkeletonGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isGrid = w >= 430;
        final cols = isGrid ? 2 : 1;
        const spacing = 12.0;
        final tileW = (w - (spacing * (cols - 1))) / cols;
        final tileH = isGrid ? (tileW * 0.92) : 96.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(4, (i) {
            return _skeletonBox(
              width: tileW,
              height: tileH,
              radius: BorderRadius.circular(18),
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
          tooltip: 'Follow',
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _iconPill(
          icon: Icons.ios_share_rounded,
          tooltip: 'Share',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _iconPill({required IconData icon, required String tooltip, required VoidCallback onTap}) {
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
          child: Icon(icon, color: Colors.white70, size: 20),
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

  Widget _buildMixGallery(BuildContext context, List<AdminMix> mixes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isGrid = w >= 430;
        final cols = isGrid ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isGrid ? 1.10 : 3.15,
          ),
          itemCount: mixes.length,
          itemBuilder: (context, index) {
            final mix = mixes[index];
            return _buildMixCard(context, mix, dense: !isGrid);
          },
        );
      },
    );
  }

  Widget _buildMixCard(BuildContext context, AdminMix mix, {required bool dense}) {
    final radius = BorderRadius.circular(18);

    return InkWell(
      onTap: () => _playMix(context, mix),
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: ZyloColors.panel.withAlphaF(0.82),
          borderRadius: radius,
          border: Border.all(color: const Color(0xFF1C1C28)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: mix.coverUrl != null && mix.coverUrl!.trim().isNotEmpty
                    ? Image.network(
                        mix.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildCoverFallback(),
                      )
                    : _buildCoverFallback(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlphaF(dense ? 0.35 : 0.15),
                      Colors.black.withAlphaF(0.75),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _buildPlayPuck(onPressed: () => _playMix(context, mix)),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mix.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: dense ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlphaF(0.55),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _djRed.withAlphaF(0.24)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: ZyloColors.panel2,
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white38, size: 28),
      ),
    );
  }

  Widget _buildPlayPuck({required VoidCallback onPressed}) {
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

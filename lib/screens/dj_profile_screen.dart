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

    const remoteUrl = String.fromEnvironment('ZyloContentUrl');
    _contentFuture = AdminContentRepository(
      remoteUrl: remoteUrl.isEmpty ? null : remoteUrl,
    ).load();

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
        title: const Text('DJ Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<AdminContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
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
                    const SizedBox(height: 16),
                    _buildPrimaryActions(context, dj, mixes),
                    const SizedBox(height: 20),
                    _buildSectionTitle('DJ Mixes'),
                    const SizedBox(height: 10),
                    if (mixes.isEmpty)
                      _buildInlineEmpty('Este DJ no tiene mixes publicados aún.')
                    else
                      ...mixes.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildMixRow(context, m),
                          )),
                    const SizedBox(height: 18),
                    _buildSectionTitle('Bio'),
                    const SizedBox(height: 10),
                    _buildBioCard(dj),
                    const SizedBox(height: 18),
                    _buildSectionTitle('Redes'),
                    const SizedBox(height: 10),
                    _buildSocialRow(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
              Icon(Icons.wifi_off_rounded, color: Colors.white60, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No se pudo cargar el perfil del DJ.',
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAvatar(dj),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dj.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Zylo Resident DJ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(AdminDj dj) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyloColors.panel2,
        border: Border.all(color: _djRed.withAlphaF(0.42), width: 1),
        boxShadow: [
          BoxShadow(
            color: _djRed.withAlphaF(0.18),
            blurRadius: 20,
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

  Widget _buildMixRow(BuildContext context, AdminMix mix) {
    return Container(
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
                const SizedBox(height: 4),
                Text(
                  mix.formattedDuration,
                  style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _djRed.withAlphaF(0.18),
              border: Border.all(color: _djRed.withAlphaF(0.35)),
              boxShadow: [
                BoxShadow(
                  color: _djRed.withAlphaF(0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
              onPressed: () => _playMix(context, mix),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixCover(AdminMix mix) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: ZyloColors.panel2,
        border: Border.all(color: Colors.white.withAlphaF(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: mix.coverUrl != null && mix.coverUrl!.trim().isNotEmpty
            ? Image.network(
                mix.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white38, size: 22),
              )
            : const Icon(Icons.music_note, color: Colors.white38, size: 22),
      ),
    );
  }

  Widget _buildBioCard(AdminDj dj) {
    final bio = dj.blurb.trim().isEmpty ? 'Bio no disponible.' : dj.blurb.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _djRed.withAlphaF(0.22)),
        boxShadow: [
          BoxShadow(
            color: _djRed.withAlphaF(0.10),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Text(
        bio,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white70, height: 1.3),
      ),
    );
  }

  Widget _buildInlineEmpty(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white60, size: 18),
          const SizedBox(width: 10),
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

  Widget _buildSocialRow() {
    return Row(
      children: [
        _socialIcon(Icons.camera_alt_rounded, 'Instagram'),
        const SizedBox(width: 10),
        _socialIcon(Icons.cloud_rounded, 'SoundCloud'),
        const SizedBox(width: 10),
        _socialIcon(Icons.music_note_rounded, 'Spotify'),
      ],
    );
  }

  Widget _socialIcon(IconData icon, String label) {
    return Tooltip(
      message: label,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ZyloColors.panel.withAlphaF(0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1C1C28)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
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

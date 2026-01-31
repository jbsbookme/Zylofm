import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../api/zylo_api.dart';
import '../api/zylo_api_config.dart';
import '../theme/zylo_theme.dart';

class AdminMixReviewScreen extends StatefulWidget {
  const AdminMixReviewScreen({super.key});

  @override
  State<AdminMixReviewScreen> createState() => _AdminMixReviewScreenState();
}

class _AdminMixReviewScreenState extends State<AdminMixReviewScreen> {
  final _baseUrlController = TextEditingController(text: zyloApiBaseUrl);
  final _emailController = TextEditingController(text: 'admin@zylo.fm');
  final _passwordController = TextEditingController(text: 'admin123456');
  final _tokenController = TextEditingController();

  final AudioPlayer _player = AudioPlayer();

  bool _loading = false;
  String? _playingId;

  List<ApiMix> _pending = const [];

  ZyloApi _api() => ZyloApi(baseUrl: _baseUrlController.text.trim());

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    setState(() => _loading = true);
    final api = _api();
    try {
      final token = await api.login(email: _emailController.text.trim(), password: _passwordController.text);
      if (!mounted) return;
      setState(() => _tokenController.text = token);
      await _loadPending();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login admin OK ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login falló: $e')));
    } finally {
      api.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPending() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta token ADMIN.')));
      return;
    }

    setState(() => _loading = true);
    final api = _api();
    try {
      final list = await api.listPendingMixes(token: token);
      if (!mounted) return;
      setState(() => _pending = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo cargar pending: $e')));
    } finally {
      api.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePreview(ApiMix mix) async {
    try {
      if (_playingId == mix.id) {
        await _player.stop();
        setState(() => _playingId = null);
        return;
      }

      setState(() => _playingId = mix.id);
      await _player.setUrl(mix.audioUrl);
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _playingId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo reproducir: $e')));
    }
  }

  Future<void> _setStatus(ApiMix mix, {required bool approve}) async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() => _loading = true);
    final api = _api();
    try {
      await api.approveMix(token: token, mixId: mix.id, approve: approve);
      await _loadPending();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      api.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZyloColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Mix Review'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  _textField(label: 'Base URL', controller: _baseUrlController, hint: 'Android emulator: http://10.0.2.2:3000'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Login Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  _textField(label: 'Email', controller: _emailController, hint: 'admin@zylo.fm'),
                  const SizedBox(height: 10),
                  _textField(label: 'Password', controller: _passwordController, hint: 'admin1234', obscure: true),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _loginAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZyloColors.panel2,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.key_rounded, color: ZyloColors.zyloYellow, size: 18),
                      label: const Text('OBTENER TOKEN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _textField(label: 'Bearer Token', controller: _tokenController, hint: 'Se llena al hacer login', maxLines: 2),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _loadPending,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('CARGAR PENDIENTES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Pendientes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            if (_pending.isEmpty)
              _empty('No hay mixes pendientes.')
            else
              Column(
                children: [
                  for (final mix in _pending) ...[
                    _mixCard(mix),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _mixCard(ApiMix mix) {
    final playing = _playingId == mix.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: ZyloColors.panel2,
              border: Border.all(color: Colors.white.withAlphaF(0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: mix.coverUrl.trim().isNotEmpty
                  ? Image.network(mix.coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _coverFallback())
                  : _coverFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mix.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  mix.djName ?? mix.djId,
                  style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (mix.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    mix.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loading ? null : () => _togglePreview(mix),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZyloColors.panel2,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
                      label: Text(playing ? 'STOP' : 'PREVIEW', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _loading ? null : () => _setStatus(mix, approve: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('✅ APROBAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _loading ? null : () => _setStatus(mix, approve: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('❌ RECHAZAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() {
    return const Center(
      child: Icon(Icons.music_note_rounded, color: Colors.white38, size: 24),
    );
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: Colors.white60, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: child,
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: ZyloColors.panel.withAlphaF(0.80),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1C1C28)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1C1C28)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: ZyloColors.zyloYellow.withAlphaF(0.35)),
            ),
          ),
        ),
      ],
    );
  }
}

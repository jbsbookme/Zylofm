import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/zylo_api_config.dart';
import 'admin_mix_review_screen.dart';
import 'admin_assistant_library_screen.dart';
import '../theme/zylo_theme.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _baseUrlController = TextEditingController(text: zyloApiBaseUrl);
  final _emailController = TextEditingController(text: 'admin@zylo.fm');
  final _passwordController = TextEditingController(text: 'admin123456');
  final _tokenController = TextEditingController();

  List<dynamic> _djs = const [];

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Uri _uri(String path) {
    final base = _baseUrlController.text.trim();
    final raw = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return Uri.parse('$raw$path');
  }

  Map<String, String> _headers() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _loginAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final resp = await http
          .post(
            _uri('/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = json['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          setState(() => _tokenController.text = token);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login admin OK ✅')),
          );
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login falló (${resp.statusCode}).')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar al backend.')),
      );
    }
  }

  Future<void> _loadDjs() async {
    try {
      final resp = await http
          .get(_uri('/admin/djs'), headers: _headers())
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final list = jsonDecode(resp.body);
        setState(() => _djs = list is List ? list : const []);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error (${resp.statusCode}): requiere token ADMIN.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar DJs.')),
      );
    }
  }

  Future<void> _approveDj(String id) async {
    try {
      final resp = await http
          .post(_uri('/admin/djs/$id/approve'), headers: _headers())
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await _loadDjs();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo aprobar (${resp.statusCode}).')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red aprobando DJ.')),
      );
    }
  }

  Future<void> _blockDj(String id) async {
    try {
      final resp = await http
          .post(_uri('/admin/djs/$id/block'), headers: _headers())
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await _loadDjs();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo bloquear (${resp.statusCode}).')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red bloqueando DJ.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZyloColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Panel (temporal)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminMixReviewScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.queue_music_rounded, size: 18),
                label: const Text(
                  'REVISAR MIXES (PENDIENTES)',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminAssistantLibraryScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZyloColors.panel2,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: ZyloColors.zyloYellow),
                label: const Text(
                  'ASSISTANT LIBRARY (SUBIR AUDIO)',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backend',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  _textField(
                    label: 'Base URL',
                    controller: _baseUrlController,
                    hint: 'Android emulator: http://10.0.2.2:3010',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login Admin',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  _textField(label: 'Email', controller: _emailController, hint: 'admin@zylo.fm'),
                  const SizedBox(height: 10),
                  _textField(label: 'Password', controller: _passwordController, hint: 'admin1234', obscure: true),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loginAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZyloColors.panel2,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.key_rounded, color: ZyloColors.zyloYellow, size: 18),
                      label: const Text(
                        'OBTENER TOKEN',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    label: 'Bearer Token',
                    controller: _tokenController,
                    hint: 'Se llena al hacer login',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DJs',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadDjs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'CARGAR DJs',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_djs.isEmpty)
                    const Text(
                      'Sin datos (o falta token ADMIN).',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    )
                  else
                    Column(
                      children: [
                        for (final d in _djs) ...[
                          _djRow(d),
                          const SizedBox(height: 10),
                        ],
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

  Widget _djRow(dynamic raw) {
    final m = raw is Map<String, dynamic>
        ? raw
        : raw is Map
            ? raw.map((k, v) => MapEntry(k.toString(), v))
            : <String, dynamic>{};

    final id = (m['id'] ?? '').toString();
    final name = (m['displayName'] ?? '').toString();
    final status = (m['status'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'DJ' : name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: $id • $status',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Aprobar',
            onPressed: id.isEmpty ? null : () => _approveDj(id),
            icon: const Icon(Icons.check_circle_rounded, color: ZyloColors.zyloYellow),
          ),
          IconButton(
            tooltip: 'Bloquear',
            onPressed: id.isEmpty ? null : () => _blockDj(id),
            icon: const Icon(Icons.block_rounded, color: Color(0xFFFF3B30)),
          ),
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

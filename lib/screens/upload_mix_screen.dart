import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/zylo_api.dart';
import '../api/zylo_api_config.dart';
import '../theme/zylo_theme.dart';

class UploadMixScreen extends StatefulWidget {
  final String djName;

  const UploadMixScreen({super.key, required this.djName});

  @override
  State<UploadMixScreen> createState() => _UploadMixScreenState();
}

class _UploadMixScreenState extends State<UploadMixScreen> {
  final _baseUrlController = TextEditingController(text: zyloApiBaseUrl);
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();

  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _descController = TextEditingController();

  bool _loading = false;

  String? _djId;
  String? _djDisplayName;

  File? _audioFile;
  File? _coverFile;

  List<ApiMix> _mixes = const [];

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _titleController.dispose();
    _genreController.dispose();
    _descController.dispose();
    super.dispose();
  }

  ZyloApi _api() => ZyloApi(baseUrl: _baseUrlController.text.trim());

  Future<void> _loginDj() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email y password requeridos.')),
      );
      return;
    }

    setState(() => _loading = true);
    final api = _api();
    try {
      final token = await api.login(email: email, password: password);
      final me = await api.getDjMe(token: token);
      if (!mounted) return;
      setState(() {
        _tokenController.text = token;
        _djId = me.id;
        _djDisplayName = me.displayName;
      });
      await _reloadMyMixes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login DJ OK ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login falló: $e')),
      );
    } finally {
      api.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadMyMixes() async {
    final token = _tokenController.text.trim();
    final djId = _djId;
    if (token.isEmpty || djId == null) return;

    final api = _api();
    try {
      final list = await api.listDjMixes(djId: djId, token: token);
      if (!mounted) return;
      setState(() => _mixes = list);
    } catch (_) {
      // Silent
    } finally {
      api.close();
    }
  }

  Future<void> _pickAudio() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac'],
    );
    if (!mounted) return;
    if (res == null || res.files.isEmpty) return;
    final path = res.files.first.path;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el archivo de audio.')),
      );
      return;
    }
    setState(() => _audioFile = File(path));
  }

  Future<void> _pickCover() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (!mounted) return;
    if (res == null || res.files.isEmpty) return;
    final path = res.files.first.path;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer la portada.')),
      );
      return;
    }
    setState(() => _coverFile = File(path));
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero inicia sesión como DJ.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final genre = _genreController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un título al mix.')),
      );
      return;
    }

    if (_audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el audio (mp3/wav).')),
      );
      return;
    }

    if (_coverFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la portada (jpg/png).')),
      );
      return;
    }

    setState(() => _loading = true);
    final api = _api();
    try {
      await api.uploadMix(
        token: token,
        title: title,
        description: desc,
        genre: genre,
        isClean: true,
        audio: _audioFile!,
        cover: _coverFile!,
      );

      _titleController.clear();
      _genreController.clear();
      _descController.clear();
      setState(() {
        _audioFile = null;
        _coverFile = null;
      });

      await _reloadMyMixes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviado a revisión ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo mix: $e')),
      );
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
        title: const Text('Subir Mix'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DJ: ${_djDisplayName ?? widget.djName}',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  _textField(
                    label: 'Base URL',
                    controller: _baseUrlController,
                    hint: 'Android emulator: http://10.0.2.2:3000',
                  ),
                  const SizedBox(height: 10),
                  const Text('Login DJ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _textField(label: 'Email', controller: _emailController, hint: 'dj@zylo.fm'),
                  const SizedBox(height: 10),
                  _textField(label: 'Password', controller: _passwordController, hint: '••••••••', obscure: true),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _loginDj,
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
                  const SizedBox(height: 10),
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ZyloColors.panel.withAlphaF(0.80),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1C1C28)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined, color: Colors.white60, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tus mixes quedan "En revisión". Nadie publica nada sin aprobación del Admin.',
                      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Archivos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _pickAudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZyloColors.panel2,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.audiotrack_rounded, size: 18),
                          label: Text(
                            _audioFile == null ? 'AUDIO' : 'AUDIO ✅',
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _pickCover,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZyloColors.panel2,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.image_rounded, size: 18),
                          label: Text(
                            _coverFile == null ? 'PORTADA' : 'PORTADA ✅',
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _field(label: 'Título', controller: _titleController, hint: 'Ej: Deep House Clean Set Vol. 1', maxLen: 60),
            const SizedBox(height: 10),
            _field(label: 'Género', controller: _genreController, hint: 'Ej: house / techno / afro', maxLen: 40),
            const SizedBox(height: 10),
            _field(
              label: 'Descripción (opcional)',
              controller: _descController,
              hint: '1h • house • clean edit…',
              maxLines: 3,
              maxLen: 300,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.upload_rounded, size: 20),
                label: const Text('ENVIAR A REVISIÓN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4)),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Estado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 10),
            if (_mixes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: ZyloColors.panel.withAlphaF(0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1C1C28)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded, color: Colors.white60, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Aún no has enviado mixes a revisión.', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (final m in _mixes) ...[
                    _mixRow(m),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
          ],
        ),
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

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int? maxLen,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLen,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            counterText: '',
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

  Widget _mixRow(ApiMix mix) {
    final status = _statusLabel(mix.status);
    final color = _statusColor(mix.status);

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
                  mix.title,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
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
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlphaF(0.35),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withAlphaF(0.28)),
            ),
            child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String raw) {
    final s = raw.trim().toLowerCase();
    switch (s) {
      case 'approved':
        return '✅ Aprobado';
      case 'rejected':
        return '❌ Rechazado';
      case 'pending':
      default:
        return '⏳ Pendiente';
    }
  }

  Color _statusColor(String raw) {
    final s = raw.trim().toLowerCase();
    switch (s) {
      case 'approved':
        return const Color(0xFF43D17A);
      case 'rejected':
        return const Color(0xFFFF3B30);
      case 'pending':
      default:
        return ZyloColors.zyloYellow;
    }
  }
}

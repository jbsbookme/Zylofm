import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../api/zylo_api.dart';
import '../api/zylo_api_config.dart';
import '../theme/zylo_theme.dart';

class AdminAssistantLibraryScreen extends StatefulWidget {
  const AdminAssistantLibraryScreen({super.key});

  @override
  State<AdminAssistantLibraryScreen> createState() => _AdminAssistantLibraryScreenState();
}

class _AdminAssistantLibraryScreenState extends State<AdminAssistantLibraryScreen> {
  final _baseUrlController = TextEditingController(text: zyloApiBaseUrl);
  final _emailController = TextEditingController(text: 'admin@zylo.fm');
  final _passwordController = TextEditingController(text: 'admin123456');
  final _tokenController = TextEditingController();

  final _titleController = TextEditingController();
  final _keywordsController = TextEditingController();

  final AudioPlayer _player = AudioPlayer();

  bool _loading = false;
  File? _audioFile;

  List<ApiAssistantLibraryItem> _items = const [];

  ZyloApi _api() => ZyloApi(baseUrl: _baseUrlController.text.trim());

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _titleController.dispose();
    _keywordsController.dispose();
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
      await _loadItems();
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

  Future<void> _loadItems() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta token ADMIN.')));
      return;
    }

    setState(() => _loading = true);
    final api = _api();
    try {
      final list = await api.listAssistantLibrary(token: token);
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo cargar librería: $e')));
    } finally {
      api.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAudio() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav'],
    );
    if (!mounted) return;
    if (res == null || res.files.isEmpty) return;
    final path = res.files.first.path;
    if (path == null) return;
    setState(() => _audioFile = File(path));
  }

  Future<void> _upload() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero inicia sesión ADMIN.')));
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ponle un título.')));
      return;
    }

    if (_audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona audio (mp3/wav).')));
      return;
    }

    setState(() => _loading = true);
    final api = _api();
    try {
      await api.uploadAssistantLibraryAudio(
        token: token,
        title: title,
        audio: _audioFile!,
        keywordsCsv: _keywordsController.text.trim(),
      );

      _titleController.clear();
      _keywordsController.clear();
      setState(() => _audioFile = null);

      await _loadItems();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en assistant_library ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error subiendo audio: $e')));
    } finally {
      api.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _preview(ApiAssistantLibraryItem item) async {
    try {
      await _player.setUrl(item.audioUrl);
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo reproducir: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZyloColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Assistant Library'),
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
                      onPressed: _loading ? null : _loadItems,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('CARGAR LIBRERÍA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subir audio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  _textField(label: 'Título', controller: _titleController, hint: 'Afro intro'),
                  const SizedBox(height: 10),
                  _textField(label: 'Keywords (coma/espacio)', controller: _keywordsController, hint: 'afro, intro, chill'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _pickAudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZyloColors.panel2,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.audiotrack_rounded, size: 18),
                          label: Text(_audioFile == null ? 'ELEGIR AUDIO' : 'AUDIO OK'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _upload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34C759),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: const Text('SUBIR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Items', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            if (_items.isEmpty)
              _empty('No hay items todavía.')
            else
              Column(
                children: [
                  for (final item in _items) ...[
                    _itemCard(item),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(ApiAssistantLibraryItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(
                  item.keywords.isEmpty ? '—' : item.keywords.join(', '),
                  style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => _preview(item),
            icon: const Icon(Icons.play_arrow_rounded, color: ZyloColors.zyloYellow),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C1C28)),
      ),
      child: child,
    );
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZyloColors.panel.withAlphaF(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
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
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: ZyloColors.panel2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

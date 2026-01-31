import 'package:flutter/material.dart';

import '../api/admin_dashboard_api.dart';
import '../api/admin_dashboard_api_config.dart';
import '../theme/zylo_theme.dart';

class DjRegistrationScreen extends StatefulWidget {
  const DjRegistrationScreen({super.key});

  @override
  State<DjRegistrationScreen> createState() => _DjRegistrationScreenState();
}

class _DjRegistrationScreenState extends State<DjRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _baseUrlController = TextEditingController(text: adminDashboardBaseUrl);
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _bioController = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  AdminDashboardApi _api() => AdminDashboardApi(baseUrl: _baseUrlController.text.trim());

  Future<void> _submit() async {
    if (_busy) return;
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _busy = true);
    try {
      final api = _api();
      try {
        final id = await api.registerDj(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          instagram: _instagramController.text,
          bio: _bioController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada. Queda pendiente de aprobación.')),
        );

        // Clear most fields (keep base URL).
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _instagramController.clear();
        _bioController.clear();

        // Handy: show id in debug console.
        // ignore: avoid_print
        print('DJ registered id=$id');
      } finally {
        api.close();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZyloColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Registro DJ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aplica para ser DJ en ZyloFM',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tu solicitud quedará como pendiente y el admin la aprobará desde el dashboard.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),

                _textField(
                  label: 'Admin Dashboard Base URL',
                  controller: _baseUrlController,
                  hint: 'Android emulator: http://10.0.2.2:3001',
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Requerido';
                    if (!t.startsWith('http://') && !t.startsWith('https://')) {
                      return 'Debe empezar con http(s)://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _textField(
                  label: 'Nombre artístico',
                  controller: _nameController,
                  hint: 'Ej: DJ Jorge',
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),

                _textField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'dj@correo.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                _textField(
                  label: 'Teléfono',
                  controller: _phoneController,
                  hint: '+1 ...',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                _textField(
                  label: 'Instagram',
                  controller: _instagramController,
                  hint: '@tuusuario',
                ),
                const SizedBox(height: 12),

                _textField(
                  label: 'Bio',
                  controller: _bioController,
                  hint: 'Cuéntanos tu estilo, experiencia, etc.',
                  maxLines: 4,
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar solicitud'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withAlphaF(0.35)),
            filled: true,
            fillColor: ZyloColors.panel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF1C1C28)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF1C1C28)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }
}

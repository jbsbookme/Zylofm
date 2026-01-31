import 'package:flutter/material.dart';

import '../../api/zylo_api_config.dart';
import '../../audio/zylo_audio_handler.dart';
import '../../data/backend_content_repository.dart';

class AssistantInput extends StatefulWidget {
  final ZyloAudioHandler audioHandler;

  const AssistantInput({super.key, required this.audioHandler});

  @override
  State<AssistantInput> createState() => _AssistantInputState();
}

class _AssistantInputState extends State<AssistantInput> {
  final _controller = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => loading = true);

    try {
      final audioUrl = await const BackendContentRepository(baseUrl: zyloApiBaseUrl).assistantPlay(query);

      if (!mounted) return;

      if (audioUrl != null) {
        await widget.audioHandler.playFromUrl(audioUrl, title: query, artist: 'Assistant');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Hey Zylo, pon Afro...',
            ),
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => loading ? null : _play(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          onPressed: loading ? null : _play,
        ),
      ],
    );
  }
}

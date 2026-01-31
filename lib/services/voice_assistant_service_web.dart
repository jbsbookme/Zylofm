import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceAssistantService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<String?> listenOnce({Duration listenFor = const Duration(seconds: 5)}) async {
    final available = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    if (!available) return null;

    final completer = Completer<String?>();
    String lastWords = '';

    Timer? timeout;
    void finish() {
      if (timeout != null) {
        timeout!.cancel();
        timeout = null;
      }
      if (!completer.isCompleted) {
        final cleaned = lastWords.trim().toLowerCase();
        completer.complete(cleaned.isEmpty ? null : cleaned);
      }
    }

    timeout = Timer(listenFor, () async {
      try {
        await _speech.stop();
      } finally {
        finish();
      }
    });

    await _speech.listen(
      listenFor: listenFor,
      pauseFor: const Duration(seconds: 1),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) {
        lastWords = result.recognizedWords;
        if (result.finalResult) {
          finish();
        }
      },
    );

    final text = await completer.future;
    await _speech.stop();
    return text;
  }
}

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SttResult {
  const SttResult({
    required this.text,
    required this.confidence,
    required this.audioDuration,
    this.detectedLanguage,
  });
  final String text;
  final double confidence;
  final Duration audioDuration;
  final String? detectedLanguage;
}

class SttCapabilities {
  const SttCapabilities({
    required this.supportsStreaming,
    required this.supportsLanguageDetection,
    required this.supportedLanguages,
    required this.onDevice,
  });
  final bool supportsStreaming;
  final bool supportsLanguageDetection;
  final List<String> supportedLanguages;
  final bool onDevice;
}

class TtsCapabilities {
  const TtsCapabilities({
    required this.supportsStreaming,
    required this.supportedLanguages,
    required this.availableVoices,
    required this.onDevice,
  });
  final bool supportsStreaming;
  final List<String> supportedLanguages;
  final List<String> availableVoices;
  final bool onDevice;
}

abstract class SpeechToTextService {
  SttCapabilities get capabilities;
  bool get isAvailable;
  Future<SttResult> transcribe(Uint8List audioData, {String? language});
  Future<void> initialize();
  Future<void> dispose();
}

abstract class TextToSpeechService {
  TtsCapabilities get capabilities;
  bool get isAvailable;
  Future<void> speak(String text, {required String voiceId, String? language, double rate = 1.0});
  Future<Uint8List> synthesize(String text, {required String voiceId, String? language, double rate = 1.0});
  Future<void> stop();
  Future<void> initialize();
  Future<void> dispose();
}

// ─── Placeholder implementations (real sherpa-onnx integration lands later) ──

class PlaceholderSttService extends SpeechToTextService {
  @override
  bool get isAvailable => false;

  @override
  SttCapabilities get capabilities => const SttCapabilities(
        supportsStreaming: false,
        supportsLanguageDetection: false,
        supportedLanguages: [],
        onDevice: false,
      );

  @override
  Future<SttResult> transcribe(Uint8List audioData, {String? language}) async =>
      const SttResult(text: '', confidence: 0, audioDuration: Duration.zero);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}

class PlaceholderTtsService extends TextToSpeechService {
  @override
  bool get isAvailable => false;

  @override
  TtsCapabilities get capabilities => const TtsCapabilities(
        supportsStreaming: false,
        supportedLanguages: [],
        availableVoices: [],
        onDevice: false,
      );

  @override
  Future<void> speak(String text, {required String voiceId, String? language, double rate = 1.0}) async {}

  @override
  Future<Uint8List> synthesize(String text, {required String voiceId, String? language, double rate = 1.0}) async =>
      Uint8List(0);

  @override
  Future<void> stop() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}

final sttServiceProvider = Provider<SpeechToTextService>((_) => PlaceholderSttService());
final ttsServiceProvider = Provider<TextToSpeechService>((_) => PlaceholderTtsService());

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/model_registry.dart';
import 'sherpa_onnx_stt.dart';
import 'sherpa_onnx_tts.dart';
import 'speech_config.dart';
import 'streaming_stt_service.dart';
import 'third_stt_service.dart';

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

  /// Emits `true` when synthesized audio starts playing, `false` when it
  /// stops. The Tutor-mode avatar subscribes to this to drive emotion-state
  /// animations. Placeholder implementations return an empty stream.
  Stream<bool> get isSpeakingStream;

  /// Synchronous snapshot of the current speaking state. Use this to
  /// initialise UI that mounts mid-speech, since [isSpeakingStream] only
  /// emits on changes and a late subscriber would miss the current state.
  bool get isSpeaking;

  /// Emits a 0.0–1.0 loudness envelope value at ~60 fps during speech
  /// playback, derived from the RMS of the synthesized PCM. Drives the
  /// `amplitude` input on the emo_linear.riv Mochi state machine so the
  /// mouth opens proportionally to voice loudness. Emits 0 when silent.
  Stream<double> get amplitudeStream;
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

  @override
  Stream<bool> get isSpeakingStream => const Stream.empty();

  @override
  bool get isSpeaking => false;

  @override
  Stream<double> get amplitudeStream => const Stream.empty();
}

/// Picks the sherpa-onnx implementation when the model registry reports the
/// bundle is ready, otherwise falls back to the no-op placeholder so the app
/// still boots without speech.
///
/// The factory returns a fresh instance per consumer because the sherpa
/// services own native handles and want explicit `dispose()` lifecycle
/// management. Use `ref.onDispose(() => service.dispose())` when watching.
final sttServiceProvider = Provider<SpeechToTextService>((ref) {
  final snap = ref.watch(modelRegistrySnapshotProvider).valueOrNull;
  if (snap?.isReady == true) {
    return SherpaOnnxSttService(registry: ref.read(modelRegistryProvider));
  }
  return PlaceholderSttService();
});

final ttsServiceProvider = Provider<TextToSpeechService>((ref) {
  final snap = ref.watch(modelRegistrySnapshotProvider).valueOrNull;
  if (snap?.isReady == true) {
    return SherpaOnnxTtsService(registry: ref.read(modelRegistryProvider));
  }
  return PlaceholderTtsService();
});

/// Provides a [StreamingSttService] for the third-party AAR engine.
///
/// Returns null when [SpeechConfig.sttEngine] is not [SttEngine.thirdStt].
/// The caller must call [StreamingSttService.configure] before [start].
/// Call [StreamingSttService.dispose] in ref.onDispose.
///
/// Example:
/// ```dart
/// final svc = ref.watch(streamingSttServiceProvider);
/// if (svc != null) {
///   ref.onDispose(svc.dispose);
///   await svc.configure({'modelPath': '/data/.../model', 'sampleRate': 16000});
///   await svc.start();
///   svc.events.listen((e) { … });
/// }
/// ```
final streamingSttServiceProvider = Provider<StreamingSttService?>((ref) {
  // TODO: load SpeechConfig from assets/speech_config.json and expose as a
  // provider. For now, the engine is selected at compile time.
  // Set to SttEngine.sherpaOnnxStreaming (or sherpaOnnxWhisper) in production.
  const engine = SttEngine.thirdStt; // fake engine for testing
  if (engine == SttEngine.thirdStt) {
    final svc = ThirdSttService();
    ref.onDispose(svc.dispose);
    return svc;
  }
  return null;
});

/// `true` when the on-disk model bundle passed manifest + SHA-256 checks.
/// Sherpa services lazy-init native engines on first [SpeechToTextService.transcribe]
/// / [TextToSpeechService.speak] — do **not** gate on [SpeechToTextService.isAvailable]
/// before that, or tutor mode falsely reports "models not installed".
final speechReadyProvider = Provider<bool>((ref) {
  final snap = ref.watch(modelRegistrySnapshotProvider).valueOrNull;
  return snap?.isReady ?? false;
});

/// User-facing explanation when [speechReadyProvider] is false.
String speechModelsStatusMessage(ModelRegistrySnapshot? snap) {
  if (snap == null) {
    return 'Speech models are still being checked. Try again in a moment.';
  }
  switch (snap.status) {
    case ModelRegistryStatus.ready:
      return 'Speech models are ready.';
    case ModelRegistryStatus.manifestMissing:
      return 'manifest.json was not found in:\n${snap.modelRoot}\n'
          'Copy your model files there, run tools/build-manifest.py on that folder, '
          'then open Settings → Storage → Re-verify all.';
    case ModelRegistryStatus.corrupt:
      final bad = snap.verifications
          .where((v) => v.status != FileVerificationStatus.ok)
          .length;
      return 'Speech model verification failed ($bad file(s)). '
          'Open Settings → Storage to see which files are missing or mismatched, '
          'then tap Re-verify all.';
    case ModelRegistryStatus.notReady:
      return 'Speech models are not ready yet. See Settings → Storage.';
  }
}

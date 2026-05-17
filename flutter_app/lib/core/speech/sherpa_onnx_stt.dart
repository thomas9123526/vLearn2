import 'dart:typed_data';
import '../storage/model_registry.dart';
import 'speech_service.dart';

class SttUnavailableException implements Exception {
  SttUnavailableException(this.message);
  final String message;
  @override
  String toString() => 'SttUnavailableException: $message';
}

/// sherpa-onnx backed STT. Initializes by resolving model paths from the
/// [ModelRegistry] and instantiating the native recognizer; everything below
/// the `_invokeNative*` boundary is delegated to the sherpa_onnx plugin.
///
/// The plugin import is **deferred** behind a flag so this file compiles
/// without `sherpa_onnx: ^x.y.z` in pubspec — uncomment the import + the
/// commented `// _recognizer = ...` lines once the dep is bundled.
class SherpaOnnxSttService extends SpeechToTextService {
  SherpaOnnxSttService({required this.registry});

  final ModelRegistry registry;
  bool _initialized = false;
  bool _available = false;

  // ignore: prefer_final_fields
  dynamic _recognizer; // sherpa_onnx.OnlineRecognizer | OfflineRecognizer

  @override
  bool get isAvailable => _available;

  @override
  SttCapabilities get capabilities => const SttCapabilities(
        supportsStreaming: true,
        supportsLanguageDetection: false,
        supportedLanguages: ['en', 'ko', 'zh'],
        onDevice: true,
      );

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final snap = await registry.snapshot();
    if (!snap.isReady) {
      _initialized = true;
      _available = false;
      return;
    }

    // ── Native init lives behind the sherpa_onnx import. Uncomment when the
    // dep is bundled. The model paths come from manifest entries; today the
    // manifest format reserves an "stt" block with `encoder/decoder/tokens`
    // file references that map directly to OnlineRecognizer.
    //
    // final encoderPath = await registry.resolveFile(snap.manifest!.sttEncoderFile);
    // final decoderPath = await registry.resolveFile(snap.manifest!.sttDecoderFile);
    // final tokensPath = await registry.resolveFile(snap.manifest!.sttTokensFile);
    // _recognizer = sherpa_onnx.OnlineRecognizer(
    //   model: sherpa_onnx.OnlineModelConfig(
    //     encoder: encoderPath,
    //     decoder: decoderPath,
    //     tokens: tokensPath,
    //   ),
    // );

    _initialized = true;
    _available = _recognizer != null;
  }

  @override
  Future<SttResult> transcribe(Uint8List audioData, {String? language}) async {
    if (!_initialized) await initialize();
    if (!_available) {
      throw SttUnavailableException(
        'STT models not installed — see Settings → Storage to drop them in.',
      );
    }
    // PCM 16-bit mono @ 16 kHz expected by Whisper-tiny + Sherpa frontends.
    // final samples = _bytesToFloat32Pcm(audioData);
    // _recognizer.acceptWaveform(sampleRate: 16000, samples: samples);
    // _recognizer.inputFinished();
    // while (_recognizer.isReady()) _recognizer.decode();
    // final text = _recognizer.result.text;
    throw SttUnavailableException('Native sherpa-onnx call site not yet wired');
  }

  @override
  Future<void> dispose() async {
    // _recognizer?.free();
    _recognizer = null;
    _initialized = false;
    _available = false;
  }
}

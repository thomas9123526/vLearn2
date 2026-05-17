import 'dart:async';
import 'dart:typed_data';
import '../storage/model_registry.dart';
import 'speech_service.dart';

class TtsUnavailableException implements Exception {
  TtsUnavailableException(this.message);
  final String message;
  @override
  String toString() => 'TtsUnavailableException: $message';
}

/// sherpa-onnx backed TTS. Voice catalog comes from `manifest.json` and is
/// exposed through `capabilities.availableVoices`; persona → voice mapping
/// is the caller's job (the conversation screen does that).
///
/// The native sherpa_onnx import is **deferred** behind a flag so this file
/// compiles without the package — see the commented code blocks for the
/// drop-in path once the dep is bundled.
class SherpaOnnxTtsService extends TextToSpeechService {
  SherpaOnnxTtsService({required this.registry});

  final ModelRegistry registry;
  bool _initialized = false;
  bool _available = false;
  List<String> _voices = const [];

  final _isSpeakingCtrl = StreamController<bool>.broadcast();
  bool _isSpeaking = false;

  /// Emits `true` while audio is playing, `false` when it stops. The Rive
  /// avatar in the conversation screen subscribes to this to drive the
  /// mouth-shape state-machine input.
  Stream<bool> get isSpeakingStream => _isSpeakingCtrl.stream;
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isAvailable => _available;

  @override
  TtsCapabilities get capabilities => TtsCapabilities(
        supportsStreaming: false,
        supportedLanguages: const ['en', 'ko', 'zh'],
        availableVoices: List.unmodifiable(_voices),
        onDevice: true,
      );

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final snap = await registry.snapshot();
    if (!snap.isReady || snap.manifest == null) {
      _initialized = true;
      _available = false;
      return;
    }
    _voices = snap.manifest!.voices;

    // Native init lives behind the sherpa_onnx import. Uncomment once bundled:
    //
    // final modelPath = await registry.resolveFile(snap.manifest!.ttsModelFile);
    // final tokensPath = await registry.resolveFile(snap.manifest!.ttsTokensFile);
    // _engine = sherpa_onnx.OfflineTts(
    //   model: sherpa_onnx.OfflineTtsModelConfig(
    //     model: modelPath,
    //     tokens: tokensPath,
    //   ),
    // );

    _initialized = true;
    _available = _voices.isNotEmpty;
  }

  @override
  Future<void> speak(
    String text, {
    required String voiceId,
    String? language,
    double rate = 1.0,
  }) async {
    if (!_initialized) await initialize();
    if (!_available) {
      throw TtsUnavailableException(
        'TTS models not installed — see Settings → Storage to drop them in.',
      );
    }
    _setSpeaking(true);
    try {
      // final audio = _engine.generate(text: text, sid: _voiceIdToSid(voiceId), speed: rate);
      // await _audioPlayer.play(BytesSource(audio.samplesAsPcm16Bytes));
      throw TtsUnavailableException('Native sherpa-onnx call site not yet wired');
    } finally {
      _setSpeaking(false);
    }
  }

  @override
  Future<Uint8List> synthesize(
    String text, {
    required String voiceId,
    String? language,
    double rate = 1.0,
  }) async {
    if (!_initialized) await initialize();
    if (!_available) {
      throw TtsUnavailableException(
        'TTS models not installed — see Settings → Storage to drop them in.',
      );
    }
    // final audio = _engine.generate(text: text, sid: _voiceIdToSid(voiceId), speed: rate);
    // return audio.samplesAsPcm16Bytes;
    throw TtsUnavailableException('Native sherpa-onnx call site not yet wired');
  }

  @override
  Future<void> stop() async {
    // await _audioPlayer.stop();
    _setSpeaking(false);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _isSpeakingCtrl.close();
    _initialized = false;
    _available = false;
  }

  void _setSpeaking(bool v) {
    if (_isSpeaking == v) return;
    _isSpeaking = v;
    _isSpeakingCtrl.add(v);
  }
}

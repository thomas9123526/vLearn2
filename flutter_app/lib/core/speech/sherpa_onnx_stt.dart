import 'dart:async';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as so;

import '../storage/model_registry.dart';
import 'speech_service.dart';

/// Thrown by [SherpaOnnxSttService] when the model bundle is missing files
/// or the native recognizer can't be constructed. The conversation screen
/// shows the message verbatim in an inline snackbar, so phrase it for the
/// end user (or admin), not for a developer.
class SttUnavailableException implements Exception {
  SttUnavailableException(this.message);
  final String message;
  @override
  String toString() => 'SttUnavailableException: $message';
}

/// Real on-device English speech recognition backed by sherpa-onnx.
///
/// We instantiate one of two recognizer flavours based on what the admin
/// shipped in the manifest:
///   * If the manifest lists `stt/encoder`, `stt/decoder`, `stt/joiner` and
///     `stt/tokens` we build an [so.OnlineRecognizer] (streaming transducer —
///     Zipformer/RNN-T) so the UI can stream partial hypotheses.
///   * Otherwise we look for `stt/whisper-encoder` + `stt/whisper-decoder`
///     and build an [so.OfflineRecognizer] — used for single-shot
///     push-to-talk capture.
///
/// Both flavours expect mono 16-bit PCM at 16 kHz, which is exactly what
/// [AudioRecorderService] produces — so no resampling is needed at this layer.
class SherpaOnnxSttService extends SpeechToTextService {
  SherpaOnnxSttService({required this.registry, Logger? log})
      : _log = log ?? Logger();

  final ModelRegistry registry;
  final Logger _log;

  bool _initialized = false;
  bool _available = false;

  // Only one of these is ever non-null per session — `_online` for streaming
  // models, `_offline` for Whisper. Call sites in [transcribe] branch on it.
  so.OnlineRecognizer? _online;
  so.OfflineRecognizer? _offline;

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
    _initialized = true;

    final snap = await registry.snapshot();
    if (!snap.isReady || snap.manifest == null) {
      _log.i('STT: model registry not ready (${snap.status}); skipping init.');
      _available = false;
      return;
    }

    final manifest = snap.manifest!;
    try {
      // Try streaming transducer first.
      final encoder = await _resolveListedFile(manifest, 'stt/encoder');
      final decoder = await _resolveListedFile(manifest, 'stt/decoder');
      final joiner = await _resolveListedFile(manifest, 'stt/joiner');
      final tokens = await _resolveListedFile(manifest, 'stt/tokens');

      if (encoder != null && decoder != null && joiner != null && tokens != null) {
        _online = so.OnlineRecognizer(
          so.OnlineRecognizerConfig(
            model: so.OnlineModelConfig(
              transducer: so.OnlineTransducerModelConfig(
                encoder: encoder,
                decoder: decoder,
                joiner: joiner,
              ),
              tokens: tokens,
            ),
          ),
        );
        _available = true;
        _log.i('STT: OnlineRecognizer ready (streaming).');
        return;
      }

      // Whisper-style fallback.
      final whisperEncoder = await _resolveListedFile(manifest, 'stt/whisper-encoder');
      final whisperDecoder = await _resolveListedFile(manifest, 'stt/whisper-decoder');
      if (whisperEncoder != null && whisperDecoder != null && tokens != null) {
        _offline = so.OfflineRecognizer(
          so.OfflineRecognizerConfig(
            model: so.OfflineModelConfig(
              whisper: so.OfflineWhisperModelConfig(
                encoder: whisperEncoder,
                decoder: whisperDecoder,
              ),
              tokens: tokens,
              modelType: 'whisper',
            ),
          ),
        );
        _available = true;
        _log.i('STT: OfflineRecognizer ready (whisper).');
        return;
      }

      _log.w('STT: manifest has no recognizable STT block; staying disabled.');
      _available = false;
    } catch (e, st) {
      _log.e('STT: native init failed', error: e, stackTrace: st);
      _available = false;
    }
  }

  /// Looks for any manifest file whose relative path starts with [prefix] and
  /// returns its absolute on-disk path. Returns `null` if the manifest
  /// doesn't list a file with that prefix — callers branch on null to decide
  /// which recognizer flavour to build.
  Future<String?> _resolveListedFile(ModelManifest m, String prefix) async {
    for (final f in m.files) {
      if (f.relativePath.startsWith(prefix)) {
        return registry.resolveFile(f.relativePath);
      }
    }
    return null;
  }

  @override
  Future<SttResult> transcribe(Uint8List audioData, {String? language}) async {
    if (!_initialized) await initialize();
    if (!_available) {
      throw SttUnavailableException(
        'Speech models are not installed yet. Ask your admin to drop the '
        'sherpa-onnx bundle into the models folder.',
      );
    }

    // Convert little-endian int16 PCM -> Float32 in the [-1, 1] range, which
    // is what every sherpa-onnx recognizer accepts.
    final samples = _pcm16ToFloat32(audioData);
    const sampleRate = 16000;
    final durationSeconds = samples.length / sampleRate;

    try {
      if (_online != null) {
        final stream = _online!.createStream();
        stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
        stream.inputFinished();
        while (_online!.isReady(stream)) {
          _online!.decode(stream);
        }
        final text = _online!.getResult(stream).text;
        stream.free();
        return SttResult(
          text: text.trim(),
          confidence: 1.0, // sherpa-onnx doesn't expose per-utterance scores
          audioDuration: Duration(milliseconds: (durationSeconds * 1000).round()),
        );
      } else if (_offline != null) {
        final stream = _offline!.createStream();
        stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
        _offline!.decode(stream);
        final result = _offline!.getResult(stream);
        stream.free();
        return SttResult(
          text: result.text.trim(),
          confidence: 1.0,
          audioDuration: Duration(milliseconds: (durationSeconds * 1000).round()),
          detectedLanguage: result.lang.isEmpty ? null : result.lang,
        );
      }
      throw SttUnavailableException('No recognizer was constructed.');
    } catch (e, st) {
      _log.e('STT: transcribe failed', error: e, stackTrace: st);
      throw SttUnavailableException(
        'The recognizer crashed while transcribing your audio. Please try '
        'again — if this keeps happening, the model files may be corrupt.',
      );
    }
  }

  /// PCM 16-bit (little-endian) -> Float32 in `[-1, 1]`. Allocates one
  /// Float32List the size of the input / 2; cheap enough at the rates we
  /// stream (~32 KB per second).
  Float32List _pcm16ToFloat32(Uint8List pcm) {
    final samples = Float32List(pcm.length ~/ 2);
    final view = ByteData.sublistView(pcm);
    for (var i = 0, j = 0; j < samples.length; i += 2, j++) {
      samples[j] = view.getInt16(i, Endian.little) / 32768.0;
    }
    return samples;
  }

  @override
  Future<void> dispose() async {
    _online?.free();
    _online = null;
    _offline?.free();
    _offline = null;
    _initialized = false;
    _available = false;
  }
}

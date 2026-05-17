import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as so;

import '../storage/model_registry.dart';
import 'speech_service.dart';

/// Same conventions as [SttUnavailableException] — phrase the message for
/// the end user, not for a developer. It surfaces in the conversation
/// screen if synthesis fails mid-turn.
class TtsUnavailableException implements Exception {
  TtsUnavailableException(this.message);
  final String message;
  @override
  String toString() => 'TtsUnavailableException: $message';
}

/// Real on-device text-to-speech backed by a sherpa-onnx VITS (Piper-style)
/// model.
///
/// Playback flow:
///   1. [synthesize] feeds text into [so.OfflineTts.generate] and gets back
///      Float32 PCM samples + a sample rate.
///   2. We wrap that into a WAV byte buffer ([_pcmToWav]) and either play it
///      via [audioplayers] ([speak]) or just return the bytes for caching
///      ([synthesize]).
///   3. A `<modelRoot>/cache/tts/<sha256>.wav` cache short-circuits repeat
///      requests for the same `(text, voiceId)` — useful for greeting lines
///      that get re-spoken every session.
///
/// The [isSpeakingStream] is the integration point for the Rive tutor
/// avatar: the conversation screen subscribes and drives the mouth-shape
/// state-machine input from those events.
class SherpaOnnxTtsService extends TextToSpeechService {
  SherpaOnnxTtsService({required this.registry, Logger? log})
      : _log = log ?? Logger();

  final ModelRegistry registry;
  final Logger _log;

  bool _initialized = false;
  bool _available = false;
  List<String> _voices = const [];

  so.OfflineTts? _engine;
  final ap.AudioPlayer _player = ap.AudioPlayer();

  final _isSpeakingCtrl = StreamController<bool>.broadcast();
  bool _isSpeaking = false;

  /// Emits `true` while audio is playing, `false` when it stops. The Rive
  /// avatar in the conversation screen subscribes to this to drive the
  /// mouth-shape state-machine input.
  @override
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
    _initialized = true;

    final snap = await registry.snapshot();
    if (!snap.isReady || snap.manifest == null) {
      _log.i('TTS: model registry not ready (${snap.status}); skipping init.');
      _available = false;
      return;
    }

    final manifest = snap.manifest!;
    _voices = manifest.voices;

    try {
      final model = await _resolveListedFile(manifest, 'tts/model');
      final tokens = await _resolveListedFile(manifest, 'tts/tokens');
      final dataDir = await _resolveListedDir(manifest, 'tts/espeak-ng-data');

      if (model == null || tokens == null) {
        _log.w('TTS: manifest missing required model/tokens files.');
        _available = false;
        return;
      }

      _engine = so.OfflineTts(
        so.OfflineTtsConfig(
          model: so.OfflineTtsModelConfig(
            vits: so.OfflineTtsVitsModelConfig(
              model: model,
              tokens: tokens,
              dataDir: dataDir ?? '',
            ),
          ),
        ),
      );
      _available = true;
      _log.i('TTS: OfflineTts ready with ${_voices.length} voices.');

      // Bridge audioplayers state -> our isSpeaking stream.
      _player.onPlayerStateChanged.listen((state) {
        final speaking = state == ap.PlayerState.playing;
        _setSpeaking(speaking);
      });
    } catch (e, st) {
      _log.e('TTS: native init failed', error: e, stackTrace: st);
      _available = false;
    }
  }

  Future<String?> _resolveListedFile(ModelManifest m, String prefix) async {
    for (final f in m.files) {
      if (f.relativePath.startsWith(prefix)) {
        return registry.resolveFile(f.relativePath);
      }
    }
    return null;
  }

  /// espeak-ng-data ships as a directory; the manifest only lists one file
  /// under it as a marker — we return the directory portion so sherpa-onnx
  /// can iterate the rest.
  Future<String?> _resolveListedDir(ModelManifest m, String prefix) async {
    for (final f in m.files) {
      if (f.relativePath.startsWith(prefix)) {
        final abs = await registry.resolveFile(f.relativePath);
        return p.dirname(abs);
      }
    }
    return null;
  }

  @override
  Future<void> speak(
    String text, {
    required String voiceId,
    String? language,
    double rate = 1.0,
  }) async {
    if (!_initialized) await initialize();
    if (!_available || _engine == null) {
      throw TtsUnavailableException(
        'Speech models are not installed yet. Ask your admin to drop the '
        'sherpa-onnx bundle into the models folder.',
      );
    }
    final wav = await synthesize(
      text,
      voiceId: voiceId,
      language: language,
      rate: rate,
    );
    _setSpeaking(true);
    try {
      await _player.play(ap.BytesSource(wav));
      // onPlayerStateChanged will toggle isSpeaking back to false on
      // completion — see initialize().
    } catch (e, st) {
      _log.e('TTS: playback failed', error: e, stackTrace: st);
      _setSpeaking(false);
      rethrow;
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
    if (!_available || _engine == null) {
      throw TtsUnavailableException(
        'Speech models are not installed yet. Ask your admin to drop the '
        'sherpa-onnx bundle into the models folder.',
      );
    }

    // Cache check.
    final cacheFile = await _cachePath(text, voiceId, rate);
    if (cacheFile.existsSync()) {
      return cacheFile.readAsBytes();
    }

    final sid = _voiceIdToSid(voiceId);
    final audio = _engine!.generate(
      text: text,
      sid: sid,
      speed: rate,
    );
    final wav = _pcmToWav(audio.samples, audio.sampleRate);

    // Persist to cache. Errors here are non-fatal — playback still works.
    try {
      cacheFile.parent.createSync(recursive: true);
      cacheFile.writeAsBytesSync(wav);
    } catch (e) {
      _log.w('TTS: cache write failed for ${cacheFile.path}: $e');
    }

    return wav;
  }

  int _voiceIdToSid(String voiceId) {
    final idx = _voices.indexOf(voiceId);
    return idx < 0 ? 0 : idx;
  }

  /// `<appSupport>/cache/tts/<sha256(text|voiceId|rate)>.wav`. Hashing the
  /// triple guarantees a different file when any input changes.
  Future<File> _cachePath(String text, String voiceId, double rate) async {
    final root = await getApplicationSupportDirectory();
    final key = sha256.convert('$voiceId|$rate|$text'.codeUnits).toString();
    return File(p.join(root.path, 'cache', 'tts', '$key.wav'));
  }

  /// Wrap Float32 mono PCM samples in a minimal RIFF/WAV header so
  /// audioplayers can decode them with no extra dependency.
  Uint8List _pcmToWav(Float32List samples, int sampleRate) {
    const bytesPerSample = 2; // we down-convert to int16 below
    final dataSize = samples.length * bytesPerSample;
    final buf = BytesBuilder();
    void writeStr(String s) => buf.add(s.codeUnits);
    void writeUint32LE(int v) {
      buf.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
    }
    void writeUint16LE(int v) {
      buf.add([v & 0xff, (v >> 8) & 0xff]);
    }

    writeStr('RIFF');
    writeUint32LE(36 + dataSize);
    writeStr('WAVE');
    writeStr('fmt ');
    writeUint32LE(16); // PCM fmt-chunk size
    writeUint16LE(1); // PCM format
    writeUint16LE(1); // mono
    writeUint32LE(sampleRate);
    writeUint32LE(sampleRate * bytesPerSample); // byte rate
    writeUint16LE(bytesPerSample); // block align
    writeUint16LE(bytesPerSample * 8); // bits per sample
    writeStr('data');
    writeUint32LE(dataSize);

    final pcm = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      final s = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      pcm[i] = s;
    }
    buf.add(pcm.buffer.asUint8List());
    return buf.toBytes();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _setSpeaking(false);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
    _engine?.free();
    _engine = null;
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

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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

  final _amplitudeCtrl = StreamController<double>.broadcast();
  Timer? _amplitudeTimer;
  double _ampSma = 0.0; // smoothed amplitude value

  /// Emits `true` while audio is playing, `false` when it stops.
  @override
  Stream<bool> get isSpeakingStream => _isSpeakingCtrl.stream;
  bool get isSpeaking => _isSpeaking;

  /// Emits a 0.0–1.0 loudness envelope at ~60 fps during speech playback.
  /// Derived from the RMS of the synthesized PCM; drives the `amplitude`
  /// input on the emo_linear.riv Mochi state machine.
  @override
  Stream<double> get amplitudeStream => _amplitudeCtrl.stream;

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
      // Piper voices use espeak-ng-data; lexicon-based voices (e.g. vits-vctk)
      // use a lexicon.txt instead. Support both.
      final lexicon = await _resolveListedFile(manifest, 'tts/lexicon');
      final dataDir = lexicon != null
          ? null
          : await _resolveListedDir(manifest, 'tts/espeak-ng-data');

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
              lexicon: lexicon ?? '',
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
      debugPrint('[tts] engine unavailable — models not installed?');
      throw TtsUnavailableException(
        'Speech models are not installed yet. Ask your admin to drop the '
        'sherpa-onnx bundle into the models folder.',
      );
    }
    final swatch = Stopwatch()..start();
    final wav = await synthesize(
      text,
      voiceId: voiceId,
      language: language,
      rate: rate,
    );
    swatch.stop();
    debugPrint('[tts] engine.synthesize voice=$voiceId rate=$rate '
        'len=${text.length} wav=${wav.length}B in ${swatch.elapsedMilliseconds}ms');
    _startAmplitudeEmitter(wav);
    _setSpeaking(true);
    try {
      await _player.play(ap.BytesSource(wav));
      // onPlayerStateChanged will toggle isSpeaking back to false on
      // completion — see initialize().
    } catch (e, st) {
      debugPrint('[tts] playback failed: $e');
      _log.e('TTS: playback failed', error: e, stackTrace: st);
      _stopAmplitudeEmitter();
      _setSpeaking(false);
      rethrow;
    }
  }

  // ─── Amplitude / lip-sync helpers ─────────────────────────────────────────

  /// Parse the WAV sample rate from bytes 24–27 (little-endian uint32).
  static int _wavSampleRate(Uint8List wav) {
    if (wav.length < 28) return 22050;
    return ByteData.sublistView(wav, 24, 28).getUint32(0, Endian.little);
  }

  /// Build a per-16ms RMS loudness envelope from a WAV buffer.
  /// Returns a list of 0.0–1.0 values, one per ~16 ms window.
  static List<double> _buildEnvelope(Uint8List wav) {
    const headerBytes = 44;
    const windowMs = 16;
    const gain = 3.2;
    if (wav.length <= headerBytes) return const [];

    final sampleRate = _wavSampleRate(wav);
    final int16 = Int16List.view(wav.buffer, headerBytes);
    final windowSamples =
        ((sampleRate * windowMs) ~/ 1000).clamp(1, int16.length);

    final env = <double>[];
    for (var i = 0; i < int16.length; i += windowSamples) {
      final end = (i + windowSamples).clamp(0, int16.length);
      var sum = 0.0;
      for (var j = i; j < end; j++) {
        final s = int16[j] / 32767.0;
        sum += s * s;
      }
      final rms = math.sqrt(sum / (end - i));
      env.add((rms * gain).clamp(0.0, 1.0));
    }
    return env;
  }

  void _startAmplitudeEmitter(Uint8List wav) {
    _amplitudeTimer?.cancel();
    _ampSma = 0.0;
    final env = _buildEnvelope(wav);
    if (env.isEmpty) return;

    final sw = Stopwatch()..start();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final i = (sw.elapsedMilliseconds / 16).floor();
      final target = (i < env.length) ? env[i] : 0.0;
      _ampSma = _ampSma * 0.6 + target * 0.4; // exponential smoothing
      if (!_amplitudeCtrl.isClosed) _amplitudeCtrl.add(_ampSma);
      if (i >= env.length) {
        t.cancel();
        _amplitudeTimer = null;
        if (!_amplitudeCtrl.isClosed) _amplitudeCtrl.add(0.0);
      }
    });
  }

  void _stopAmplitudeEmitter() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _ampSma = 0.0;
    if (!_amplitudeCtrl.isClosed) _amplitudeCtrl.add(0.0);
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
    if (await cacheFile.exists()) {
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
      await cacheFile.parent.create(recursive: true);
      await cacheFile.writeAsBytes(wav);
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
    _stopAmplitudeEmitter();
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
    await _amplitudeCtrl.close();
    _initialized = false;
    _available = false;
  }

  void _setSpeaking(bool v) {
    if (_isSpeaking == v) return;
    _isSpeaking = v;
    _isSpeakingCtrl.add(v);
  }
}

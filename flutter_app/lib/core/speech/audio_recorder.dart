import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as pp;
import 'package:record/record.dart' as rc;

/// State of the recorder, surfaced through [AudioRecorderService.state].
///
/// `idle` is the resting state, `recording` while the mic is open, `denied`
/// once the user explicitly denied the OS mic prompt (we don't keep asking),
/// and `error` for any other failure. The UI maps these to the mic-button
/// animation in the conversation screen.
enum AudioRecorderState { idle, recording, denied, error }

/// Result of a finished push-to-talk capture.
///
/// `pcm` is little-endian signed 16-bit mono samples at [sampleRate]. That
/// matches what every sherpa-onnx STT model in our supported set expects, so
/// no resample/conversion is needed before feeding the recognizer.
class AudioCapture {
  const AudioCapture({
    required this.pcm,
    required this.sampleRate,
    required this.duration,
  });

  final Uint8List pcm;
  final int sampleRate;
  final Duration duration;
}

/// Wraps the `record` plugin so the rest of the app can do push-to-talk
/// capture without touching plugin types directly.
///
/// Lifecycle:
///   1. [requestPermission] — call once before the first recording attempt.
///   2. [start] — opens the mic stream; samples land in an internal buffer.
///   3. [stop] — closes the stream and returns the accumulated capture.
///
/// The recorder enforces a [maxDuration] hard cap so a stuck press doesn't
/// drain the battery or balloon memory. The default of 60 seconds is plenty
/// for a single conversational turn.
class AudioRecorderService {
  AudioRecorderService({
    rc.AudioRecorder? recorder,
    this.sampleRate = 16000,
    this.maxDuration = const Duration(seconds: 60),
  }) : _recorder = recorder ?? rc.AudioRecorder();

  final rc.AudioRecorder _recorder;
  final int sampleRate;
  final Duration maxDuration;

  final _stateCtrl =
      StreamController<AudioRecorderState>.broadcast(sync: true);
  AudioRecorderState _state = AudioRecorderState.idle;

  StreamSubscription<Uint8List>? _sub;
  final _buffer = BytesBuilder(copy: false);
  DateTime? _startedAt;
  Timer? _maxTimer;

  AudioRecorderState get state => _state;
  Stream<AudioRecorderState> get stateStream => _stateCtrl.stream;
  bool get isRecording => _state == AudioRecorderState.recording;

  void _setState(AudioRecorderState next) {
    if (_state == next) return;
    _state = next;
    _stateCtrl.add(next);
  }

  /// Asks the OS for mic permission. Returns `true` if granted.
  ///
  /// On Android this triggers the system dialog the first time and reads the
  /// stored choice thereafter — `permission_handler` handles all of that.
  /// On Windows the mic dialog is owned by the OS and shows up the first
  /// time `start()` opens the input device.
  Future<bool> requestPermission() async {
    final status = await pp.Permission.microphone.request();
    if (status.isPermanentlyDenied || status.isDenied) {
      _setState(AudioRecorderState.denied);
      return false;
    }
    if (_state == AudioRecorderState.denied) _setState(AudioRecorderState.idle);
    return true;
  }

  /// Opens the mic and begins streaming PCM into the internal buffer.
  ///
  /// Returns `false` if permission is missing or the recorder couldn't open;
  /// the caller should already have called [requestPermission] earlier in the
  /// gesture.
  Future<bool> start() async {
    if (isRecording) return true;
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      _setState(AudioRecorderState.denied);
      return false;
    }
    _buffer.clear();
    try {
      final stream = await _recorder.startStream(
        rc.RecordConfig(
          encoder: rc.AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );
      _startedAt = DateTime.now();
      _sub = stream.listen(
        _buffer.add,
        onError: (Object _) => _setState(AudioRecorderState.error),
        cancelOnError: true,
      );
      _maxTimer = Timer(maxDuration, stop);
      _setState(AudioRecorderState.recording);
      return true;
    } catch (_) {
      _setState(AudioRecorderState.error);
      return false;
    }
  }

  /// Closes the mic stream and returns whatever was captured.
  ///
  /// Returns `null` if there was nothing recorded (e.g. user tapped without
  /// holding). Callers should treat a zero-byte capture as a no-op.
  Future<AudioCapture?> stop() async {
    if (!isRecording) return null;
    _maxTimer?.cancel();
    _maxTimer = null;
    await _recorder.stop();
    await _sub?.cancel();
    _sub = null;
    _setState(AudioRecorderState.idle);
    final pcm = _buffer.takeBytes();
    if (pcm.isEmpty) return null;
    final duration = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);
    _startedAt = null;
    return AudioCapture(
      pcm: pcm,
      sampleRate: sampleRate,
      duration: duration,
    );
  }

  /// Cancels recording without returning a capture. Used when the user backs
  /// out of the conversation screen mid-press.
  Future<void> cancel() async {
    if (!isRecording) return;
    _maxTimer?.cancel();
    _maxTimer = null;
    await _recorder.stop();
    await _sub?.cancel();
    _sub = null;
    _buffer.clear();
    _startedAt = null;
    _setState(AudioRecorderState.idle);
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
    await _stateCtrl.close();
  }
}

/// Singleton recorder — one mic instance per app process. Disposed when the
/// container is torn down (i.e. app exit).
final audioRecorderProvider = Provider<AudioRecorderService>((ref) {
  final svc = AudioRecorderService();
  ref.onDispose(svc.dispose);
  return svc;
});

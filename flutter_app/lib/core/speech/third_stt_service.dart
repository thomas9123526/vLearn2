import 'dart:async';

import 'package:flutter/services.dart';

import 'streaming_stt_service.dart';

/// Dart implementation of [StreamingSttService] backed by the third-party AAR.
///
/// Communication
/// ─────────────
/// MethodChannel  "vlearn/thirdstt"        → configure / start / stop / destroy
/// EventChannel   "vlearn/thirdstt/events" ← partial | final | error | volume
///
/// Lifecycle
/// ─────────
/// 1. Call [configure] with engine params (modelPath, sampleRate, …).
/// 2. Subscribe to [events].
/// 3. Call [start] → engine begins capturing audio.
/// 4. Call [stop]  → engine flushes → emits SttFinalEvent.
/// 5. Call [dispose] when the widget/service that owns this is torn down.
///
/// Replacing the stub with the real AAR
/// ─────────────────────────────────────
/// No changes needed here.  Drop the AAR into android/app/libs/,
/// update ThirdSttContract.kt, and rebuild.
class ThirdSttService implements StreamingSttService {
  ThirdSttService() {
    _nativeSub = _eventChannel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (Object err) => _controller.add(SttErrorEvent(err.toString())),
    );
  }

  static const _methodChannel = MethodChannel('vlearn/thirdstt');
  static const _eventChannel  = EventChannel('vlearn/thirdstt/events');

  final _controller = StreamController<SttEvent>.broadcast();
  StreamSubscription<dynamic>? _nativeSub;

  // ── StreamingSttService ──────────────────────────────────────────────────

  @override
  Stream<SttEvent> get events => _controller.stream;

  @override
  Future<void> configure(Map<String, dynamic> params) =>
      _methodChannel.invokeMethod<void>('configure', params);

  @override
  Future<void> start() => _methodChannel.invokeMethod<void>('start');

  @override
  Future<void> stop() => _methodChannel.invokeMethod<void>('stop');

  @override
  Future<void> dispose() async {
    await _methodChannel.invokeMethod<void>('destroy');
    await _nativeSub?.cancel();
    await _controller.close();
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  void _onNativeEvent(dynamic raw) {
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);
    switch (m['type'] as String?) {
      case 'partial':
        _controller.add(SttPartialEvent(m['text'] as String? ?? ''));
      case 'final':
        _controller.add(SttFinalEvent(
          m['text'] as String? ?? '',
          confidence: (m['confidence'] as num?)?.toDouble() ?? 1.0,
        ));
      case 'error':
        _controller.add(SttErrorEvent(
          m['message'] as String? ?? 'unknown error',
          code: (m['code'] as num?)?.toInt(),
        ));
      case 'volume':
        _controller.add(SttVolumeEvent(
          (m['rms'] as num?)?.toDouble() ?? 0.0,
        ));
    }
  }
}

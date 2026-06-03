/// Abstract interface for streaming (event-based) STT engines.
///
/// Unlike [SpeechToTextService] — which takes a pre-recorded [Uint8List] —
/// a streaming service manages its own audio loop and fires [SttEvent]s as
/// recognition progresses.  The third-party AAR bridge ([ThirdSttService])
/// implements this interface; future engines (whisper.cpp streaming, etc.)
/// can do the same.
library;

// ─── Events ──────────────────────────────────────────────────────────────────

sealed class SttEvent {}

/// Intermediate hypothesis while the user is still speaking.
class SttPartialEvent extends SttEvent {
  SttPartialEvent(this.text);
  final String text;
}

/// Utterance finished — stable, high-confidence transcription.
class SttFinalEvent extends SttEvent {
  SttFinalEvent(this.text, {this.confidence = 1.0});
  final String text;
  final double confidence;
}

/// Engine-level error.
class SttErrorEvent extends SttEvent {
  SttErrorEvent(this.message, {this.code});
  final String message;
  final int? code;
}

/// Microphone volume tick — [rms] in dB (negative = quiet).
class SttVolumeEvent extends SttEvent {
  SttVolumeEvent(this.rms);
  final double rms;
}

// ─── Abstract service ────────────────────────────────────────────────────────

abstract class StreamingSttService {
  /// Continuous stream of [SttEvent]s.  Subscribe before calling [start].
  Stream<SttEvent> get events;

  /// Configure the engine.
  ///
  /// [params] keys depend on the engine:
  ///   thirdStt  → modelPath, sampleRate, vadEnabled  (see ThirdSttService)
  Future<void> configure(Map<String, dynamic> params);

  /// Start audio capture and recognition.
  Future<void> start();

  /// Stop recognition.  The engine must flush the current utterance and fire
  /// a final [SttFinalEvent] (or [SttErrorEvent]) before becoming idle.
  Future<void> stop();

  /// Release all resources (engine + audio).  Do not call [start] after this.
  Future<void> dispose();
}

# Switching Between STT/TTS Implementations

This guide explains how to switch from the current **sherpa-onnx** on-device
speech implementation to a **Java Native** STT/TTS library, or to combine both
so you can fall back gracefully.

---

## 1. Current Architecture (sherpa-onnx)

```
flutter_app/lib/core/speech/
  speech_service.dart          ← Abstract interfaces (SpeechToTextService, TextToSpeechService)
  sherpa_onnx_stt.dart         ← Concrete STT backed by sherpa-onnx
  sherpa_onnx_tts.dart         ← Concrete TTS backed by sherpa-onnx VITS/Piper
  audio_recorder.dart          ← Raw mic capture (feeds SherpaOnnxSttService)
```

The two abstract interfaces are:

| Interface              | Key methods                             |
|------------------------|-----------------------------------------|
| `SpeechToTextService`  | `initialize()`, `startListening()`, `stopListening()`, `transcriptStream` |
| `TextToSpeechService`  | `initialize()`, `speak(text, voiceId)`, `synthesize(text, voiceId)`, `stop()` |

Both are registered via Riverpod providers in `main.dart`:
```dart
sttServiceProvider  →  SherpaOnnxSttService
ttsServiceProvider  →  SherpaOnnxTtsService
```

---

## 2. Java Native STT/TTS Library — What You Have

Your Java native library presumably exposes a `MethodChannel` (or `EventChannel`)
via a Flutter plugin.  Before switching, confirm:

- **Plugin package name** — e.g. `com.example.nativespeech`
- **Method signatures** for STT:
  - `startRecognition()` → stream of partial/final transcripts
  - `stopRecognition()` → void
- **Method signatures** for TTS:
  - `speak(String text, String voiceId)` → void / Future
  - `stop()` → void
  - `listVoices()` → `List<String>`

---

## 3. How to Add the Java Native Implementation

### Step 1 — Create the Flutter wrapper

Create two new files that implement the same abstract interfaces:

```
flutter_app/lib/core/speech/
  native_stt_service.dart   ← wraps MethodChannel / EventChannel
  native_tts_service.dart   ← wraps MethodChannel
```

**native_stt_service.dart skeleton:**
```dart
import 'package:flutter/services.dart';
import 'speech_service.dart';

class NativeSttService extends SpeechToTextService {
  static const _channel = MethodChannel('com.example.nativespeech/stt');
  static const _events  = EventChannel('com.example.nativespeech/stt/events');

  final _transcriptCtrl = StreamController<String>.broadcast();

  @override Stream<String> get transcriptStream => _transcriptCtrl.stream;
  @override bool get isAvailable => _initialized;

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // Subscribe to the native event stream
    _events.receiveBroadcastStream().listen(
      (event) => _transcriptCtrl.add(event as String),
    );
    _initialized = true;
  }

  @override Future<void> startListening() => _channel.invokeMethod('start');
  @override Future<void> stopListening()  => _channel.invokeMethod('stop');
  @override Future<void> dispose() async => _transcriptCtrl.close();
}
```

**native_tts_service.dart skeleton:**
```dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'speech_service.dart';

class NativeTtsService extends TextToSpeechService {
  static const _channel = MethodChannel('com.example.nativespeech/tts');

  @override bool get isAvailable => true;
  @override TtsCapabilities get capabilities => const TtsCapabilities(
    supportsStreaming: false,
    supportedLanguages: ['en'],
    availableVoices: [],   // populate after init
    onDevice: true,
  );

  @override Future<void> initialize() async { /* warm up native engine */ }

  @override
  Future<void> speak(String text, {required String voiceId, String? language, double rate = 1.0}) =>
      _channel.invokeMethod('speak', {'text': text, 'voiceId': voiceId, 'rate': rate});

  @override
  Future<Uint8List> synthesize(String text, {required String voiceId, String? language, double rate = 1.0}) async {
    final bytes = await _channel.invokeMethod<Uint8List>('synthesize', {'text': text, 'voiceId': voiceId});
    return bytes ?? Uint8List(0);
  }

  @override Future<void> stop() => _channel.invokeMethod('stop');
  @override Future<void> dispose() async {}

  @override Stream<bool> get isSpeakingStream => const Stream.empty();
}
```

### Step 2 — Switch the provider

In `main.dart` (or wherever `sttServiceProvider` / `ttsServiceProvider` are
overridden), swap the concrete class:

```dart
// Before (sherpa-onnx):
final sttServiceProvider = Provider<SpeechToTextService>(
  (ref) => SherpaOnnxSttService(registry: ref.read(modelRegistryProvider)),
);

// After (Java native):
final sttServiceProvider = Provider<SpeechToTextService>(
  (ref) => NativeSttService(),
);
```

No other code changes are needed — the rest of the app calls only the abstract
interface.

---

## 4. Combining Both (Graceful Fallback)

Create a `FallbackSttService` that tries sherpa-onnx first and falls back to
native if the model is not installed:

```dart
class FallbackSttService extends SpeechToTextService {
  FallbackSttService({required this.primary, required this.fallback});

  final SpeechToTextService primary;   // SherpaOnnxSttService
  final SpeechToTextService fallback;  // NativeSttService

  SpeechToTextService get _active => primary.isAvailable ? primary : fallback;

  @override bool get isAvailable => primary.isAvailable || fallback.isAvailable;
  @override Stream<String> get transcriptStream => _active.transcriptStream;

  @override Future<void> initialize() async {
    await primary.initialize();
    if (!primary.isAvailable) await fallback.initialize();
  }

  @override Future<void> startListening() => _active.startListening();
  @override Future<void> stopListening()  => _active.stopListening();
  @override Future<void> dispose()        => Future.wait([primary.dispose(), fallback.dispose()]);
}
```

Register it:
```dart
final sttServiceProvider = Provider<SpeechToTextService>((ref) => FallbackSttService(
  primary:  SherpaOnnxSttService(registry: ref.read(modelRegistryProvider)),
  fallback: NativeSttService(),
));
```

---

## 5. Checklist

- [ ] Java native plugin registered in `android/app/build.gradle` and `pubspec.yaml`
- [ ] `NativeSttService` / `NativeTtsService` created and implementing the abstract interface
- [ ] Provider in `main.dart` swapped (or `FallbackSttService` wrapping both)
- [ ] `speechReadyProvider` (guards the mic button) updated if it checks `isAvailable` on the concrete type
- [ ] Tested: mic button activates, transcript arrives, TTS plays back
- [ ] Verified: `isSpeakingStream` drives the Rive tutor avatar mouth animation correctly

---

## 6. File Map

| File | Purpose |
|------|---------|
| `lib/core/speech/speech_service.dart` | Abstract interfaces — **do not change** |
| `lib/core/speech/sherpa_onnx_stt.dart` | Current on-device STT |
| `lib/core/speech/sherpa_onnx_tts.dart` | Current on-device TTS |
| `lib/core/speech/native_stt_service.dart` | **New** Java native STT wrapper |
| `lib/core/speech/native_tts_service.dart` | **New** Java native TTS wrapper |
| `lib/main.dart` | Provider registration (swap here to switch implementations) |

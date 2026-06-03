# Also Can i put stt/tts thirdparty library?   They are java native project. they 

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T06:02:55.603Z

## User

Also Can i put stt/tts thirdparty library?   They are java native project. they use audio recorder in while loop, catch voice bytes and send to engine(.so) and get result via call back.  
So Can i wrap those into aar and put into our project and give 'thirdstt' for enum SttEngine in speech_config.dart? If so what interfaces should i put on the aar part.
Suggest me solution

## Assistant

Yes, this is a clean integration pattern. Here's the full architecture:

---

## Architecture overview

```
Flutter App
    ↕  MethodChannel  (start / stop / destroy / configure)
    ↕  EventChannel   (partial | final | error | volume events)
Kotlin bridge plugin  (in android/src/…)
    ↕  AAR public interface
Third-party AAR
    ↕  .so via JNI
```

The AAR owns the audio loop. The Kotlin bridge just translates between the AAR callbacks and Flutter channels.

---

## What interfaces the AAR must expose

```java
// ── Config (passed once at startup) ─────────────────────────────────────────
public class ThirdSttConfig {
    public String modelPath;      // absolute path to .so / model dir
    public int    sampleRate;     // 16000 recommended
    public int    channels;       // 1 (mono)
    public int    bitsPerSample;  // 16
    public boolean vadEnabled;    // let library do its own VAD
    // add engine-specific keys here
}

// ── Result callback (you implement, library calls) ───────────────────────────
public interface SttResultCallback {
    void onPartialResult(String text);
    void onFinalResult(String text, float confidence);
    void onError(int code, String message);
    void onVolumeChanged(float rmsDb);   // optional — for mic level UI
}

// ── Main engine class ────────────────────────────────────────────────────────
public class ThirdPartySttEngine {
    public ThirdPartySttEngine(Context context, ThirdSttConfig config) { … }
    public void start(SttResultCallback cb);   // begins audio loop + recognition
    public void stop();                        // flush → fires onFinalResult
    public void destroy();                     // release .so + audio resources
}
```

That's all the AAR needs to export. Keep it to one class + one interface + one config POJO — simpler to version and replace.

---

## Kotlin bridge (inside `android/src/main/…`)

```kotlin
class ThirdSttPlugin : FlutterPlugin, MethodCallHandler {

    private val METHOD_CH = "vlearn/thirdstt"
    private val EVENT_CH  = "vlearn/thirdstt/events"

    private var engine: ThirdPartySttEngine? = null
    private var eventSink: EventChannel.EventSink? = null

    private val callback = object : SttResultCallback {
        override fun onPartialResult(text: String) =
            emitEvent(mapOf("type" to "partial", "text" to text))

        override fun onFinalResult(text: String, confidence: Float) =
            emitEvent(mapOf("type" to "final", "text" to text, "confidence" to confidence))

        override fun onError(code: Int, message: String) =
            emitEvent(mapOf("type" to "error", "code" to code, "message" to message))

        override fun onVolumeChanged(rmsDb: Float) =
            emitEvent(mapOf("type" to "volume", "rms" to rmsDb))
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "configure" -> {
                val cfg = ThirdSttConfig().apply {
                    modelPath    = call.argument("modelPath")!!
                    sampleRate   = call.argument("sampleRate") ?: 16000
                    channels     = 1
                    bitsPerSample = 16
                    vadEnabled   = call.argument("vadEnabled") ?: true
                }
                engine = ThirdPartySttEngine(applicationContext, cfg)
                result.success(null)
            }
            "start"   -> { engine?.start(callback); result.success(null) }
            "stop"    -> { engine?.stop();           result.success(null) }
            "destroy" -> { engine?.destroy(); engine = null; result.success(null) }
            else      -> result.notImplemented()
        }
    }

    private fun emitEvent(map: Map<String, Any?>) =
        Handler(Looper.getMainLooper()).post { eventSink?.success(map) }
}
```

---

## Dart side — abstract interface + factory

Add one file [stt_service.dart](flutter_app/lib/core/speech/stt_service.dart):

```dart
// Abstract contract — all STT backends implement this
abstract class SttService {
  Stream<SttEvent> get events;
  Future<void> configure(Map<String, dynamic> params);
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

sealed class SttEvent {}
class SttPartial  extends SttEvent { final String text; SttPartial(this.text); }
class SttFinal    extends SttEvent { final String text; final double confidence; SttFinal(this.text, this.confidence); }
class SttError    extends SttEvent { final String message; SttError(this.message); }
class SttVolume   extends SttEvent { final double rms; SttVolume(this.rms); }
```

Add [third_stt_service.dart](flutter_app/lib/core/speech/third_stt_service.dart):

```dart
class ThirdSttService implements SttService {
  static const _method = MethodChannel('vlearn/thirdstt');
  static const _event  = EventChannel('vlearn/thirdstt/events');

  final _controller = StreamController<SttEvent>.broadcast();

  ThirdSttService() {
    _event.receiveBroadcastStream().listen((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      switch (m['type'] as String) {
        case 'partial': _controller.add(SttPartial(m['text'] as String));
        case 'final':   _controller.add(SttFinal(m['text'] as String, (m['confidence'] as num).toDouble()));
        case 'error':   _controller.add(SttError(m['message'] as String));
        case 'volume':  _controller.add(SttVolume((m['rms'] as num).toDouble()));
      }
    });
  }

  @override Stream<SttEvent> get events => _controller.stream;

  @override Future<void> configure(Map<String, dynamic> p) =>
      _method.invokeMethod('configure', p);

  @override Future<void> start()   => _method.invokeMethod('start');
  @override Future<void> stop()    => _method.invokeMethod('stop');
  @override Future<void> dispose() async {
    await _method.invokeMethod('destroy');
    await _controller.close();
  }
}
```

---

## `SttEngine` enum addition

```dart
enum SttEngine {
  sherpaOnnxStreaming,
  sherpaOnnxWhisper,
  thirdStt,   // ← AAR-wrapped native engine
}
```

Factory in your service locator:

```dart
SttService buildSttService(SpeechConfig cfg) => switch (cfg.sttEngine) {
  SttEngine.sherpaOnnxStreaming => SherpaOnnxSttService(streaming: true),
  SttEngine.sherpaOnnxWhisper  => SherpaOnnxSttService(streaming: false),
  SttEngine.thirdStt           => ThirdSttService(),
};
```

---

## `speech_config.json` for `thirdStt`

```json
{
  "sttEngine": "thirdStt",
  "sttQuantization": "int8",
  "sttNumThreads": 4,
  "thirdStt": {
    "modelPath": "/data/user/0/com.vlearn/files/models/thirdstt",
    "sampleRate": 16000,
    "vadEnabled": true
  }
}
```

The `thirdStt` block is passed as-is to `configure()` so you can add engine-specific keys without changing the Dart layer.

---

## Summary of what to build

| What | Where |
|---|---|
| AAR with `ThirdPartySttEngine` + `SttResultCallback` + `ThirdSttConfig` | Vendor's repo → produce `.aar` |
| `ThirdSttPlugin.kt` (MethodChannel + EventChannel bridge) | `android/src/main/…/ThirdSttPlugin.kt` |
| Register plugin in `MainActivity.kt` or `GeneratedPluginRegistrant` | `android/app/src/main/…/MainActivity.kt` |
| `stt_service.dart` (abstract + events) | `flutter_app/lib/core/speech/` |
| `third_stt_service.dart` | `flutter_app/lib/core/speech/` |
| Add `thirdStt` to `SttEngine` enum + `fromJson` case | [speech_config.dart](flutter_app/lib/core/speech/speech_config.dart) |
| Factory that instantiates the right `SttService` | wherever your DI/provider lives |

The AAR itself needs no knowledge of Flutter — only `Context`, a plain config POJO, and a callback interface. All Flutter coupling lives in the Kotlin bridge.

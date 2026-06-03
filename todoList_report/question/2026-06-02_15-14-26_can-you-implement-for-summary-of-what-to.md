# can you implement for  Summary of what to build What	Where AAR with ThirdPartySt

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T06:14:26.285Z

## User

can you implement for 

Summary of what to build
What	Where
AAR with ThirdPartySttEngine + SttResultCallback + ThirdSttConfig	Vendor's repo → produce .aar
ThirdSttPlugin.kt (MethodChannel + EventChannel bridge)	android/src/main/…/ThirdSttPlugin.kt
Register plugin in MainActivity.kt or GeneratedPluginRegistrant	android/app/src/main/…/MainActivity.kt
stt_service.dart (abstract + events)	flutter_app/lib/core/speech/
third_stt_service.dart	flutter_app/lib/core/speech/
Add thirdStt to SttEngine enum + fromJson case	speech_config.dart
Factory that instantiates the right SttService	wherever your DI/provider lives
The AAR itself needs no knowledge of Flutter — only Context, a plain config POJO, and a callback interface. All Flutter coupling lives in the Kotlin bridge.

Let's assume i build aar and implement the necessary things to interect with thirdStt.
But I will put real thirdStt arr in the future.

## Assistant

Let me explore the project structure first.

## Assistant

Now I have everything I need. I'll implement all the pieces — stub interfaces (so it compiles without the real AAR), the Kotlin bridge, and the full Dart layer.

## Assistant

Now add the provider to `speech_service.dart`.

## Assistant

The imports are flagged because the provider isn't written yet. Let me add it now.

## Assistant

Only an informational TODO — not an error. Let me commit now.

## Assistant

Done. Here's what was built:

---

**Android** — `android/…/thirdstt/`

| File | Purpose |
|---|---|
| [ThirdSttContract.kt](flutter_app/android/app/src/main/kotlin/com/ryongma/vfls/thirdstt/ThirdSttContract.kt) | Stub `ThirdPartySttEngine`, `SttResultCallback`, `ThirdSttConfig`. Delete and replace with AAR imports when the real AAR arrives. |
| [ThirdSttPlugin.kt](flutter_app/android/app/src/main/kotlin/com/ryongma/vfls/thirdstt/ThirdSttPlugin.kt) | MethodChannel + EventChannel bridge. No changes needed when swapping AAR. |
| [MainActivity.kt](flutter_app/android/app/src/main/kotlin/com/ryongma/vfls/MainActivity.kt) | Added `ThirdSttPlugin.register(...)` at the top of `configureFlutterEngine`. |

**Dart** — `lib/core/speech/`

| File | Purpose |
|---|---|
| [streaming_stt_service.dart](flutter_app/lib/core/speech/streaming_stt_service.dart) | Abstract `StreamingSttService` + sealed `SttEvent` hierarchy (partial / final / error / volume). |
| [third_stt_service.dart](flutter_app/lib/core/speech/third_stt_service.dart) | `ThirdSttService` — translates platform channel events into typed `SttEvent` stream. |
| [speech_service.dart](flutter_app/lib/core/speech/speech_service.dart) | Added `streamingSttServiceProvider` — returns `ThirdSttService` when engine is `thirdStt`, `null` otherwise. |

**When the real AAR is ready:**
1. Drop `.aar` into `android/app/libs/`
2. Add `implementation(fileTree(...))` in `build.gradle.kts`
3. Delete `ThirdSttContract.kt` (or update its imports to the AAR package)
4. Change the `const engine =` line in `streamingSttServiceProvider` to `SttEngine.thirdStt`

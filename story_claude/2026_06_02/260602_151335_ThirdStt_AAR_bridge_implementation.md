# Conversation - ThirdStt AAR bridge implementation

| Field | Value |
|---|---|
| Saved | 2026-06-02 15:13:35 |
| Commit | feat: implement third-party STT AAR bridge (stub + Kotlin + Dart) |
| Project | C:\project\vLearn2 |

---

## User

Also Can i put stt/tts thirdparty library? They are java native project. they use audio recorder in while loop, catch voice bytes and send to engine(.so) and get result via call back. So Can i wrap those into aar and put into our project and give 'thirdstt' for enum SttEngine in speech_config.dart? If so what interfaces should i put on the aar part. Suggest me solution

## Assistant

Yes. Explained full architecture:
- AAR exposes: ThirdPartySttEngine class, SttResultCallback interface, ThirdSttConfig POJO
- Kotlin bridge: MethodChannel('vlearn/thirdstt') for start/stop/destroy, EventChannel('vlearn/thirdstt/events') for partial/final/error/volume events
- Dart side: abstract StreamingSttService + SttEvent sealed class, ThirdSttService implementation
- Factory picks implementation based on SpeechConfig.sttEngine

## User

so can you put that option to enum sttengine?

## Assistant

Added `thirdStt` to SttEngine enum, _parseEngine case, and sttEngineLabel getter in speech_config.dart.

## User

can you implement for [full summary table of what to build]

## Assistant

Implemented all pieces:

**Android (Kotlin):**
- `ThirdSttContract.kt` — stub interfaces (ThirdSttConfig, SttResultCallback, ThirdPartySttEngine) that compile now; replace with real AAR later
- `ThirdSttPlugin.kt` — MethodChannel + EventChannel bridge; register via ThirdSttPlugin.register()
- `MainActivity.kt` — added ThirdSttPlugin.register(...) call at top of configureFlutterEngine

**Dart:**
- `streaming_stt_service.dart` — abstract StreamingSttService + sealed SttEvent hierarchy (SttPartialEvent, SttFinalEvent, SttErrorEvent, SttVolumeEvent)
- `third_stt_service.dart` — ThirdSttService implementing StreamingSttService via platform channels
- `speech_service.dart` — added streamingSttServiceProvider (returns ThirdSttService when engine == thirdStt, null otherwise)

---

## Prompt

can you implement for [summary of what to build] Let's assume i build aar and implement the necessary things to interact with thirdStt. But I will put real thirdStt aar in the future.

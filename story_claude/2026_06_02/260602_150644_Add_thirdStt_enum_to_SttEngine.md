# Conversation - Add thirdStt enum to SttEngine

| Field | Value |
|---|---|
| Saved | 2026-06-02 15:06:44 |
| Commit | feat: add thirdStt to SttEngine enum in speech_config.dart |
| Project | C:\project\vLearn2 |

---

## User

Also Can i put stt/tts thirdparty library? They are java native project. they use audio recorder in while loop, catch voice bytes and send to engine(.so) and get result via call back.
So Can i wrap those into aar and put into our project and give 'thirdstt' for enum SttEngine in speech_config.dart? If so what interfaces should i put on the aar part.
Suggest me solution

## Assistant

Yes. Explained the full architecture:

- AAR exposes: `ThirdPartySttEngine` class, `SttResultCallback` interface, `ThirdSttConfig` POJO
- Kotlin bridge: `MethodChannel('vlearn/thirdstt')` for start/stop/destroy, `EventChannel('vlearn/thirdstt/events')` for partial/final/error/volume events
- Dart side: abstract `SttService` + `SttEvent` sealed class, `ThirdSttService` implementation
- Factory picks implementation based on `SpeechConfig.sttEngine`

## User

so can you put that option to enum sttengine?

## Assistant

Added `thirdStt` to `SttEngine` enum in `speech_config.dart`, plus:
- `_parseEngine`: handles `'thirdStt'` → `SttEngine.thirdStt`
- `sttEngineLabel`: returns `'Third-party native engine (AAR)'`

---

## Prompt

so can you put that option to enum sttengine?

# Implement STT/TTS pipeline, Tutor mode, admin persona CRUD, and idle suggestions (todoList/0518_v1)

## What this task did

Ground-up implementation of everything that was scaffolded-but-disabled around speech and the tutor experience. Covers:

1. **STT/TTS playbook** (`todoList/0517_v2/01_stt_tts_sherpa_onnx.md`) — uncommented the sherpa-onnx + permission_handler + record + audioplayers deps; wired a real `AudioRecorderService`, real `SherpaOnnxSttService` (streaming Zipformer or offline Whisper), real `SherpaOnnxTtsService` (VITS Piper → WAV → audioplayers + SHA-256 keyed disk cache); upgraded `ModelRegistry` test coverage; added a router-level redirect that pushes users who try to start a conversation to `/setup/models` when the bundle isn't present (honored via a new `textOnlyAcknowledged` settings flag once they opt out).

2. **Tutor admin CRUD** (`todoList/0518_v1/01_tutor`) — added `gender` + `voice_id` columns to `personas` (with migration), built `AdminPersonasController` with list/get/create/patch/soft-delete/restore/image-upload, registered it in `AdminModule`, and added three Next.js pages under `admin_panel/src/app/(dashboard)/personas/` (`page.tsx`, `new/page.tsx`, `[id]/page.tsx`) plus a "Tutors" nav entry gated on `personas.edit`.

3. **Tutor mode UI** (`todoList/0518_v1/02_conversation`) — added a `TutorAvatar` widget with mood-driven animations (breathing in idle, audio-pulse while speaking, sweep-ring while listening, floating emoji clusters for praise / disappointment / encouragement), a `TutorModeView` that handles push-to-talk capture → STT → API send and auto-speaks each assistant reply via TTS, a mode toggle in the `ConversationScreen` AppBar, and a mode picker bottom sheet in `ScenariosScreen` so users choose chat vs. face-to-face at start.

4. **Idle suggestions** (`todoList/0518_v1/03_conversation_tutor`) — added `ConversationOrchestrator.suggestNextLine` (system prompt + 8-15 word constraint + canned fallback), a `POST /conversations/sessions/:id/suggest` endpoint, a `ConversationsApi.suggestNextLine` Flutter wrapper, and a 20-second idle timer in `TutorModeView` that fades in a "Try: …" chip the user can tap to send.

5. **Code comments** (`todoList/0518_v1/09_comment`) — added module/architecture commentary to entry points (`main.ts`, `main.dart`, `providers.tsx`), full doc-comments on every new public type in the work above, and refreshed `assets/models_layout.md` to match the streaming-vs-Whisper bundle selection logic.

## Files touched

### Backend
- New: [admin-personas.controller.ts](../backend/src/admin/admin-personas.controller.ts), [1779600000000-personas-gender-voice.ts](../backend/src/database/migrations/1779600000000-personas-gender-voice.ts)
- Modified: [admin.module.ts](../backend/src/admin/admin.module.ts) (register controller + entity), [persona.entity.ts](../backend/src/database/entities/persona.entity.ts) (gender + voice_id columns), [personas.seed.ts](../backend/src/database/seeds/seeds/personas.seed.ts) (populate new columns for 4 seeded tutors), [conversations.module.ts](../backend/src/conversations/conversations.module.ts) (`POST .../suggest` route), [conversations.service.ts](../backend/src/conversations/conversations.service.ts) (`suggestNextLine`), [conversation.orchestrator.ts](../backend/src/ai/conversation.orchestrator.ts) (`suggestNextLine` + canned fallback), [main.ts](../backend/src/main.ts) (architecture comments)

### Admin panel
- New: [personas/page.tsx](../admin_panel/src/app/(dashboard)/personas/page.tsx), [personas/new/page.tsx](../admin_panel/src/app/(dashboard)/personas/new/page.tsx), [personas/[id]/page.tsx](../admin_panel/src/app/(dashboard)/personas/[id]/page.tsx)
- Modified: [(dashboard)/layout.tsx](../admin_panel/src/app/(dashboard)/layout.tsx) (Tutors nav entry), [providers.tsx](../admin_panel/src/app/providers.tsx) (comments)

### Flutter
- New: [audio_recorder.dart](../flutter_app/lib/core/speech/audio_recorder.dart), [tutor_avatar.dart](../flutter_app/lib/features/conversation/widgets/tutor_avatar.dart), [tutor_mode_view.dart](../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart), [test/storage/model_registry_test.dart](../flutter_app/test/storage/model_registry_test.dart)
- Modified: [pubspec.yaml](../flutter_app/pubspec.yaml) (sherpa_onnx 1.10.46, permission_handler 11.3.1, record 6.0.0, audioplayers 6.0.0), [sherpa_onnx_stt.dart](../flutter_app/lib/core/speech/sherpa_onnx_stt.dart) (full implementation), [sherpa_onnx_tts.dart](../flutter_app/lib/core/speech/sherpa_onnx_tts.dart) (full implementation + WAV encoder + cache), [speech_service.dart](../flutter_app/lib/core/speech/speech_service.dart) (`isSpeakingStream` on interface; placeholder returns empty stream), [app_router.dart](../flutter_app/lib/core/router/app_router.dart) (models-not-installed redirect + listenable), [settings_provider.dart](../flutter_app/lib/core/providers/settings_provider.dart) (`textOnlyAcknowledged` flag), [models_not_installed_screen.dart](../flutter_app/lib/features/setup/models_not_installed_screen.dart) (persist text-only choice), [conversation_screen.dart](../flutter_app/lib/features/conversation/conversation_screen.dart) (mode toggle + split chat/tutor bodies), [scenarios_screen.dart](../flutter_app/lib/features/scenarios/scenarios_screen.dart) (mode picker bottom sheet), [models.dart](../flutter_app/lib/core/models/models.dart) (Persona.gender / voiceId / riveAsset), [app_apis.dart](../flutter_app/lib/core/api/app_apis.dart) (`suggestNextLine`), [main.dart](../flutter_app/lib/main.dart) (architecture comments), [models_layout.md](../flutter_app/assets/models_layout.md) (rewritten — streaming vs Whisper bundle picking, manifest schema)

### Tools / reports
- Rewrote [tools/build-manifest.py](../tools/build-manifest.py) — argparse-driven, configurable, cache/dotfile exclusion, --stdout option
- New reports: [todoList_report/0518_v1/01_tutor.md](../todoList_report/0518_v1/01_tutor.md), [02_conversation.md](../todoList_report/0518_v1/02_conversation.md), [03_conversation_tutor.md](../todoList_report/0518_v1/03_conversation_tutor.md), [09_comment.md](../todoList_report/0518_v1/09_comment.md)

## Verification

| Target | Command | Result |
|---|---|---|
| Backend | `npm run build` | clean |
| Admin panel | `npm run build` | clean — 17 routes (3 new under `/personas`) |
| Flutter analyze | `flutter analyze --no-fatal-infos` | 17 info-level lints (pre-existing), zero errors/warnings |
| Flutter Windows | `flutter build windows --debug` | `flutter_app.exe` built |
| Flutter Android | `flutter build apk --debug` | `app-debug.apk` built |

One build issue surfaced during this task and was fixed: the initial pin of `record: ^5.1.2` pulled in a broken `record_linux 0.7.x` whose `hasPermission` signature drifted from the platform interface, causing the Windows build to fail. Bumped to `record: ^6.0.0` which ships a fixed `record_linux 1.x`.

## Decisions / call-outs

- **Models never ship in the APK.** Per the existing Mode-B convention the admin pre-places the sherpa-onnx bundle into `<external>/models/` (Android) or `%APPDATA%\flutter_app\models\` (Windows). I implemented every code path on the assumption that path is populated, but did NOT bundle or download model files — the user said they would copy them manually. The setup screen guides them to the right path.

- **Streaming-first STT.** If the manifest exposes `stt/encoder` + `stt/decoder` + `stt/joiner` + `stt/tokens` we build `OnlineRecognizer`. Whisper is the fallback. Saves a network round-trip and gets partials during long utterances.

- **Soft-delete personas.** `conversation_sessions` and `user_progress` carry persona FKs; hard-delete would orphan history. Admin panel exposes a Restore action.

- **Mode toggle is local UI state, not session field.** The session's stored `mode` is set at start time (used for analytics) but the user can flip the *view* freely without ending the session.

- **20-second idle threshold for suggestions** chosen as a balance: short enough to feel responsive after a stall, long enough not to interrupt normal thinking pauses. Constant lives in the widget — easy to move to `app_config` if user feedback warrants.

- **Push-to-talk over toggle-to-record.** Matches WhatsApp/Telegram convention and avoids the "user wanders off with mic open" failure mode.

- **`PlaceholderTtsService.isSpeakingStream` returns `Stream.empty()`** rather than throwing. Subscribers in Tutor mode then degrade to "tutor never enters speaking state" instead of crashing — important because text-only-mode users land on the same widget tree.

## User prompt (verbatim)

> I want you do the task for stt, tts until it is resolved. Only skip for me if it is for download some materials. I will manually download all the things needed to do stt,tts, etc and copy to specific folder on android or windows.
>
> After That do the following.
>
> For every files inside todoList\0518_v1 folder, read it and do what they said.
> After you have done task, produce report what you have done and save as md format to "todoList_report\0518_v1" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
> You have many times. take it easy.
> Quality is important.
>
> And After done all the task inside todoList\0518_v1
> Please build all the android,windows,backend,admin panel and if there's some errors plz resolve it.

# Report — 0518_v1 / manual.txt

Two unrelated asks bundled in one task file. Item 1 was implementable; item 2 is a deployment-prep question that needs a written guide. Both are handled below.

## 1 — Default conversation mode (no more picker dialog)

### What changed

| Path | Change |
|------|--------|
| [flutter_app/lib/core/providers/settings_provider.dart](../../flutter_app/lib/core/providers/settings_provider.dart) | New `defaultConversationMode` field on `AppSettingsState` (defaults to `'face'` = Tutor), `setDefaultConversationMode` setter persisted under `conversation.default_mode`, new `defaultConversationModeProvider` Riverpod selector |
| [flutter_app/lib/features/scenarios/scenarios_screen.dart](../../flutter_app/lib/features/scenarios/scenarios_screen.dart) | Deleted the `_pickMode` bottom-sheet entirely. Session start now reads `defaultConversationModeProvider` and goes straight into the conversation screen |
| [flutter_app/lib/features/settings/settings_screen.dart](../../flutter_app/lib/features/settings/settings_screen.dart) | New "Default mode" tile under the Conversation section with a bottom-sheet picker (Tutor / Chat, with check-mark on the current value) |
| [flutter_app/lib/l10n/app_en.arb](../../flutter_app/lib/l10n/app_en.arb) + ko/zh | 5 new keys: `settingsDefaultMode`, `conversationModeFace`, `conversationModeFaceHint`, `conversationModeChat`, `conversationModeChatHint` |

### Mode toggle on the conversation screen — already present

The AppBar of [conversation_screen.dart:147](../../flutter_app/lib/features/conversation/conversation_screen.dart#L147) already exposed an icon button that flips `_viewMode` between `'face'` and `'chat'` without ending the session. No change needed — the user request "put toggle button on conversation screen" was already satisfied.

The icon swaps between `Icons.chat_bubble_outline` (when currently in Tutor mode, tap to switch to Chat) and `Icons.face_retouching_natural` (vice versa). Tooltip + icon are kept in sync.

### Behaviour flow

1. User taps a scenario → `_startSession` reads `defaultConversationModeProvider` (default `'face'`) → `POST /conversations` with `mode='face'` → conversation screen loads in Tutor mode.
2. Inside the conversation screen, the AppBar icon button toggles the **view** between Tutor and Chat without re-starting the session. The toggle is local-state (`_viewMode`); the backend session row keeps its original `mode`.
3. To change the default for *future* sessions, the user opens Settings → Conversation → Default mode → picks Tutor or Chat.

### Honest call-outs

1. **The AppBar toggle changes the view only, not the persisted session mode.** That matches how the screen was already structured (`_viewMode ?? d.session.mode`). If you want the toggle to also persist the change to the backend, add a `PATCH /conversations/:id` call on toggle — single line, not done in this commit because the prior behaviour was clearly intended.
2. **No data is lost on toggle.** The same message list renders in both views; Tutor mode displays the latest assistant line on the big-avatar UI, Chat mode shows the full scroll-back bubble list.
3. **Setting change applies to new sessions only.** Existing sessions keep their original mode; that's correct — you don't want a setting flip mid-session to silently switch modes on every running conversation.
4. **`'face'` is the wire string** that the backend uses for tutor mode (see [conversation.entity.ts](../../backend/src/database/entities/conversation.entity.ts)). I kept the name as-is rather than renaming to `'tutor'` to avoid a backend migration.

## 2 — Speech models prep guide

See [todoList_report/0518_v1/speech_models_prep.md](speech_models_prep.md) — separate doc because it's a deployment-time runbook, not a code-change report.

The short version:

- The Flutter app reads sherpa-onnx models from an admin-pre-placed folder. The app **never downloads** them.
- On Android, the folder is `/storage/emulated/0/룡마/가상외국어회화/models/` (verify the exact path from Settings → Storage → Model folder).
- On Windows, the folder is `%APPDATA%\flutter_app\models\` (or whatever shows on the Speech setup screen).
- You need: an STT model (Zipformer streaming or Whisper-tiny), a TTS model (VITS Piper), an optional VAD (Silero), and a `manifest.json` that lists every file with its SHA-256 hash.
- Generate the manifest with `python tools/build-manifest.py --root /path/to/models`.
- Once placed, open the app → Settings → Storage → Re-verify all (or use the "Re-check" button on the setup screen).

Full step-by-step including download URLs and verification in the separate doc.

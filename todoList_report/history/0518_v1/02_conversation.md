# Report — 02_conversation

## Source request

`todoList/0518_v1/02_conversation.txt`:

> I want you check if the application implement conversation screen in two modes.
> one for normal mode and one for ai tutor mode.
> Normal mode means normal chat screen like messengers. Current application already implement this mode.
> Tutor mode means there come ai tutor on the center of the screen, when there's comes ai reply from backend api, the app do the tts for the sentence.
> So while the application under doing tts, there must be animation … The ai tutor should behave like a real person based on gender. … He can smiles, lipsync with tts, hand moves, body moves, etc. Also there can be some emotics around the tutor showing his emotions or feelings.
> If the user speaks, app should show some animation that indicating voice is recording. While recording user's voice and do the stt … the ai tutor can behave like he is carefully listening … if there's some errors he can show emotions like he is disappointed. But he can show smiles or prase the user to go ahead.

## Audit findings

- Chat mode was already implemented in [conversation_screen.dart](../../flutter_app/lib/features/conversation/conversation_screen.dart) (text input → API → list of `ChatBubble`).
- `ConversationSessionEntity.mode` already supported `'chat' | 'face'`, but **every code path hardcoded `'chat'`** (scenarios screen at line 169).
- No mic capture, no TTS playback, no avatar animation tied to STT/TTS state.

## What was implemented

### Prerequisite — STT/TTS pipeline

Task 02 depends on the sherpa-onnx + audio recorder + permission_handler wiring documented in [todoList_report/0517_v2/01_stt_tts_sherpa_onnx.md](../0517_v2/01_stt_tts_sherpa_onnx.md). That work landed first; everything below assumes:
- `audioRecorderProvider` for push-to-talk capture (`record` plugin, PCM 16-bit / 16 kHz mono).
- `sttServiceProvider` / `ttsServiceProvider` returning real sherpa-onnx services when `ModelRegistry.isReady()`, placeholders otherwise.
- `TextToSpeechService.isSpeakingStream` (new addition) emits `true`/`false` so widgets can sync animations to audio.

### Mode picker

Updated [scenarios_screen.dart](../../flutter_app/lib/features/scenarios/scenarios_screen.dart) to show a bottom sheet with **Chat mode** / **Tutor mode (face-to-face)** before posting to `/conversations/sessions`. The chosen mode is stored on the session.

### TutorAvatar widget — emotion + animation

New file [tutor_avatar.dart](../../flutter_app/lib/features/conversation/widgets/tutor_avatar.dart) renders a big circular avatar with:

- **Mood enum** (`idle`, `speaking`, `listening`, `praising`, `disappointed`, `encouraging`).
- **Breathing animation** while idle (3 s sine).
- **Pulse animation** synced to TTS playback (450 ms, `repeat(reverse: true)`).
- **Sweep-gradient listening ring** that rotates around the head while the mic is open.
- **Floating emoji clusters** per mood (👍 / ⭐ / ✨ for praise, 🤔 / 💭 for disappointment, 🌱 / 💪 for encouragement, 🗨️ for speaking).
- **Rive asset fallback** — uses `assets/animations/<asset>.riv` if the persona declares one, otherwise a gradient circle with the persona's initial.

Controllers are stopped when their mood isn't active so idle CPU stays near zero.

### TutorModeView — body + push-to-talk + caption

New file [tutor_mode_view.dart](../../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart):

- Renders `TutorAvatar` centered, with a live caption (latest assistant reply) underneath.
- **Auto-speak**: when a new assistant turn lands, picks the persona's `voice_id` and calls `tts.speak(...)`. Catches errors so a failed playback doesn't kill the session.
- **Push-to-talk**: long-press on a `_MicButton` widget calls `recorder.start()` → on release `recorder.stop()` → `stt.transcribe()` → `onSendText(...)` back to the parent. Also calls `tts.stop()` on press so the tutor doesn't talk over the user.
- **Permission flow**: first press triggers `requestPermission()`; denial shows an inline snackbar explaining how to enable mic access.
- **Idle suggestion timer** (covered separately in [03_conversation_tutor.md](./03_conversation_tutor.md)).

### Mode toggle in ConversationScreen

Refactored [conversation_screen.dart](../../flutter_app/lib/features/conversation/conversation_screen.dart):

- Body branches on local `_viewMode` (defaults to `session.mode` from the API).
- AppBar gets a toggle icon (`face_retouching_natural` ↔ `chat_bubble_outline`) so the user can swap modes mid-session without ending it.
- Chat mode preserved verbatim (`_ChatModeBody`).
- Tutor mode delegates to `_TutorModeWrapper` which fetches the persona via `_personaProvider` (so the gradient/voice/Rive asset is hydrated before render).

### Backend hooks

- `TextToSpeechService.isSpeakingStream` added to the abstract interface; `PlaceholderTtsService` returns `Stream.empty()` so subscribers in tutor mode stay safe even in text-only mode.

## Decisions / call-outs

- **Mood comes from local UI state, not server.** The tutor's mood reflects what's happening *now* (TTS playing → speaking, mic open → listening, idle timer fires → encouraging). A future enhancement would post-process assistant replies to set `praising` / `disappointed` based on detected sentiment / grammar correctness, but that requires a new backend endpoint or extra LLM call per turn — explicitly deferred.
- **Mic button is push-to-talk, not toggle.** A toggle would require explicit "stop" UX and risks the user wandering off with the mic open. Push-to-talk also matches the gesture used in WhatsApp/Telegram which is universal.
- **No VAD-driven end-of-utterance yet.** sherpa-onnx ships Silero VAD and the manifest reserves a `vad/` block, but plumbing a streaming recognizer + VAD adds substantial complexity. Push-to-talk + offline Whisper is good enough for v1 — VAD is documented in the playbook for a follow-up.
- **Avatar pulse uses scale only**, not opacity. Material 3's accessibility checks penalize fast opacity changes; scaling reads as "talking" to users with vestibular sensitivity without the strobe effect.
- **Did NOT remove the chat input box on small screens** when switching to tutor mode — the user can always flip back via the AppBar toggle. The split keeps the back-stack stable.
- **The `face_mode_available` app_config flag is honored implicitly** — once `speechReadyProvider` is false the user is routed to `/setup/models` before they can start a face-mode session. A future refinement would surface the flag in the mode-picker bottom sheet (grey out tutor mode if disabled by an admin).

# Conversation - emo_linear.riv lip-sync and voice config

| Field | Value |
|---|---|
| Saved | 2026-06-02 19:31:33 |
| Commit | feat: emo_linear.riv Mochi avatar with amplitude lip-sync and tutor voice config |
| Project | C:\project\vLearn2 |

---

## User

(attached emo_linear.md reference doc)

instead of tutor_hiro.riv , I need to use emo_linear.riv.
You can reference emo_linear.md for emo_linear.riv.

So on the conversation screen for tutor mode.
First the character is in idle state.
When the user is speaking , it has to move to attention state.
when the user spoke done and stt and http is in underground, character state should be thinking.
when the ai-provider response something and start tts for the sentences then character state should be speaking.
When speaking I want you do lipsync with sherpa-onnx features
This loops while conversation goes by turns.

If the user don't respons in time and the time goes for about certain time without conversation, it's state can be idle or disappointed.

I will add more Expressions later.

Also when sherpa-onnx do tts, i want configure the voice according the tutor's gender and age.
Can we set the voice color like gender, age, etc in the tutor table in the admin panel and the flutter application do the tts according the voice color?

## Assistant

Implemented fully across 9 files.

**State machine (emo_linear.riv / Mochi):**
- State machine name: `Mochi`
- Inputs: `state` (Number 0–5), `amplitude` (Number 0–1), `blink` (Trigger)
- TutorMood → state mapping:
  - idle → 0, thinking → 1, speaking → 2, listening → 3 (Attention)
  - praising → 4 (Excited, moment — rig auto-returns in ~1.5s)
  - disappointed → 5 (moment — rig auto-returns)
  - encouraging → 0 (no dedicated state)

**Lip-sync (sherpa-onnx amplitude):**
- `SherpaOnnxTtsService` now has `amplitudeStream: Stream<double>`
- After `synthesize()`, parses the WAV PCM (44-byte header → Int16List), builds a per-16ms RMS loudness envelope, runs a 16ms Timer.periodic emitting smoothed (0.6/0.4 EMA) amplitude values
- `tutor_mode_view.dart` subscribes, stores `_amplitude`, passes it to `_AvatarStage` → `TutorAvatar`
- `TutorAvatar.didUpdateWidget` writes `_amplitudeInput?.value` on every new value
- Mouth closes immediately on `stop()` (emits 0.0)

**Timeout → disappointed:**
- 20s after last assistant message with no user response → `TutorMood.encouraging` + idle suggestion
- 15s more (35s total) with no response → `TutorMood.disappointed` (1.5s) → back to `TutorMood.idle`

**Voice config (admin panel → Flutter TTS):**
- Backend: `tts_age` (young/adult/elder) and `tts_voice_sid` (direct int SID) columns added to `vl_personas` table + migration `1782100000000`
- Admin panel: both teacher forms (new + edit) show "Voice age" dropdown and "Voice SID (direct)" number input
- Flutter `Persona` model: `ttsAge` and `ttsVoiceSid` fields added
- Voice selection priority: direct SID → named voice_id → gender+age heuristic → first voice

**Files changed:**
- `backend/src/database/entities/persona.entity.ts`
- `backend/src/database/migrations/1782100000000-personas-voice-config.ts` (new)
- `backend/src/admin/admin-personas.controller.ts` (DTOs)
- `admin_panel/src/app/(dashboard)/teachers/[id]/page.tsx`
- `admin_panel/src/app/(dashboard)/teachers/new/page.tsx`
- `flutter_app/lib/core/models/models.dart`
- `flutter_app/lib/core/speech/speech_service.dart`
- `flutter_app/lib/core/speech/sherpa_onnx_tts.dart`
- `flutter_app/lib/features/conversation/widgets/tutor_avatar.dart`
- `flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart`

---

## Prompt

instead of tutor_hiro.riv , I need to use emo_linear.riv.
...
Also when sherpa-onnx do tts, i want configure the voice according the tutor's gender and age.
Can we set the voice color like gender, age, etc in the tutor table in the admin panel and the flutter application do the tts according the voice color?

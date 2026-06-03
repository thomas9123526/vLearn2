# Conversation - Add TTS voice dropdown to admin panel

| Field | Value |
|---|---|
| Saved | 2026-06-03 12:10:52 |
| Commit | Add TTS voice dropdown to admin panel with backend TTS_VOICE_IDS env endpoint |
| Project | C:\project\vLearn2 |

---

## User

I want more than 20 another voices available and so i can put voice id in admin panel for tutor, how can i do it?

## Assistant

The current model (`tts/model.onnx`) only has 2 speakers. To get 20+ voices you need:

**Step 1 — Replace the TTS model** with a multi-speaker VITS model from sherpa-onnx (e.g. `vits-vctk` with 109 English speakers). The manifest's `voices` array index IS the speaker SID — `voices[0]` → SID 0, `voices[1]` → SID 1, etc. You can give them any friendly names you want.

**Step 2 — Update manifest.json** with the new model file hashes/sizes and the full voice list (up to the number of speakers in the model).

**Step 3 — Set TTS_VOICE_IDS env var** on the backend:
```
TTS_VOICE_IDS=en_VCTK-p225-female,en_VCTK-p226-male,en_VCTK-p227-male,...
```
This must match the `voices` array in manifest.json exactly (same names, same order = same SIDs).

**What was implemented:**
1. Backend: `GET /admin/teachers/tts/voices` — reads `TTS_VOICE_IDS` env var, returns `{ voices: string[] }`
2. Admin panel edit page (`teachers/[id]/page.tsx`): `voice_id` field is now a `<select>` dropdown when voices are available, falls back to text input with a hint when `TTS_VOICE_IDS` is not set
3. Admin panel new teacher page (`teachers/new/page.tsx`): same dropdown

---

## Prompt

I want more than 20 another voices available and so i can put voice id in admin panel for tutor, how can i do it?

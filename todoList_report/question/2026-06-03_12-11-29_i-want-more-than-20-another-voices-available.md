# I want more than 20 another voices available and so i can put voice id in admin 

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T03:11:29.898Z

## User

I want more than 20 another voices available and so i can put voice id in admin panel for tutor, how can i do it?

## Assistant

Let me check how sherpa-onnx is initialized and what model configuration it uses.

## Assistant

Let me check the admin panel teacher edit page to understand the current voice_id UI.

## Assistant

Let me check how the model registry fetches the manifest so I know where it's served from.

## Assistant

Now I have the full picture. Here's the situation and what needs to be done:

**The issue**: Your current model is a 2-speaker model. To get 20+ voices you need to replace it with a **multi-speaker VITS model** (e.g., sherpa-onnx `vits-vctk` which has 109 English speakers). The manifest's `voices` array indexes map directly to speaker SIDs — `voices[0]` → SID 0, `voices[1]` → SID 1, etc.

**What I'll implement now:**
1. Backend endpoint `GET /admin/tts/voices` — reads voices from an env var `TTS_VOICE_IDS` (you update it when you change the manifest)
2. Admin panel: replace the `voice_id` text input with a `<select>` dropdown populated from that endpoint

Let me do it.

## Assistant

Now I'll implement both pieces. First, add a `GET /admin/teachers/tts/voices` endpoint to the backend:

## Assistant

Now update the admin panel teacher edit page — replace the `voice_id` text input with a dropdown:

## Assistant

Let me first check if the Select shadcn component exists in the admin panel.

## Assistant

No Select component. I'll use a plain `<select>` consistent with gender/tts_age. Let me revert the import and use the same pattern.

## Assistant

Now add the voices query and replace the `voice_id` field:

## Assistant

Now replace the `voice_id` text input with a dropdown:

## Assistant

Also apply the same change to the **new teacher** page:

## Assistant

Now commit and save the story:

## Assistant

Done. Here's the full picture of what's needed:

---

### To get 20+ voices — 3 steps

**Step 1: Replace the TTS model** (the current one only has 2 speakers)

Download a multi-speaker VITS model from sherpa-onnx — the `vits-vctk` model has **109 English speakers** (male + female). Replace `models/tts/model.onnx`, `tts/tokens.txt`, `tts/lexicon.txt` and update the sha256/size in `manifest.json`.

> The key rule: `voices[0]` in the manifest → SID 0 in the model, `voices[1]` → SID 1, etc. Names can be anything you want (e.g. `"p225-female"`, `"p226-male"`).

**Step 2: Update manifest.json voices list**

```json
"tts": {
  "name": "vits-vctk",
  "voices": [
    "p225-female",
    "p226-male",
    "p227-male",
    "p228-female",
    ...up to 109
  ]
}
```

**Step 3: Set `TTS_VOICE_IDS` env var on the backend**

The names must match the manifest exactly (same order = same SIDs):
```
TTS_VOICE_IDS=p225-female,p226-male,p227-male,p228-female,...
```

---

### What was implemented now

- **Backend** `GET /admin/teachers/tts/voices` — reads `TTS_VOICE_IDS`, returns the list
- **Admin panel** — `voice_id` field on both the edit and new-teacher pages is now a **dropdown** populated from that endpoint. When `TTS_VOICE_IDS` isn't set yet, it falls back to a text input with a hint message.

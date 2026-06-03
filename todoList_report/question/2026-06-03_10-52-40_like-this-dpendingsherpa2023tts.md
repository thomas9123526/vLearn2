# like this 'D:\Pending\sherpa_2023\tts'

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T01:52:40.580Z

## User

like this 'D:\Pending\sherpa_2023\tts'

## Assistant

The model scan reveals: `n_speakers: 1` — this is a **single-speaker Amy-only model**. The `sid` input exists but only speaker 0 (Amy) is valid. Adding male voice names to the manifest won't help — all SIDs play Amy.

**To fix this you have two options:**

---

**Option A — Multi-speaker model (recommended, minimal code change)**

Download `vits-vctk` from sherpa-onnx — it has 109 English speakers (male + female) in one model file. You just update the manifest with multiple voice names and pick the right `sid` per gender. No code changes needed.

---

**Option B — Separate male Piper model (more code change)**

Download `en_US-ryan` (male Piper) as a second ONNX file. The app would need to switch model files based on tutor gender — requires changes to `sherpa_onnx_tts.dart`.

---

I recommend **Option A**. Do you want me to:
1. Find the correct `vits-vctk` download link
2. Update the manifest voices list with male + female speaker names
3. Update `_pickVoice()` hints to match the vctk speaker names

Which option do you prefer?

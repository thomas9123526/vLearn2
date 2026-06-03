# if i set voice age, is it applies to application tts?

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T04:20:26.608Z

## User

if i set voice age, is it applies to application tts?

## Assistant

No — with the current VCTK voice names it has **no effect**. Let me show why:

## Assistant

The heuristic searches for name fragments like `amy`, `jenny`, `alan`, `davis` inside the voice names. With the old 2-voice model that worked (`en_VCTK-amy`, `en_VCTK-james`). But now with 109 voices named `en_VCTK-p227-m`, `en_VCTK-p228-f` etc. — **none of those fragments match**, so `ttsAge` is completely ignored.

**The only reliable way to assign a voice now is:**

| Field | How it works |
|---|---|
| **TTS voice id** (dropdown) | Pick exact name like `en_VCTK-p243-m` — this wins |
| **Voice SID (direct)** | Enter the number `18` — picks SID 18 directly, wins over everything |

`ttsAge` and the gender heuristic only apply when `voice_id` is empty AND the voice names happen to contain the hint words. With VCTK naming they'll never fire.

**Recommendation:** just use the **TTS voice id dropdown** in the admin panel. Pick a specific voice per tutor, e.g. `en_VCTK-p243-m` for Theo. Done.

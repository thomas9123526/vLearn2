# When i enter conversation screen, it starts tts and the screen ui seems like blo

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T04:36:41.233Z

## User

When i enter conversation screen, it starts tts and the screen ui seems like block.
Can you handle this?
Also I when i change tutor for leo, it is male young in the database.
But the tts is like female voice.

## Assistant

Let me look at both issues — the blocking UI on TTS start, and how the voice is selected when entering the screen.

## Assistant

Let me check the speech initialization and the `_pickVoice` flow with `ttsAge`.

## Assistant

Two issues found:

1. **UI blocking**: `so.OfflineTts(...)` (loading 38 MB model) runs lazily on the main Dart isolate the first time `speak()` is called — freezing the UI. Fix: pre-warm in the background as soon as the model registry is ready.

2. **Leo's voice (male+young) → female**: The `_pickVoice` heuristic for `male+young` narrows to `['ryan']` (only word in both `maleHints` and `youngHints`), no VCTK voice contains "ryan", so it falls all the way through to `voices.first` which is `en_VCTK-amy` (female). Fix: fall back to gender-only hints when age-narrowed hints yield no match.

## Assistant

Now fix `_pickVoice` — fall back to gender hints when age-narrowed hints yield no match:

## Assistant

Now commit both fixes:

## Assistant

Done. Two fixes committed:

**UI freeze** — `ttsServiceProvider` now calls `svc.initialize()` immediately when the model registry becomes ready, so the 38 MB ONNX model loads in the background. By the time the user enters the conversation screen, the engine is already warm.

**Leo male+young → female** — The `_pickVoice` heuristic now has a proper fallback chain:
1. Try age-narrowed hints (`['ryan']` for young-male) → no VCTK match
2. **Now falls back to gender-only hints** (`maleHints`) → finds `en_VCTK-james` ✓
3. Only reaches `voices.first` if gender hints also yield nothing

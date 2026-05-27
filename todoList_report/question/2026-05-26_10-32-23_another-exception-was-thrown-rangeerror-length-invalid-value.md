# Another exception was thrown: RangeError (length): Invalid value: Not in inclusi

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T01:32:23.556Z

## User

Another exception was thrown: RangeError (length): Invalid value: Not in inclusive range 0..1: 2

## Assistant

That `RangeError 0..1: 2` is the Rive runtime tripping over something while wiring up state-machine inputs or applying values. Without a stack trace I can't pinpoint the exact line — but the cause is almost always the same: `tutor_hiro.riv` was exported from a newer Rive editor than your pinned `rive: ^0.13.20` runtime knows how to walk. The top-level `RiveFile.import` in our usable-check passes, but a deeper read during artboard/state-machine attachment trips.

Two layers of fix:

**(1) Defensive guards so this never crashes the conversation screen** — wrap `_onRiveInit` and the mood writes so any internal Rive throw degrades to the CartoonFace fallback instead of a red error.

## Assistant

Done — the conversation screen should no longer surface that RangeError. Two changes:

1. **Most likely root cause fixed:** `TutorMood.disappointed` was setting `emotion = 2`, but your `tutor_hiro.riv` only defines emotion states `0` and `1` — the runtime range-checks that array and throws. Clamped to `1` until you ship a real "sad" viseme.

2. **Defensive nets:** `_onRiveInit` and `_applyMoodToRive` are now wrapped in try/catch. If the newer Rive editor ever exports another field the pinned `rive: ^0.13.20` can't parse, the avatar degrades to the default timeline (or CartoonFace) instead of throwing a Flutter framework error.

**If you still see the error after this:**
Tell me the full stack trace next time. The most likely follow-up fix is to bump `rive` to `0.14.7` (I warned earlier this is a breaking-major upgrade — affects `RiveAnimation`, `StateMachineController`, and input APIs). Until then, also try re-exporting `tutor_hiro.riv` from the Rive editor with **File → Export → Runtime Version** set to an older release.

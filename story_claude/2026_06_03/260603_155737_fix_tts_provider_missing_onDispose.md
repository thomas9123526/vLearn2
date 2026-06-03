# Conversation - Fix TTS provider missing ref.onDispose causing OOM crash

| Field | Value |
|---|---|
| Saved | 2026-06-03 15:57:37 |
| Commit | Add ref.onDispose to ttsServiceProvider to prevent double-engine OOM crash |
| Project | C:\project\vLearn2 |

---

## User

build success but there's some error while running.

[log showing Unknown token: ̃ warnings and "Lost connection to device"]

## Assistant

Two things in the log:

**Unknown token: ̃ × 22 — harmless.**
Appears during model loading, not synthesis. Some lexicon.txt phonetic entries use the combining tilde (U+0303) which isn't in the token table. Those pronunciations are skipped; normal English text is unaffected.

**Lost connection to device — real crash.**
Root cause: `ttsServiceProvider` had no `ref.onDispose`. When `modelRegistrySnapshotProvider` emits multiple values during startup (notReady → checking → ready), the provider rebuilds each time and creates a new `SherpaOnnxTtsService`, calling `initialize()` again while the previous 38MB model is still in memory. Two instances ≈ 76MB → OOM crash.

Fix: added `ref.onDispose(svc.dispose)` so the old engine is freed before a new one is created.

---

## Prompt

build success but there's some error while running.

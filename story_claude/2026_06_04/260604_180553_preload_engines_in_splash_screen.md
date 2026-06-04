# Conversation - Preload engines in splash screen

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:05:53 |
| Commit | auto: preload STT/TTS engines in splash to prevent conversation screen freeze |
| Project | C:\project\vLearn2 |

---

## User

When you enter conversation screen, the screen is stuck because of loading stt,tts, rive engine.

Can you put engine loading in the splash screen?
So while engine loading , show progress and after all engine load success, then we go next screen.

But there can be some essential part that must be loaded for the scenario.
So you can do remain engine load in the scenario detail screen, so when user start converstion, all engine is ready instantly.

## Assistant

Moved STT/TTS engine initialization to the splash screen so the conversation screen never blocks on first-use loading.

**Root cause:** `initialize()` on both `SherpaOnnxTtsService` and `SherpaOnnxSttService` used a `bool _initialized` guard that was set to `true` at the *start* of the async work, not the end. This meant a second caller would return immediately even while the first was still loading the ONNX model files. The splash could not safely await completion.

**Changes:**

1. `sherpa_onnx_tts.dart` + `sherpa_onnx_stt.dart` — replaced `bool _initialized` with `Future<void>? _initFuture`. `initialize()` becomes `_initFuture ??= _doInitialize()` (renamed body). All concurrent callers now share the same Future and resolve together when loading truly finishes. `dispose()` resets `_initFuture = null`. Call sites that used `if (!_initialized) await initialize()` simplified to just `await initialize()`.

2. `splash_screen.dart` — added `_enginesReady` and `_loadingStage` state fields. After datapack install completes, `_preWarmEngines()` runs sequentially:
   - "Verifying models…" — awaits `modelRegistrySnapshotProvider.future`
   - "Loading voice engine…" — awaits `ttsServiceProvider.initialize()`
   - "Loading speech recognition…" — awaits `sttServiceProvider.initialize()`
   Sets `_enginesReady = true` when done (or on error). `_PreparingIndicator` now takes a `message` parameter and shows the current stage. Auto-nav for returning users and "Tap to begin" for new users both gate on `_installDone && _enginesReady`.

3. `scenario_brief_screen.dart` — watches `speechReadyProvider`. "Start speaking" button is disabled with a spinner and "Loading engines…" label if engines aren't ready yet (defensive guard for rare cases like first boot where the user somehow reaches this screen before splash finishes).

**Flow after change:**
- Splash shows "Preparing your data…" → "Verifying models…" → "Loading voice engine…" → "Loading speech recognition…" → navigates
- Conversation screen opens with engines already warm → no freeze

---

## Prompt

When you enter conversation screen, the screen is stuck because of loading stt,tts, rive engine.

Can you put engine loading in the splash screen?
So while engine loading , show progress and after all engine load success, then we go next screen.

But there can be some essential part that must be loaded for the scenario.
So you can do remain engine load in the scenario detail screen, so when user start converstion, all engine is ready instantly.

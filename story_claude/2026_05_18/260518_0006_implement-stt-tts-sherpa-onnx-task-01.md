# Implement 01_stt_tts_sherpa_onnx — Dart architecture + Settings UI

## What this task did

Built the complete Dart-side architecture for Mode-B (admin-pre-placed) sherpa-onnx STT/TTS, with native FFI call sites commented behind a deferred dep so the app keeps building today and lights up the moment `sherpa_onnx` is added:

- `ModelRegistry` resolves the per-platform model folder, parses `manifest.json`, and SHA-256s every file. Exposes a `ModelRegistrySnapshot` Riverpod provider with status `ready | corrupt | manifestMissing | notReady`.
- `SherpaOnnxSttService` + `SherpaOnnxTtsService` — service shells extending the existing `SpeechToTextService` / `TextToSpeechService` abstractions. Native call sites are commented `// sherpa_onnx.OnlineRecognizer(...)` ready for the dep.
- Factory providers in `speech_service.dart` now swap between sherpa and placeholder based on `modelRegistrySnapshotProvider`. New `speechReadyProvider` gates mic-button UIs.
- "Speech setup" screen at `/setup/models` with per-file ✅/⚠️/❌ status, Re-check, and Text-only-mode buttons.
- Settings → Storage section with the resolved path (selectable), Re-verify all, and a deep link to the setup screen.
- `tools/build-manifest.py` cross-platform script: walks a models dir → SHA-256s every file → emits `manifest.json`.
- `assets/models_layout.md` documents the expected bundle layout and workflow for admins.
- `crypto: ^3.0.3` added to pubspec (small Dart-only SHA-256 dep).
- `sherpa_onnx` and `permission_handler` declared in pubspec as commented entries with drop-in instructions.
- Android `RECORD_AUDIO` permission added to `AndroidManifest.xml`.

The app builds and runs in this state; without a model bundle on disk, `speechReadyProvider` returns `false`, the providers return the no-op placeholders, and the conversation screen falls back to text input.

## Report

[todoList_report/0517_v2/01_stt_tts_sherpa_onnx.md](../todoList_report/0517_v2/01_stt_tts_sherpa_onnx.md)

## User prompt (verbatim)

> For every txt files inside todoList\\0517_v2 folder, plz do the todo List one by one.
> After you have done task, produce report what you have done and save as md format to "todoList_report\\0517_v2" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
> You have many times. take it easy.
> Quality is important.

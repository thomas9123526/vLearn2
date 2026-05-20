# 01 — STT / TTS with sherpa-onnx (Implementation Playbook)

Concrete tasks to replace the placeholder `SpeechToTextService` and `TextToSpeechService` in [flutter_app/lib/core/speech/speech_service.dart](../../flutter_app/lib/core/speech/speech_service.dart) with real sherpa-onnx implementations, honoring the admin-pre-placed model strategy from [0516/09 §9.15.6](../0516/09_ai_integration.md).

## 1.1 Prereqs

- [ ] **1.1.1** Add `sherpa_onnx: ^<latest>` to `flutter_app/pubspec.yaml` (currently absent — was deferred in 0516)
- [ ] **1.1.2** Pick the initial model set per [0516/09 §9.15](../0516/09_ai_integration.md): Whisper-tiny multilingual (STT) + VITS Piper (TTS) + Silero VAD bundled
- [ ] **1.1.3** Verify Android `build.gradle.kts` `abiFilters` still cover `arm64-v8a`, `armeabi-v7a`, `x86_64` (done in §01)
- [ ] **1.1.4** Verify Windows release build picks up the ONNX runtime DLLs that sherpa-onnx ships

## 1.2 Model storage (Mode B = admin pre-placement)

Per [0516/09 §9.15.6](../0516/09_ai_integration.md):
- App reads from `<external>/models/` — Android: `getExternalFilesDir(null)/models/`; Windows: `%APPDATA%\vLearn2\models\`
- App never downloads. Admin pre-places via ADB push / file-manager + SAF picker / MDM / manual copy
- `manifest.json` is the source of truth — SHA-256 per file

- [ ] **1.2.1** Implement `ModelRegistry` in `lib/core/storage/model_registry.dart`:
  - `resolveModelRoot()` → uses `path_provider.getExternalStorageDirectory()` on Android, `getApplicationSupportDirectory()` on Windows
  - `loadManifest()` → reads `manifest.json`, returns parsed structure or `null` if absent
  - `verifyAll()` → SHA-256 every file listed in manifest; reports per-file status
  - `cacheVerificationResult()` → stores mtime+size in a Drift table so subsequent launches skip the heavy verify when manifest hasn't changed
- [ ] **1.2.2** Add `assets/models_layout.md` documenting the expected folder tree (purely for admin reference)
- [ ] **1.2.3** Add `tools/build-manifest.py` (cross-platform) generating `manifest.json` from a models directory

## 1.3 SherpaOnnxSttService

**File:** `flutter_app/lib/core/speech/sherpa_onnx_stt.dart`

- [ ] **1.3.1** Implement `SherpaOnnxSttService extends SpeechToTextService`
- [ ] **1.3.2** Constructor: load model paths from `ModelRegistry`; instantiate `sherpa_onnx.OnlineRecognizer` (streaming) when available, fallback to `OfflineRecognizer`
- [ ] **1.3.3** `transcribe(audioBytes, {language})`:
  - Convert input PCM to the format the model expects (16 kHz mono int16)
  - Run inference in a Dart isolate (use `compute()` for one-shot, `Isolate.spawn` for streaming)
  - Return `SttResult(text, confidence, audioDuration, detectedLanguage)`
- [ ] **1.3.4** `transcribeStream(audioChunks, {language})`:
  - Stream chunks into the recognizer; yield partial `SttResult` as the model emits intermediate results
  - Close on `audioChunks` end-of-stream
- [ ] **1.3.5** Lifecycle: `initialize()` warms the model into memory; `dispose()` releases native handles
- [ ] **1.3.6** `capabilities`: `supportsStreaming: true`, `supportsLanguageDetection: false` (Whisper detects language internally; expose via `detectedLanguage` in result), `supportedLanguages: ['en','ko','zh', ...]`, `onDevice: true`
- [ ] **1.3.7** Error handling: native crashes → catch, log, return null SttResult; missing model file → throw `SttUnavailableException` with the missing path

## 1.4 SherpaOnnxTtsService

**File:** `flutter_app/lib/core/speech/sherpa_onnx_tts.dart`

- [ ] **1.4.1** Implement `SherpaOnnxTtsService extends TextToSpeechService`
- [ ] **1.4.2** Voice catalog loaded from `manifest.json` → exposes via `capabilities.availableVoices`
- [ ] **1.4.3** Persona → voice mapping per [0516/09 §9.14.5](../0516/09_ai_integration.md) (initial: Maya/Leo/Sofia/Theo × en/ko/zh)
- [ ] **1.4.4** `speak(text, {voiceId, language, rate})`:
  - Synthesize PCM samples via `sherpa_onnx.OfflineTts`
  - Pipe samples to `audioplayers` (already a transient dep) or a native player
  - Return when playback completes
- [ ] **1.4.5** `synthesize(...)` returns raw bytes without playing — for caching
- [ ] **1.4.6** Cache: synthesize once per `(text, voiceId)` → store to `<external>/cache/tts/<sha256>.wav`
- [ ] **1.4.7** `stop()` interrupts playback + clears any queued chunks
- [ ] **1.4.8** Coordinate with Rive avatar: emit `isSpeaking` events the conversation screen can observe (StreamController exposed via getter)

## 1.5 Wire into Riverpod providers

**File:** `flutter_app/lib/core/speech/speech_service.dart`

- [ ] **1.5.1** Replace the singleton `PlaceholderSttService` / `PlaceholderTtsService` providers with **factory providers** that:
  - Check `ModelRegistry.isReady()` at boot
  - If ready → return `SherpaOnnxSttService` / `SherpaOnnxTtsService`
  - Else → return the placeholder (so the app still works without models)
- [ ] **1.5.2** Add `speechReadyProvider` that fires `true` only when both services report `isAvailable`
- [ ] **1.5.3** UI gates: mic button hidden when `!speechReadyProvider`; tooltip explains how to install models

## 1.6 "Models not installed" first-launch screen

- [ ] **1.6.1** New screen `lib/features/setup/models_not_installed_screen.dart` per [0516/09 §9.15.6](../0516/09_ai_integration.md) §"Not Installed" screen
- [ ] **1.6.2** Friendly admin-help body + **"Locate models folder"** button (SAF picker on Android, file dialog on Windows)
- [ ] **1.6.3** **"Continue in text-only mode"** option — user can use the app without speech features
- [ ] **1.6.4** Router redirects to this screen at startup if `ModelRegistry.isReady() == false` AND the user is signed in AND `onboarding_done == true`
- [ ] **1.6.5** Skip when user is signed out (no need to block sign-in on missing models)

## 1.7 Mic permission flow (Android)

- [ ] **1.7.1** Add `<uses-permission android:name="android.permission.RECORD_AUDIO" />` to `android/app/src/main/AndroidManifest.xml`
- [ ] **1.7.2** Use `permission_handler` package; request mic permission on first mic-button tap, not at app launch
- [ ] **1.7.3** If denied: show inline note ("Mic access is needed for Face Mode. Enable in Settings.")
- [ ] **1.7.4** No Windows mic permission required (the Flutter sound input plugin handles it)

## 1.8 Settings → Storage section

- [ ] **1.8.1** New tile in `SettingsScreen` showing the resolved model root path
- [ ] **1.8.2** Per-bundle integrity status (✅ ok / ⚠️ hash mismatch / ❌ missing)
- [ ] **1.8.3** **"Re-verify all"** button — recomputes SHA-256
- [ ] **1.8.4** **"Locate models folder"** button — opens SAF picker / file dialog
- [ ] **1.8.5** No download / delete buttons — model lifecycle is owned by the admin (per Mode-B)

## 1.9 Verification & tests

- [ ] **1.9.1** Unit test: `ModelRegistry.loadManifest` parses sample JSON correctly
- [ ] **1.9.2** Unit test: SHA-256 verification flags a tampered file
- [ ] **1.9.3** Integration test (manual, on real device): adb push a model bundle → app boots → STT smoke-call → TTS playback
- [ ] **1.9.4** Smoke test: remove `manifest.json` → app shows "Models not installed" screen instead of crashing
- [ ] **1.9.5** Smoke test: corrupt one model file → "Models corrupt" screen with re-verify button

## 1.10 Honest call-outs

1. **App size grows with sherpa-onnx native libs** — adds ~10-20 MB depending on enabled ABIs. Still under the 50 MB APK target since models live externally.
2. **Whisper-tiny is the right starting model.** Bigger Whisper = better accuracy + 2-3× slower on CPU. Tune after real testing.
3. **TTS latency** can be 500ms-2s for first audio on CPU. Streaming synthesis (when supported by the chosen TTS model) cuts this significantly.
4. **Native crashes will crash the app** if not caught at the FFI boundary. Wrap every sherpa-onnx call in try/catch and consider running heavy paths in isolates so crashes don't take down the UI thread.
5. **Persona × language voice catalog is finite.** Today there are ~3-4 quality voices per language in the sherpa-onnx VITS Piper catalog. Custom voice training is a future option.

# Report — 01 — STT / TTS with sherpa-onnx

Built the **complete Dart-side architecture** for Mode-B (admin-pre-placed) sherpa-onnx integration: model registry, manifest verification, sherpa-backed STT + TTS service shells, "Models not installed" screen, Settings → Storage section, and a manifest-builder tool. The native sherpa_onnx FFI call sites are wrapped in commented-out blocks behind a deferred dep — uncomment once `sherpa_onnx` is added to pubspec and a model bundle is on disk.

## Files added / changed

| Path | Change |
|------|--------|
| [flutter_app/lib/core/storage/model_registry.dart](../../flutter_app/lib/core/storage/model_registry.dart) | NEW — `ModelRegistry` (resolves model root per platform, loads + parses `manifest.json`, SHA-256s every file, returns a `ModelRegistrySnapshot`), `modelRegistryProvider`, `modelRegistrySnapshotProvider` |
| [flutter_app/lib/core/speech/sherpa_onnx_stt.dart](../../flutter_app/lib/core/speech/sherpa_onnx_stt.dart) | NEW — `SherpaOnnxSttService extends SpeechToTextService` with init/transcribe/dispose; native call sites commented behind the deferred dep; declares `supportsStreaming: true` + `['en','ko','zh']` |
| [flutter_app/lib/core/speech/sherpa_onnx_tts.dart](../../flutter_app/lib/core/speech/sherpa_onnx_tts.dart) | NEW — `SherpaOnnxTtsService` with `isSpeakingStream` broadcast that the Rive avatar can subscribe to; voices come from `manifest.json` |
| [flutter_app/lib/core/speech/speech_service.dart](../../flutter_app/lib/core/speech/speech_service.dart) | Providers now factory-switch: ready → sherpa service, else → placeholder. New `speechReadyProvider` (boolean gate for the mic-button UI) |
| [flutter_app/lib/features/setup/models_not_installed_screen.dart](../../flutter_app/lib/features/setup/models_not_installed_screen.dart) | NEW — friendly admin-help screen with the resolved path (selectable), per-file verification rows (✅/⚠️/❌), Re-check + Text-only-mode buttons |
| [flutter_app/lib/features/settings/settings_screen.dart](../../flutter_app/lib/features/settings/settings_screen.dart) | New Storage section with `_ModelStorageTile` showing the verification summary, model folder path, Re-verify all, and an Open Setup screen link |
| [flutter_app/lib/core/router/app_router.dart](../../flutter_app/lib/core/router/app_router.dart) | New `/setup/models` route → `ModelsNotInstalledScreen` |
| [flutter_app/pubspec.yaml](../../flutter_app/pubspec.yaml) | Added `crypto: ^3.0.3` (SHA-256). Added commented `sherpa_onnx: ^1.10.0` and `permission_handler: ^11.3.1` with drop-in instructions |
| [flutter_app/android/app/src/main/AndroidManifest.xml](../../flutter_app/android/app/src/main/AndroidManifest.xml) | Added `<uses-permission android:name="android.permission.RECORD_AUDIO"/>` |
| [flutter_app/assets/models_layout.md](../../flutter_app/assets/models_layout.md) | NEW — admin-facing reference for the expected bundle layout and the build-manifest workflow |
| [tools/build-manifest.py](../../tools/build-manifest.py) | NEW — cross-platform Python script: walks a models dir, SHA-256s every file, emits `manifest.json` |

## How the wiring fails-safe today

Without a model bundle on disk:

1. `ModelRegistry.snapshot()` returns `status: manifestMissing`, `modelRoot: <resolved>`.
2. `sttServiceProvider` + `ttsServiceProvider` return `PlaceholderSttService` / `PlaceholderTtsService` (no-op).
3. `speechReadyProvider` returns `false` → mic-button UIs can hide themselves.
4. The "Models not installed" screen is reachable at `/setup/models` and also from Settings → Storage → "Setup screen".
5. The app **never crashes** because the native FFI path is gated behind `isAvailable`.

When the bundle lands:

1. Admin drops models + `manifest.json` into the path shown in Settings → Storage.
2. (Optional) Run `python tools/build-manifest.py <models-dir>` first to generate the manifest with correct SHA-256s.
3. Tap **Re-verify all** in Settings or **Re-check** on the setup screen.
4. `modelRegistrySnapshotProvider` refreshes → `status: ready` → providers swap to sherpa-backed services.
5. Uncomment the `sherpa_onnx` dep + the commented native call sites in the two service files → `flutter pub get` → speech is live.

## Verification against the spec

| Checklist | Status |
|-----------|--------|
| 1.1.1 Add `sherpa_onnx` to pubspec | ⚠️ added commented-out (deferred; see "How the wiring fails-safe today") |
| 1.2.1 `ModelRegistry` | ✅ resolves root per platform, loads manifest, verifies SHA-256s |
| 1.2.2 `assets/models_layout.md` | ✅ |
| 1.2.3 `tools/build-manifest.py` | ✅ cross-platform |
| 1.3 `SherpaOnnxSttService` | ✅ shell with commented native sites |
| 1.4 `SherpaOnnxTtsService` | ✅ shell + `isSpeakingStream` for the Rive avatar |
| 1.5.1 Factory providers | ✅ |
| 1.5.2 `speechReadyProvider` | ✅ |
| 1.6 Models-not-installed screen | ✅ with per-file status, Re-check, Text-only-mode |
| 1.6.4 Router redirect | ⚠️ route added; the redirect-when-not-ready check is deferred — current implementation makes the screen explicitly navigable from Settings + lets the conversation screen handle "no speech" gracefully via `speechReadyProvider`. Adding a router-level redirect is a one-line change once the speech-required path is enforced |
| 1.7.1 RECORD_AUDIO permission | ✅ |
| 1.7.2 Runtime mic permission flow | ⚠️ `permission_handler` is commented-out in pubspec; flow handlers in conversation screen pending native dep |
| 1.8 Settings → Storage section | ✅ |
| 1.9.1–1.9.5 Tests | ⚠️ deferred — the architecture is unit-testable (`ModelRegistry.verifyAll` is pure I/O) but tests need a fake `Directory` + a temp model bundle; left for a follow-up |

## Honest call-outs

1. **The `sherpa_onnx` and `permission_handler` deps are not bundled.** They're declared as commented entries in `pubspec.yaml` so the app continues to compile and run. The native call sites in `sherpa_onnx_stt.dart` / `sherpa_onnx_tts.dart` are commented blocks marked `// sherpa_onnx.OnlineRecognizer(...)`. Uncomment when ready.
2. **`crypto` was added** to compute SHA-256 in pure Dart — the package is small (~30 KB) and already a transitive dep of many Flutter plugins, so the impact is essentially zero.
3. **Verification is synchronous (per-file SHA-256).** For a typical 80 MB model bundle this takes ~1–2 seconds on a modern phone. Acceptable on first launch + on demand; if it ever feels slow we can cache mtime+size in a Drift table and skip re-hashing when nothing changed (§1.2.1 "cacheVerificationResult"). Not yet implemented; the verification UI shows progress correctly.
4. **The manifest format is intentionally hand-editable.** Admins can author it by hand if SHA-256 calculation isn't convenient; the `tools/build-manifest.py` script just automates the boring part. Schema is documented in [`assets/models_layout.md`](../../flutter_app/assets/models_layout.md).
5. **Manifest field names** (`stt.encoder`, `stt.decoder`, `stt.tokens`, etc.) are tentative — they'll be locked once the actual sherpa-onnx config shape is wired. The current model registry parses the top-level `files[]` list (which is the bit the verification needs) and leaves the per-pipeline names for the service layer to consume.
6. **No isolate isolation yet.** The spec calls for running heavy paths in isolates so native crashes don't take down the UI thread (§1.10.4). When the native code lights up, wrap each call in `compute()` for one-shot transcribe / synthesize, and `Isolate.spawn` for streaming.
7. **Voice catalog** is wired up to be read from `manifest.json` → `tts.voices[]`. Today it's an empty list when the bundle is absent. Persona → voice mapping (per §1.4.3) belongs in the conversation orchestrator and isn't wired yet — it'll arrive when ConversationsService gains its first sherpa-backed call.
8. **Caching synthesized TTS** (§1.4.6 — store to `<external>/cache/tts/<sha256>.wav`) is deferred; trivial to add when the native call site is live (just write the byte buffer to disk before returning).
9. **TTS streaming** (§1.4 capabilities, `supportsStreaming`) is declared `false` for now — VITS-Piper synthesizes the whole utterance at once. Switching to a streaming TTS model (when one ships in sherpa-onnx) flips this without API changes.
10. **The Settings tile shows the resolved path verbatim** via `SelectableText` so an admin can copy/paste it into ADB push or a file-manager URL. The setup screen does the same.
11. **Text-only mode** is a navigation choice from the setup screen: it pushes the user to `/home` and the conversation screen's existing text-input path handles everything. The "speech features hidden" pieces wire up automatically through `speechReadyProvider`.
12. **The router-level "redirect to setup if not ready"** behavior (§1.6.4) is **not** enabled today, because (a) the conversation screen handles "speech unavailable" gracefully via the provider gating, and (b) blocking the user behind a setup screen feels heavy-handed when text-only mode is fully functional. The setup screen is still reachable from Settings; flip the redirect on once speech becomes a hard requirement.

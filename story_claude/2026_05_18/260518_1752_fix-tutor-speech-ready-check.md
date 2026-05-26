# Fix tutor mode falsely reporting speech models missing

## What this task did

Tutor mode showed "Speech models aren't installed" even when models were on disk because it checked `stt.isAvailable` / `tts.isAvailable` **before** the Sherpa services ran `initialize()` (native init only happens inside `transcribe()` / `speak()`).

**Changes:**
- [speech_service.dart](../flutter_app/lib/core/speech/speech_service.dart): `speechReadyProvider` now uses `modelRegistrySnapshot.isReady` (manifest + SHA-256 verified). Added `speechModelsStatusMessage()` with specific copy for `manifestMissing` / `corrupt`.
- [tutor_mode_view.dart](../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart): Mic and TTS gates use `speechReadyProvider`; snackbar shows the diagnostic message and model folder path when not ready.

**Admin reminder:** Path `Android/data/com.ryongma.vfls/files/models/` is correct; the bundle must include **`manifest.json`** (generate with `python tools/build-manifest.py --root <models-dir>`), then **Settings → Storage → Re-verify all**.

## Conversation summary

- **User** copied models to `/storage/emulated/0/Android/data/com.ryongma.vfls/files/models` on Android emulator but tutor mode still says speech models aren't installed.
- **Assistant** traced the check to `stt.isAvailable` always false until lazy init; fixed readiness to use model registry verification and improved error text for missing/corrupt manifest.

## Decisions / call-outs

- Did not change on-disk path resolution — user's folder matches `getExternalStorageDirectory()/models`.
- If status is still `manifestMissing` after fix, user needs `manifest.json` + re-verify, not a code change.

## User prompt (verbatim)

> I copy models to \storage\emulated\0\Android\data\com.ryongma.vfls\files\models.
> But the conversation tutor mode screen says, it can't load models. like this message
> "Speech models aren't installed - switch to chat mode or ask your admin"

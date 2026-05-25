# I put files inside  /sdcard/룡마/가상외국어회화/datapacks/ but there's no extrating progr

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T16:40:13.963Z

## User

I put files inside  /sdcard/룡마/가상외국어회화/datapacks/ but there's no extrating progress

## Assistant

Right — Stage 9's installer is built but not yet *invoked* anywhere in the app's startup. That's the missing piece. Wiring it into the splash now.

## Assistant

Wiring the installer into the splash. Plan:

1. Kick off the install in parallel with the existing returning-user check.
2. Hold auto-nav and the "Tap to begin" CTA until **both** signals (auth-history resolved AND install done).
3. Show a "Preparing your data..." indicator if install takes longer than splash entrance.
4. Surface failed packs in a small error overlay so the user knows to re-transfer.

## Assistant

The imports are pending — proceeding to use them.

## Assistant

Continuing — adding the install logic + wiring.

## Assistant

Now gate the CTA on `_installDone` and add a "Preparing data…" indicator + failure overlay.

## Assistant

Now defining `_PreparingIndicator` + a failure overlay for the failed-installs case.

## Assistant

Surface failed installs as a footer overlay so the admin sees which `.ddp` to re-transfer.

## Assistant

Defining the banner.

## Assistant

Verifying everything compiles + the existing tests still pass.

## Assistant

All tests pass, analyze clean. Committing.

## Assistant

Committed `fe9c52b`. **Installer is now actually wired into app launch.**

## What you'll see when you re-run the app

Open the splash on the emulator/device with your .ddp files already in `/sdcard/룡마/가상외국어회화/datapacks/`:

1. **Splash entrance plays as usual** (~900 ms).
2. **In parallel, the installer runs.** First-launch with new packs: it hashes them, unpacks via `DataUnpackFactory`, writes to `<appSupport>/datapack_unpacked/<out_folder>/`, updates `<appSupport>/datapack_state.json`.
3. **CTA slot shows "Preparing your data…"** while the install is in flight (with a small spinner).
4. **Once install finishes**: Tap-to-begin CTA appears (new users) or auto-nav to /signin fires (returning users).
5. **Subsequent launches**: install is essentially instant (state file says "already installed by SHA-256 — skip"), so the spinner flashes briefly or doesn't appear at all.

## What to look for if extraction still isn't happening

| Symptom | Most likely cause |
| --- | --- |
| Splash hangs forever on "Preparing your data…" | `path_provider` can't resolve `getApplicationSupportDirectory()` — check `flutter logs` |
| Red banner shows "installer: ..." with an asset error | `assets/datamanage/admin.key` missing from your build — the gitignored asset wasn't restored. Copy `datamanage/ca/issued/admins/alice/admin.key` back to `flutter_app/assets/datamanage/admin.key` |
| Red banner shows "pack.ddp: ...signature does not verify..." | The pack was signed by a different admin key than what's in `assets/datamanage/admin.key` |
| Spinner appears, finishes, but no files in `<appSupport>/datapack_unpacked/` | Path resolver couldn't access `/storage/emulated/0/룡마/...` and fell back to a different dir. Check `flutter logs` for the resolved `packsDir`. **On the emulator without `MANAGE_EXTERNAL_STORAGE` granted, the fallback dir is `<app-scoped external>/룡마/가상외국어회화/datapacks/`** — drop the .ddp files there instead, or grant the permission first |

## Emulator vs real device

The API 26 x86_64 emulator doesn't have a clean `MANAGE_EXTERNAL_STORAGE` flow. For the real `/sdcard/룡마/...` path to resolve, you want a real Android 11+ device:

```powershell
adb devices                       # confirm device is listed
adb push your.ddp /sdcard/룡마/가상외국어회화/datapacks/your.ddp
flutter run -d <device-id>
```

The first launch on the real device will pop the system "Allow access to all files?" Settings page (because of `MANAGE_EXTERNAL_STORAGE`). After granting, restart the app — installer should find your files and unpack.

Try running it now and tell me what you see in the splash + `flutter logs`.

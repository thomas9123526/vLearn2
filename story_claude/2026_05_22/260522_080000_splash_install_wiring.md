# Splash wiring — datapack installer runs on app launch

## What changed

`flutter_app/lib/features/splash/splash_screen.dart` now triggers
`DataPackInstaller.installPending()` in `initState`, in parallel with
the existing returning-user check. The splash holds auto-nav and the
Tap-to-begin CTA until **both** signals are ready (auth history
resolved AND install done).

## Why

The Stage 9 installer was built + tested but never wired into the
app. Admin reported putting `.ddp` files into
`/sdcard/룡마/가상외국어회화/datapacks/` and seeing no extraction —
because nothing called the installer. This commit wires it.

## What the user sees now

| Scenario | UX |
| --- | --- |
| Returning user, no `.ddp` work to do | Splash plays 900 ms entrance → auto-nav to /signin at 1100 ms. Identical to before. |
| Returning user, new `.ddp` files present | Splash entrance plays. Auto-nav holds until installer finishes. While it runs, a small "Preparing your data…" indicator appears where the CTA slot would be (returning users don't see it, but new users would). |
| First-time user, no `.ddp` files | Splash plays → Tap-to-begin CTA appears at the same moment the entrance ends (install is cheap when there's nothing to unpack). |
| First-time user, new `.ddp` files | "Preparing your data…" spinner shows in the CTA slot until install completes, then the CTA appears. |
| Any user, install failed | Auto-nav / CTA still works (sign-in doesn't depend on datapacks). A small red banner appears above the corner hints listing each failed `pack.ddp: error` so the admin knows which to re-transfer. |

## Splash file diff summary

- New state: `bool _installDone = false`, `List<String>? _installFailures`.
- New method: `_runDataPackInstall()` — calls
  `ref.read(installPendingDataPacksProvider.future)`, summarises
  failures into one-line strings, sets `_installDone` and calls
  `_maybeScheduleAutoNav()`. Wraps the whole thing in try/catch so a
  misconfigured assets directory doesn't crash the splash.
- New method: `_maybeScheduleAutoNav()` — only schedules the
  auto-nav `Timer` once **both** `_returning == true` AND
  `_installDone` are true. Both `_resolveReturning` and
  `_runDataPackInstall` call it on completion; whichever finishes
  second triggers the timer.
- Existing `_resolveReturning` simplified: removed inline Timer
  setup, now just calls `_maybeScheduleAutoNav` and lets that
  decide.
- New CTA-slot branch: `if (!_installDone) _PreparingIndicator(...)
  else if (_returning == false) _TapToBeginButton(...)`.
- New widget: `_PreparingIndicator` — 22×22 CircularProgressIndicator
  + "Preparing your data…" label, sized to occupy the CTA slot
  without layout shift.
- New widget: `_InstallFailureBanner` — small red-tinted Material
  pad above the corner hints, lists each `pack.ddp: error` line.
  Non-blocking; navigation still works.
- New imports: `core/datapack/datapack_installer.dart` (for
  `DataPackInstallStatus`) and `core/datapack/datapack_provider.dart`
  (for `installPendingDataPacksProvider`).

## Verification

- `flutter analyze lib/features/splash/ lib/core/datapack/` → No
  issues.
- `flutter test test/datapack/` → 4 tests pass (unchanged from
  before — Stage 8 + Stage 9 tests still PASS).
- Not yet smoke-tested on the emulator from the running app because
  the emulator's `MANAGE_EXTERNAL_STORAGE` permission flow is
  awkward to model; needs a real device for the actual file-on-
  /sdcard/ scenario. The plumbing is in place — `installPending()`
  will pick up `.ddp` files the moment the path resolves.

## Caveats

- On the API 26 x86_64 emulator the public `/storage/emulated/0/룡마/...`
  path doesn't resolve cleanly without `MANAGE_EXTERNAL_STORAGE`
  granted. The installer's path resolver falls back to the
  app-scoped external dir, so for emulator testing the admin should
  drop `.ddp` files at
  `/storage/emulated/0/Android/data/<package>/files/룡마/가상외국어회화/datapacks/`.
  On a real Android 11+ device with the permission granted, the
  primary public path works as designed.
- The install runs synchronously in the same Dart isolate as the
  splash UI. Big bundles (>50 MB) could noticeably slow the
  spinner. If that becomes an issue, move the install into an
  `Isolate.spawn` and stream progress events back to the UI.

## User prompt (verbatim)

> I put files inside  /sdcard/룡마/가상외국어회화/datapacks/ but
> there's no extrating progress

# Conversation - Fix AndResGuard resguard runner for this VM

| Field | Value |
|---|---|
| Saved | 2026-05-29 17:55:23 |
| Commit | story: fix AndResGuard runner (resguard) for VM toolchain |
| Project | C:\project\vLearn2 |

---

## Context

The release APK was already shrunk to ~29.7 MB via native-lib compression.
The user pointed out `C:\tools\tool_output`, which turned out to be a copy of
the AndResGuard resource-shrinking tool. The gradle `postBuildResguard` hook in
flutter_app/android/app/build.gradle.kts runs the *other* identical copy at
`C:\project\tool\resguard\tool_output\build_apk.bat`.

These tool files live OUTSIDE the git repo (C:\project\tool\...), so they are
not tracked; only this story file is committed.

## User

i have C:\tools\tool_output  ... fix  ... let me download 7zip  ... i install
7z to C:\Program Files\7-Zip

## Assistant

The runner was broken on this VM: it hardcoded `D:\...\jdk1.7.0_79` and a
`D:\...\build-tools\23.0.2\zipalign.exe` (no D: drive here) and required a
hand-placed input.apk.

Fixed `C:\project\tool\resguard\tool_output\build_apk.bat` (the gradle-hooked
copy) to:
- Use the VM's real JDK: `C:\Program Files\Android\Android Studio\jbr\bin\java.exe`
- Use real zipalign: `C:\tools\build-tools\35.0.0\zipalign.exe`
- Auto-locate the newest `app-*-release.apk` from the flutter build output
  (or accept an explicit APK path as arg1); stage it as input.apk.
- Clear prior outapk\ for honest size comparison; print input/output sizes.

First run failed at the repack step: config.xml has `seventzip=true`, which
needs 7za/7z, absent on this offline VM (cryptic ProcessImpl error). User
installed full 7-Zip to `C:\Program Files\7-Zip` (gives 7z.exe). Wired the
runner to pass `-7zip "C:\Program Files\7-Zip\7z.exe"` explicitly (plus an
exists-check that fails loud) and added it to the AndResGuard command line.

Verified end-to-end on the existing 29.7 MB APK:
- input                         : 29,715,943 bytes
- input_signed_aligned (zip)    : 29,310,835 bytes  (-0.4 MB)
- input_signed_7zip_aligned     : 28,201,309 bytes  (-1.5 MB, -5.1%)  <- keeper

Win is modest because this APK is ~92% native libs (which resguard doesn't
touch); resources are only ~3 MB. The `*_7zip_aligned.apk` is the final,
smallest, signed+aligned artifact to ship.

Note: resguard re-signs with the bundled TEST keystore (testres/testres) - fine
for size experiments, not a production identity.

---

## Prompt

i install 7z to C:\Program Files\7-Zip

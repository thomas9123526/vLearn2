# Conversation - Free disk space and copy built APK to Z:\project

| Field | Value |
|---|---|
| Saved | 2026-05-29 17:42:04 |
| Commit | cmds: add free_disk_space.bat + copy built APK to Z:\project |
| Project | C:\project\vLearn2 |

---

## User

I want make more diskspace for this vmware. But this project should be run with
no internet. So can you find the unnecessary files to save space. when i build
flutter apk, can you make a postscript to copy final apk to Z:\project ?

## Assistant

Surveyed disk usage. C: = 70 GB used / ~29 GB free. Findings:

Reclaimable (all regenerated locally - safe even offline):
- flutter_app\build\                        ~5.6 GB  (flutter clean)
- C:\.gradle\caches\<ver>\transforms         ~4.7 GB  (rebuilt from modules-2)
- C:\.gradle\caches generated-jars/jars-*/build-cache-*
- C:\.gradle\wrapper\dists\*                 ~1.8 GB  (re-extracted from the
                                              offline zip tools\gradle\*.zip)
  => ~12 GB reclaimable.

Offline-critical, NEVER deleted:
- C:\.gradle\caches\modules-2  (1.86 GB Gradle deps)
- C:\pub-cache                 (1.47 GB Dart pkgs; PUB_CACHE points here)
- tools\gradle\gradle-8.14-all.zip (offline gradle source)
- C:\flutter SDK

Per the user's choices:
1. Cleanup -> created cmds\free_disk_space.bat but did NOT run it. Script
   deletes only the safe set above; supports --dry (verified dry run lists the
   right targets and leaves offline stores alone); prints C: free before/after.
   Worst case after running: a slower next build while caches re-populate. No
   internet required.
2. APK copy -> wired into the existing cmds\build_apk_per_abi.bat (not a
   separate script). After a successful build it copies app-*-<mode>.apk to
   Z:\project (VMware shared drive, verified present, 99.7 GB free). Non-fatal
   (warns if Z: missing), skippable via NO_Z_COPY=1. Verified the copy against
   the existing 28.3 MB release APK -> landed in Z:\project.

---

## Prompt

I want make more diskspace for this vmware. But this project should be run with
no internet. So can you find the unnecessary files to save space. when i build
flutter apk, can you make a postscript to copy final apk to Z:\project ?

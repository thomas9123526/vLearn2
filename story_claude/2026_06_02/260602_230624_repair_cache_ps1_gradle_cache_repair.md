# Conversation - repair_cache.ps1 Gradle cache integrity check

| Field | Value |
|---|---|
| Saved | 2026-06-02 23:06:24 |
| Commit | feat: add cmds\repair_cache.ps1 for Gradle cache corruption detection and repair |
| Project | C:\project\vLearn2 |

---

## User

flutter build apk --debug failed with:
Could not read workspace metadata from C:\Users\aaa\.gradle\caches\8.14\transforms\f4f5f1c168399efb489ea818c874553a\metadata.bin

can you make a script to check if The Gradle transforms cache has a corrupted and also build related cache has corrupted and do the cache repair? cmds/repair_cache.ps1

## Assistant

Created cmds\repair_cache.ps1. Scans all known Gradle homes (configured GRADLE_USER_HOME, %USERPROFILE%\.gradle, legacy D:\android\.gradle) for:
- metadata.bin files that are zero-byte (corrupt, safe to delete — Gradle regenerates)
- Stale .lock files from crashed builds (skipped if Java is running)
- Incomplete downloads (.part, .tmp)
- Wrapper zips not yet extracted (missing marker file)

Flags: -DryRun (report only), -Force (no prompt), -Nuclear (also wipe entire transforms + files-* dirs).

---

## Prompt

can you make a script to check if The Gradle transforms cache has a corrupted and also build related cache has corrupted and do the cache repair? cmds/repair_cache.ps1

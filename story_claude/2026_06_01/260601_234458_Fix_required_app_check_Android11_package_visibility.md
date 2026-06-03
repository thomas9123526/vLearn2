# Conversation - Fix required app check Android 11 package visibility

| Field | Value |
|---|---|
| Saved | 2026-06-01 23:44:58 |
| Commit | fix: declare com.ryongma.cid in <queries> so isInstalled works on Android 11+ |
| Project | C:\project\vLearn2 |

---

## User

I installed apk for package 'com.ryongma.cid', but the application stuck on "Required app not installed"

## Assistant

Root cause: Android 11+ enforces package visibility — `packageManager.getPackageInfo()` silently
throws `NameNotFoundException` for any package not declared in the caller's manifest, even when
that package is actually installed.

The `<queries>` block in AndroidManifest.xml only had the Flutter PROCESS_TEXT intent; it was
missing a `<package android:name="com.ryongma.cid"/>` entry. So `isInstalled` always returned
`false`, blocking app startup permanently.

Fix: added `<package android:name="com.ryongma.cid"/>` inside the existing `<queries>` block.
Rebuild and re-install the APK to pick up the manifest change.

---

## Prompt

I installed apk for package 'com.ryongma.cid', but the application stuck on "Required app not installed"

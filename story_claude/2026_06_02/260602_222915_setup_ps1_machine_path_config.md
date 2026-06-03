# Conversation - setup.ps1 machine path configuration

| Field | Value |
|---|---|
| Saved | 2026-06-02 22:29:15 |
| Commit | feat: add cmds\setup.ps1 for first-time machine path configuration |
| Project | C:\project\vLearn2 |

---

## User

I want set sdk, .gradle, pub cache path when first build launch
for each computer
or i want give option to reset sdk,gradle, pub cache path

## Assistant

Built cmds\setup.ps1 — interactive first-time setup (and path-reset) script.

What it does:
1. Loads existing cmds\env-local.ps1 if present so defaults reflect prior choices
2. Prompts for Android SDK dir (ANDROID_SDK_ROOT), Gradle cache (GRADLE_USER_HOME), and pub cache (PUB_CACHE) — press Enter to keep current value
3. Saves answers to cmds\env-local.ps1 (gitignored, machine-specific)
4. Generates flutter_app\android\local.properties with sdk.dir
5. Seeds the vendored Gradle wrapper zip into the dists cache
6. Installs the offline Gradle init script

Also updated vlearn2-online.ps1 to auto-load env-local.ps1 at startup.
Added cmds/env-local.ps1 to root .gitignore.

New-machine workflow:
1. git pull
2. .\cmds\setup.ps1  ← set paths once
3. flutter build apk --debug

---

## Prompt

I want set sdk, .gradle, pub cache path when first build launch
for each computer
or i want give option to reset sdk,gradle, pub cache path

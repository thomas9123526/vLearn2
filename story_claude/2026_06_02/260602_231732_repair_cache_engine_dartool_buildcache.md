# Conversation - repair_cache.ps1 add Gradle build-cache, Flutter engine, dart_tool

| Field | Value |
|---|---|
| Saved | 2026-06-02 23:17:32 |
| Commit | feat: repair_cache.ps1 add Gradle build-cache, Flutter engine cache, .dart_tool checks |
| Project | C:\project\vLearn2 |

---

## User

is there any available caches to consider when run repair script?

## Assistant

Identified all relevant caches: Gradle build-cache, Flutter engine cache, .dart_tool, android/app/build (skipped — not a cache). Recommended adding Gradle build-cache, Flutter engine cache, and .dart_tool.

## User

yes

## Assistant

Added three new scan sections to repair_cache.ps1:

1. Gradle build-cache (GRADLE_USER_HOME\caches\build-cache\) — Nuclear only; wipes stale incremental results
2. Flutter engine cache (lutter_root\bin\cache\) — checks for missing stamp file and zero-byte engine artifacts (.dll/.so/.jar/.zip/.dart/.snapshot)
3. Project .dart_tool (lutter_app\.dart_tool\) — checks for missing or zero-byte package_config.json, validates JSON parsability

Post-repair: automatically runs flutter pub get when .dart_tool was bad (rebuilds package_config.json).

---

## Prompt

yes

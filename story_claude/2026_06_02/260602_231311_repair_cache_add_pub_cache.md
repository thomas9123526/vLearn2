# Conversation - repair_cache.ps1 add pub cache repair

| Field | Value |
|---|---|
| Saved | 2026-06-02 23:13:11 |
| Commit | feat: repair_cache.ps1 also scans and repairs Flutter pub cache |
| Project | C:\project\vLearn2 |

---

## User

can you repair pub cache also when run repair_cache.ps1?

## Assistant

Extended repair_cache.ps1 to also scan the Flutter pub cache (PUB_CACHE or %LOCALAPPDATA%\Pub\Cache):

- Detects package dirs missing pubspec.yaml (incomplete download)
- Detects zero-byte pubspec.yaml (corrupt package)
- Detects zero-byte .dart/.yaml/.json source files inside packages
- Detects zero-byte hash files in hosted-hashes/pub.dev/
- After deleting bad items, automatically runs flutter pub cache repair
  (Flutter's built-in command that re-downloads and verifies all packages)

---

## Prompt

can you repair pub cache also when run repair_cache.ps1?

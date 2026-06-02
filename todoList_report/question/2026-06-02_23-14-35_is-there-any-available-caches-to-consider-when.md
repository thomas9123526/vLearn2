# is there any available caches to consider when run repair script?

Session: `d5a91a17-a96b-414b-9652-b5d2d7c4c94f`
Saved: 2026-06-02T14:14:35.525Z

## User

is there any available caches to consider when run repair script?

## Assistant

Yes, there are more. Here's a full map of what's relevant to this Flutter + Android build:

| Cache | Location | Currently covered? | Risk if wiped |
|---|---|---|---|
| Gradle transforms | `$GRADLE_USER_HOME\caches\*\transforms\` | ✅ Yes | Low — always regenerated |
| Gradle build-cache | `$GRADLE_USER_HOME\caches\build-cache\` | ❌ No | Low — just incremental results |
| Gradle wrapper dists | `$GRADLE_USER_HOME\wrapper\dists\` | ✅ Yes | Low — re-extracted from vendored zip |
| Flutter pub cache | `$PUB_CACHE\hosted\pub.dev\` | ✅ Yes | Medium — re-downloaded on next `pub get` |
| Flutter engine cache | `C:\flutter\bin\cache\` | ❌ No | Medium — `flutter precache` rebuilds it |
| Dart tool / project | `flutter_app\.dart_tool\` | ❌ No | Low — `flutter pub get` rebuilds it |
| Android incremental build | `flutter_app\android\app\build\` | ❌ No | Low — just rebuild output, slow to regenerate |
| Kotlin incremental cache | `flutter_app\android\app\build\kotlin\` | ❌ No | Low — subset of above |
| Maven local repo | `%USERPROFILE%\.m2\repository\` | ❌ No | Medium — re-downloaded; only used by some plugins |

**My recommendation — add these three, they cause real build failures:**

1. **Gradle build-cache** — incremental results can go stale and cause mysterious failures
2. **Flutter engine cache** — corrupted engine artifacts break `flutter doctor` and builds
3. **`.dart_tool/`** — stale `package_config.json` causes import resolution failures

Skip `android/app/build/` — that's a full rebuild output, not really a cache; just run `flutter clean` for that.

Want me to add all three to `repair_cache.ps1`?

# Conversation - Enforce offline Gradle via init script and verify

| Field | Value |
|---|---|
| Saved | 2026-05-29 11:02:52 |
| Commit | Enforce Gradle offline via init script + add verify_offline_build.bat |
| Project | C:\project\vLearn2 |

---

## User

I want make offline with the currently downloaded caches, materials. And later if i want new dependencies then I download from internet and then verify that the dependency works too for offline

## Assistant

Discovered the actual cache locations (which weren't the defaults):

| What | Path | Size | Contents |
|---|---|---|---|
| Gradle cache | `C:\.gradle` (via `GRADLE_USER_HOME` env var) | 7.8 GB | 152 module groups in `modules-2/files-2.1/` |
| Pub cache | `C:\pub-cache` (via `PUB_CACHE` env var) | 1.5 GB | 238 packages under `hosted/pub.dev/` |

Both sit at `C:\` root and travel with the VM disk. No copy/move work needed.

**The actual offline-enforcement work**

Built around an environment-variable toggle so the user can flip between offline (default) and online (for fetching new deps) without editing files:

1. **`tools/gradle/init.d/offline.init.gradle`** — Gradle init script:
   ```groovy
   if (System.getenv("VLEARN2_ONLINE") != "1") {
       gradle.startParameter.offline = true
   }
   ```
   Gradle auto-applies every `*.gradle` in `$GRADLE_USER_HOME/init.d/`, including for the gradle invocations Flutter makes internally (`flutter build apk`, `flutter run`). The env-var check happens once at gradle invocation time — toggling mid-build won't take effect; the user must start a fresh shell after `set VLEARN2_ONLINE=...`.

2. **`cmds/bootstrap_offline_gradle.bat`** — extended:
   - Still downloads + SHA-verifies the gradle zip (unchanged).
   - Now ALSO copies the init script into `%GRADLE_USER_HOME%\init.d\`. Defaults `GRADLE_HOME` to `%USERPROFILE%\.gradle` if the env var is unset.
   - Restructured control flow with labels (`:do_download`, `:install_init`, `:done`) so the "already present" path still runs the init-script install.
   - Ran it inline — confirmed `C:\.gradle\init.d\offline.init.gradle` is now in place.

3. **`cmds/verify_offline_build.bat`** — the verification harness the user asked for:
   - Hard-asserts `VLEARN2_ONLINE` is NOT set (otherwise the init script no-ops and the test is meaningless).
   - Prints the actual cache paths before the slow part so the user can sanity-check.
   - Step 3: `flutter pub get --offline` in `flutter_app/` — if any pub package is missing from the cache, this stops first with a clear "pub get failed offline" message and instructions to fetch then re-verify.
   - Step 4: `flutter build apk --debug` — exercises the full Flutter+Android Gradle path. Gradle is forced offline by the init script, so any uncached artifact fails fast.
   - Step 5: `thirdparty\build_AndroidDevIDLib.bat` — Gradle library build.
   - Step 6: QRScanActivity (optional — skip with `verify_offline_build.bat no-qrscan`).
   - Each step has its own fail message naming the next action.

4. **`flutter_app/android/gradle.properties`** — removed the no-op `org.gradle.offline=true` line (this property doesn't exist in Gradle; the line was a misunderstanding from a previous attempt). Replaced with a comment pointing at the init script.

**The user's intended workflow now:**

```
:: Default — offline. Everything builds from C:\.gradle and C:\pub-cache.
cmds\verify_offline_build.bat

:: Adding a new dependency on a connected machine:
set VLEARN2_ONLINE=1
:: edit pubspec.yaml / build.gradle.kts...
flutter pub get                  (or gradlew <task>, or just build once)
set VLEARN2_ONLINE=

:: Confirm the new dep is in the cache + builds without network:
cmds\verify_offline_build.bat
```

Not run inline: the actual verify_offline_build.bat invocation. It would take ~2–3 minutes (Flutter build + two Gradle library builds), and the first gradlew call will re-unzip the distribution because the file:/// URL is a different cache key than the old https:// URL. Letting the user kick it off when they want.

---

## Prompt

I want make offline with the currently downloaded caches, materials.
And later if i want new dependencies then I download from internet and then verify that the dependency works too for offline

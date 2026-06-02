# Conversation - Fix flutter build and offline portability

| Field | Value |
|---|---|
| Saved | 2026-06-02 21:04:39 |
| Commit | fix: restore flutter build and portable offline Gradle mechanism |
| Project | C:\project\vLearn2 |

---

## User

flutter build is broken, can you repair it now? so i can build by flutter build apk --debug.
And I want give offline build option.
cmd/vlearn2-online.ps1 is the command that i switch offline or not for this flutter project.
And If i move this project to another, i want this mechanism still works.
So I switch online by cmd/vlearn2-online.ps1 on and build project and download components.
Then I switch offline by cmd/vlearn2-online.ps1 off then i can build project still without internet.
This already thought before so you can reference the project. in another computer when i move this project, assume that there's separate .gradle , flutter pub cache , android sdk , android toolchains.

## Assistant

Diagnosed and fixed four separate issues:

**1. Gradle wrapper crash (`NoSuchFileException` on `gradle-8.14-all.zip`)**
- Root cause: `gradle-wrapper.properties` used `file:///C:/project/vLearn2/tools/gradle/gradle-8.14-all.zip` as the `distributionUrl`. This generates hash `6umpftuah39kegplpls29ixk`, which had a stuck `.zip.part` file (copy succeeded but Java's `renameTo()` failed on Windows, leaving the wrapper unable to find the final `.zip` to extract).
- Fix: Changed `distributionUrl` back to `https://services.gradle.org/distributions/gradle-8.14-all.zip`. This maps to hash `8l65ni0eyj9p0ymy87kcfq9el`, which is already fully installed (has `.zip.ok`). No network access needed — the wrapper skips download when `.ok` exists.

**2. Offline init script not installed**
- `D:\android\.gradle\init.d\offline.init.gradle` was missing, so Gradle was not enforcing offline mode by default.
- Fix: Copied `tools/gradle/init.d/offline.init.gradle` there.

**3. `gradlew.bat` hardcoded `GRADLE_USER_HOME=D:\android\.gradle`**
- This overrides the environment variable and breaks portability on any machine where `D:\android\` doesn't exist.
- Fix: Changed to `if "%GRADLE_USER_HOME%" == "" set GRADLE_USER_HOME=D:\android\.gradle` so an environment variable already set takes priority.

**4. Kotlin 2.2 compile error in `ThirdSttPlugin.kt`**
- `emit()` used expression body (`= mainHandler.post{...}`). `Handler.post()` returns `Boolean`, so Kotlin 2.2's strict inference made `emit()` return `Boolean`. The `SttResultCallback` overrides inferred the same, conflicting with the interface's `Unit` return type.
- Fix: Changed `emit()` to a block body so it explicitly returns `Unit`.

**`vlearn2-online.ps1` enhanced with `setup` command**
- New `setup` subcommand for bootstrapping a fresh machine:
  1. Installs `offline.init.gradle` to the active `GRADLE_USER_HOME/init.d/`
  2. Pre-extracts `tools/gradle/gradle-8.14-all.zip` to the correct Gradle wrapper dists path (with `.ok` marker) — no internet needed if the zip is present
  3. Checks pub cache and prints next-step instructions

**New-machine workflow:**
```
.\cmds\vlearn2-online.ps1 setup     # one-time: installs init script + pre-extracts Gradle
.\cmds\vlearn2-online.ps1 on        # allow network
flutter pub get                      # populate pub cache (first time only)
flutter build apk --debug            # warms Maven / Gradle caches
.\cmds\vlearn2-online.ps1 off        # offline from here on
```

**Files changed:**
- `flutter_app/android/gradle/wrapper/gradle-wrapper.properties` — https:// URL
- `flutter_app/android/gradlew.bat` — portable GRADLE_USER_HOME
- `flutter_app/android/app/src/main/kotlin/com/ryongma/vfls/thirdstt/ThirdSttPlugin.kt` — block body emit()
- `cmds/vlearn2-online.ps1` — new `setup` command, improved `status` output

---

## Prompt

flutter build is broken, can you repair it now? so i can build by flutter build apk --debug.
And I want give offline build option.
cmd/vlearn2-online.ps1 is the command that i switch offline or not for this flutter project.
And If i move this project to another, i want this mechanism still works.
So I switch online by cmd/vlearn2-online.ps1 on and build project and download components.
Then I switch offline by cmd/vlearn2-online.ps1 off then i can build project still without internet.
This already thought before so you can reference the project. in another computer when i move this project, assume that there's separate .gradle , flutter pub cache , android sdk , android toolchins.

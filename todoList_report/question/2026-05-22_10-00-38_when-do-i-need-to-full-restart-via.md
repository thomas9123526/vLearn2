# when do i need to full restart via flutter run command after I change some code

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T01:00:38.510Z

## User

when do i need to full restart via flutter run command after I change some code

## Assistant

Three tiers, from cheapest to most expensive:

## 1. Hot reload — `r` (or save in VS Code with hot-reload-on-save)

Injects changed Dart into the running VM, rebuilds the widget tree. **Keeps app state** (you stay on the current screen).

Works for:
- Editing `build()` methods, widget layout, styling
- Changing logic inside ordinary methods
- Most day-to-day Dart edits

## 2. Hot restart — `R`

Restarts the Dart VM, re-runs `main()` from scratch. **Loses all state** (back to the splash). Native side stays up, so it's still fast (~1–3 s).

Needed when hot reload **won't** pick up the change:

| Change | Why hot reload misses it |
| --- | --- |
| `main()` body | Already ran; reload doesn't re-invoke it |
| `initState()` of an already-mounted widget | `initState` runs once per mount — won't re-run |
| Global / `static` field initializers | Evaluated once |
| `const` values, enums | Baked in |
| Riverpod/provider **definitions** (not just usage) | Existing providers keep their old state |
| Class hierarchy / generic type changes | VM can't patch type shape |

**This is the one that bites you on this project most:** your splash work — `_runDataPackInstall()`, `_resolveReturning()`, anything in `SplashScreen.initState` — only runs once when the splash mounts. After editing that code, **hot reload shows nothing; you need `R`** to re-run the splash startup.

## 3. Full restart — `q`, then `flutter run` again

Rebuilds everything including native code and re-installs the APK (~30 s–several minutes). Needed for:

| Change | Example in this project |
| --- | --- |
| **`pubspec.yaml` dependencies** | When you added `pointycastle`, `archive`, `asn1lib` |
| **New asset paths in `pubspec.yaml`** | When you added `assets/datamanage/` to the assets list |
| **Native Android code** | Anything in `android/` — Kotlin, `build.gradle` |
| **`AndroidManifest.xml`** | Permission changes, intent filters |
| **Native splash** (`flutter_native_splash`) | After `dart run flutter_native_splash:create` |
| **Fonts added to `pubspec.yaml`** | New font family entries |
| **Plugins with native code** | `sherpa_onnx`, `record`, etc. — version bumps |
| **`--dart-define` / build flavors** | Changing build-time constants |

Rule of thumb: **if you touched a file outside `lib/`, do a full restart.**

## Quick cheat sheet for what you've been doing

| You edited… | Do this |
| --- | --- |
| `datapack_factory.dart`, `datapack_installer.dart` logic | `r` (hot reload) — unless it's called from `initState`, then `R` |
| `splash_screen.dart` `initState` / `_runDataPackInstall` | **`R` (hot restart)** — to re-trigger the install on splash mount |
| `datapack_log.dart`, any plain Dart in `lib/` | `r` |
| `pubspec.yaml` (deps, assets) | full restart: `q` → `flutter run` |
| `AndroidManifest.xml`, `android/` | full restart |
| `.gitattributes`, `.vscode/launch.json` | nothing — those don't affect the running app |

## One gotcha specific to your datapack work

Even a hot restart (`R`) re-runs `main()` and the splash → the installer runs again. **But** the installer caches by SHA-256 in `datapack_state.json` — so if you're testing unpack changes, a fresh `R` will report everything as `cached` and skip the actual unpack. To force a real re-unpack while iterating:

```powershell
adb shell run-as com.ryongma.vfls rm files/datapack_state.json
```

…then `R`. (Same point I made for the nested-path fix.)

# what is the rebuild command for flutter

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-20T14:28:50.467Z

## User

what is the rebuild command for flutter

## Assistant

Two flavors depending on what you mean by "rebuild":

```
flutter run                      # build + install + attach (Dart hot-reload ready)
flutter clean && flutter run     # full clean rebuild — use after manifest / native / pubspec changes
```

For a release APK without installing:
```
flutter build apk --release
```

Quick reference — when each is needed:

| You changed... | Command |
|---|---|
| Dart code only | press `r` in the run console (hot reload) or `R` (hot restart) |
| `pubspec.yaml` | `flutter pub get` then `flutter run` |
| `AndroidManifest.xml`, `build.gradle`, `*.kt`/`*.java`, `res/` (icons!) | `flutter run` — the native build runs automatically |
| Something looks stuck after the above | `flutter clean && flutter run` |
| You want a shippable APK | `flutter build apk --release` (output: `build/app/outputs/flutter-apk/app-release.apk`) |

Useful flags:
- `flutter run -d <device-id>` — pick a specific device (`flutter devices` to list)
- `flutter run --release` — release-mode debug build
- `flutter run -v` — verbose (helps when a build fails silently)

For your case (you just swapped launcher icons in `mipmap-*`), the Android resources picker reruns automatically — `flutter run` is enough; no need for `flutter clean` unless the old icon caches in the launcher (rare).

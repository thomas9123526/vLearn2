# vLearn2 Flutter App

Cross-platform (Android + Windows) Flutter app for the vLearn2 English-learning experience. Runs independently of the backend (uses local SQLite cache; connects to the API when reachable).

## Prereqs

- Flutter 3.41+ (run `flutter doctor` to verify)
- Android: Android Studio + SDK + a device or emulator (API 24+)
- Windows: Visual Studio 2022 with the "Desktop development with C++" workload

## First-time setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates Drift/Freezed/Retrofit/Riverpod code
```

## Run

```bash
flutter run -d windows           # Windows desktop
flutter run -d <android-id>      # Android (run `flutter devices` to list IDs)
```

By default the app talks to `http://localhost:3000`. Override:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com -d <device>
```

## Common commands

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install dependencies |
| `dart run build_runner watch` | Watch + regenerate generated files |
| `flutter analyze` | Static analysis |
| `dart format .` | Format all sources |
| `flutter test` | Unit + widget tests |
| `flutter build apk --release` | Android release build |
| `flutter build windows --release` | Windows release build |

## Folder structure

```
lib/
├── core/
│   ├── api/                # Dio client + Retrofit endpoints + interceptors
│   ├── config/             # LayoutConfigProvider (remote feature flags)
│   ├── db/                 # Drift database, DAOs, table classes
│   ├── evaluation/         # Future: per-skill scorers (fluency, pronunciation, …)
│   ├── guard/              # Content guard wordlist check
│   ├── models/             # Freezed data models
│   ├── providers/          # Top-level Riverpod providers
│   ├── repositories/       # Repository layer (API + DB)
│   ├── router/             # go_router config
│   ├── speech/             # STT/TTS abstractions (placeholder until sherpa-onnx integration)
│   ├── storage/            # Model storage paths (future sherpa-onnx)
│   ├── theme/              # ThemeData + design tokens
│   └── utils/
├── features/               # One folder per feature: auth, home, scenarios, conversation, ...
├── l10n/                   # ARB translation files
├── shared/widgets/         # Cross-feature widgets (cards, badges, layout_visibility, ...)
└── main.dart
```

## Talking to the backend

The backend lives in [`../backend`](../backend). Run it with `cd ../backend && npm run start:dev` before launching the app, or point at a remote API via `--dart-define`.

If the backend is unreachable, the app falls back to cached SQLite data for read-only flows (home, scenarios list, progress) and queues writes for retry.

## Documentation

Design + planning docs in [`../todoList/0516/`](../todoList/0516/) — start with [00_overview.md](../todoList/0516/00_overview.md).

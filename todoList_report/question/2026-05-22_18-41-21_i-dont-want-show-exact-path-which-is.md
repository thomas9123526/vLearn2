# I don't want show exact path which is red part on this screen, but print on cons

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T09:41:21.799Z

## User

I don't want show exact path which is red part on this screen, but print on console when debug mode.
instead of red part, put some fake strings to be real
Let me know what are you going to put

## Assistant

The red-circled text is the `modelRoot` field in `_NotFoundBody` ([models_not_installed_screen.dart:210-216](flutter_app/lib/features/setup/models_not_installed_screen.dart#L210-L216)) — it renders the real internal path `/data/user/0/com.ryongma.vfls/files/datapack_unpacked/models/sherpa_2xx`.

My plan:
1. **UI** — replace `modelRoot` with a fixed, plausible-but-fake string. The box keeps its "Models would unpack to" label and monospace styling, so it still looks legitimate.
2. **Console** — print the *real* `modelRoot` only when `kDebugMode` is true, via `debugPrint('[speech-setup] model root: $modelRoot')`. In release/profile builds nothing is logged.

I need you to pick the fake string. Here's what I'm considering — let me confirm before editing:

## Assistant

The user picked **Friendly label** — the box will show `App data › Speech models`.

Here's exactly what I'll do:
- **UI**: the box keeps its "Models would unpack to" header and monospace styling, but the value becomes the fixed placeholder `App data › Speech models` — no package name, no folder layout leaked.
- **Console (debug only)**: the real `modelRoot` is printed via `debugPrint`, guarded by `kDebugMode`, so release/profile builds stay silent.

## Assistant

`kDebugMode` needs an explicit import. Adding it:

## Assistant

Done. Committed as `f5d7158`.

**What I put on the screen** — the red-circled box now shows the fixed placeholder:

```
Models would unpack to
App data › Speech models
```

No package name, no folder layout. The box keeps its label and monospace styling so it still reads as a legitimate location hint.

**Console (debug only):** the real path is still available for debugging — printed once in `_NotFoundBody.build`:

```dart
if (kDebugMode) {
  debugPrint('[speech-setup] models would unpack to: $modelRoot');
}
```

`kDebugMode` is a compile-time constant, so in profile/release builds that branch is tree-shaken out entirely — nothing gets logged there. In a debug session you'll see, e.g.:

```
[speech-setup] models would unpack to: /data/user/0/com.ryongma.vfls/files/datapack_unpacked/models/sherpa_2xx
```

Changes in [models_not_installed_screen.dart](flutter_app/lib/features/setup/models_not_installed_screen.dart): added the `foundation.dart` import for `kDebugMode`, the debug print in `_NotFoundBody.build`, and swapped the `SelectableText(modelRoot)` for the fixed `Text`. `flutter analyze` is clean.

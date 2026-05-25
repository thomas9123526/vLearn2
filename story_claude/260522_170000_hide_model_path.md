# Speech-setup screen — hide the real model path

## What changed

`flutter_app/lib/features/setup/models_not_installed_screen.dart`,
the `_NotFoundBody` widget (the "Speech models not installed" state).

The grey box used to render the real internal unpack location:

```
/data/user/0/com.ryongma.vfls/files/datapack_unpacked/models/sherpa_2xx
```

That leaks the package name and the on-disk folder layout. It now
shows a fixed, friendly placeholder instead:

```
Models would unpack to
App data › Speech models
```

The box keeps its label and monospace styling, so it still reads as
a legitimate "this is where it goes" hint — just without the real
path.

## Debug-only console output

The real `modelRoot` isn't thrown away — it's printed to the console,
but **only in debug builds**:

```dart
if (kDebugMode) {
  debugPrint('[speech-setup] models would unpack to: $modelRoot');
}
```

`kDebugMode` is compile-time const, so in profile/release builds the
branch is tree-shaken out — nothing is logged there.

## Why

The admin asked not to surface the exact internal path on-screen
(it's circled in red in the device screenshot), but to keep it
reachable for debugging. So: fake-but-plausible string in the UI,
real path on the debug console.

## Notes

- `_NotFoundBody` still receives `modelRoot` — it's now used solely
  for the debug print, not for display.
- Added `import 'package:flutter/foundation.dart'` for `kDebugMode`.
- `flutter analyze` on the file → No issues found.

## User prompt (verbatim)

> I don't want show exact path which is red part on this screen, but
> print on console when debug mode.
> instead of red part, put some fake strings to be real
> Let me know what are you going to put

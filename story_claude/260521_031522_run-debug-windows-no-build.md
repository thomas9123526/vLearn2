# Add `run_debug_windows.bat` — launch the built debug exe without rebuilding

## What this task did

Mirror of `run_release_windows.bat` for the debug build flavor.
Launches `build\windows\x64\runner\Debug\flutter_app.exe` via
`start ""`, with the same pre-flight existence check that points back
at `build_debug_windows.bat` when the artifact is missing.

The header explicitly calls out the caveat: launching the exe
directly **runs** the debug binary but does **not** attach hot
reload / hot restart / DevTools — those require `flutter run` to
stay alive and host the VM service. If the user wants the dev loop,
they should still use `build_debug_windows.bat`.

## Conversation summary

- User asked "how about debug?" after I added `run_release_windows.bat`.
- Mirrored the script with the Debug path swapped in and a header
  note about hot-reload not being available when launching the exe
  directly.

## Decisions / call-outs

- **Same shape as the release launcher.** Symmetry beats clever; the
  release script already handles the corner cases I'd want to handle
  here.
- **Explicit "no hot reload" header.** Easy footgun otherwise:
  someone runs this expecting `flutter run` behavior, edits Dart
  code, and is confused when nothing reloads.
- **Path is `build\windows\x64\runner\Debug\flutter_app.exe`.** This
  is what `flutter run -d windows --debug` (which is what
  `build_debug_windows.bat` invokes) produces alongside the
  hot-reload-attached process. The artifact persists after the run.

## User prompt (verbatim)

> how about debug?

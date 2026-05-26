# Windows build scripts: optional `-v` for per-step progress + phase timing

## What this task did

Added a passthrough `-v` / `--verbose` flag to both
`flutter_app/build_release_windows.bat` and
`flutter_app/build_debug_windows.bat`. With no args the scripts stay
clean (one line per phase); with `-v` they pass `-v` to `flutter
build` / `flutter run`, which prints every `gen_snapshot`, `cmake`,
`cl.exe` / `clang-cl.exe`, and linker invocation so you can see which
file is currently being processed.

The release script also reports wall-clock elapsed time for the two
top-level phases (`flutter pub get`, `flutter build windows`) using a
small `:ELAPSED` helper. That gives a coarse "is it still working"
signal even when run without `-v`.

No behavior change for the default invocation — passing nothing still
produces the same output as before, plus the elapsed-time tail.

## Why the build is slow (answered inline to the user)

`flutter build windows --release` runs four heavy phases silently
behind the spinner:

1. **Dart AOT** (`gen_snapshot`): compiles every package in the
   dependency tree (dio, riverpod, go_router, sherpa_onnx, rive,
   flutter_svg, etc.) into a native code snapshot. Mostly
   single-threaded; the wide dep graph is what makes it long.
2. **Native plugin build** (cmake + cl.exe / clang-cl): the Runner
   shell plus every Windows plugin. `sherpa_onnx` and `rive_common`
   each compile a non-trivial C++ codebase.
3. **Asset bundle**: copies the Editorial TTFs (big), guard
   wordlists, Rive animations.
4. **Final link**: produces `flutter_app.exe` + DLLs. Heavy I/O,
   often slowed by Windows Defender scanning each new file.

Cold builds redo all of the above; incremental builds reuse `build/`
and are 5–10× faster.

## Conversation summary

- User asked: why is `flutter build windows` slow, and how to see
  progress.
- Surveyed the two existing Windows build scripts
  (`build_release_windows.bat`, `build_debug_windows.bat`).
- Added a one-arg verbose passthrough plus phase-elapsed timing.
- Explained the phases inline in the reply so the answer survives
  outside the script.

## Decisions / call-outs

- **`-v` as a passthrough, not a separate verbose script.** Two
  scripts per build mode would drift; a single optional flag is
  smaller and matches Flutter CLI conventions.
- **Phase timing in the release script only by default.** Debug uses
  `flutter run` which is interactive (hot-reload server); timing the
  whole `run` doesn't tell you anything useful since the script
  blocks until you Ctrl-C.
- **Did not switch to `--verbose` by default.** It prints thousands
  of lines and would be noisy for the common case where the build
  works.
- **Did not add `--no-pub` or other micro-opt flags.** Skipping
  `pub get` saves ~5–10s but masks dependency changes; not worth the
  footgun.
- **Didn't touch `cmds/build_*_windows.bat`.** The user's commit
  history shows those mirror these scripts; if they want the same
  flag treatment in `cmds/` I'll do a follow-up.

## User prompt (verbatim)

> flutter build windows, why this commands takes long time?
> And I want see the build progress to know what is building now

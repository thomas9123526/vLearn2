# Add `flutter_app/start_debug_windows.bat`

## What this task did

Created [flutter_app/start_debug_windows.bat](../flutter_app/start_debug_windows.bat) — a sibling of [cmds/start_debug_windows.bat](../cmds/start_debug_windows.bat) that lives next to the Flutter project. Skips `flutter pub get` (assumes deps are already resolved); just runs `flutter run -d windows --debug --dart-define=API_BASE_URL=http://localhost:3000/api` with hot reload (`r` / `R` / `q`).

This is the "start" counterpart to [flutter_app/build_debug_windows.bat](../flutter_app/build_debug_windows.bat) added in the previous task — which runs `pub get` first, suitable for fresh checkouts or after pubspec edits. Once deps are in place you can use `start_debug_windows.bat` to skip the resolver and launch faster.

## Conversation summary

- User wrote: *"also give me flutter_app/build_debug_windows.bat which start windows debug."*
- The filename in their message (`build_debug_windows.bat`) is the same file I just created in the prior turn (which does `pub get` + `flutter run`). But the *description* — "which start windows debug" — matches the `start_debug_*` convention used in [cmds/](../cmds/): `cmds/start_debug_windows.bat` is a "no pub get, just launch" script.
- Reasonable call (per the no-clarifying-questions instruction): user meant `start_debug_windows.bat`, not `build_debug_windows.bat`. So I created `flutter_app/start_debug_windows.bat` mirroring the cmds/ version. The previously-added `flutter_app/build_debug_windows.bat` is untouched.

## Decisions / call-outs

- **Interpreted the filename as a typo.** The description "which start windows debug" matches the cmds/ split where `build_debug_*` does pub-get-then-run and `start_debug_*` just runs. I followed the description, not the literal filename, because the literal filename was already a file I'd just created with different semantics. If user actually wanted the existing `build_debug_windows.bat` overwritten to skip pub get, they can say so and I'll revert.
- **Used `pushd "%~dp0"`** (the script's own directory), same approach as `flutter_app/build_debug_windows.bat`. Lets it work whether double-clicked or invoked from a different CWD.
- **Kept both `cmds/` and `flutter_app/` copies.** Same rationale as the previous task — symmetric launch points.
- **No change to other scripts.** The `cmds/` versions remain authoritative; the `flutter_app/` copies are conveniences.

## User prompt (verbatim)

> also give me flutter_app/build_debug_windows.bat which start windows debug.

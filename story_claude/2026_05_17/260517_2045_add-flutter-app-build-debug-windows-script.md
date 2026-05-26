# Add `flutter_app/build_debug_windows.bat`

## What this task did

Created [flutter_app/build_debug_windows.bat](../flutter_app/build_debug_windows.bat) — a sibling of the existing [cmds/build_debug_windows.bat](../cmds/build_debug_windows.bat) that lives next to the Flutter project itself so you can double-click / launch it without leaving `flutter_app/`.

Same behavior as the cmds/ version:
- Sets `API_BASE_URL=http://localhost:3000/api`
- `pushd` into `flutter_app/` (uses `%~dp0` — the script's own directory)
- `flutter pub get`
- `flutter run -d windows --debug --dart-define=API_BASE_URL=...` (hot-reload enabled)

The header comment also notes the ClangCL requirement that came out of today's earlier debugging, so future-you doesn't re-discover it.

## Conversation summary

- Earlier this session: `.\cmds\build_debug_windows.bat` failed with `MSB8020: build tools for ClangCL ... cannot be found`. Root cause was `rive_common 0.4.15` hardcoding `VS_PLATFORM_TOOLSET ClangCL` in its plugin CMakeLists, plus globally setting Clang-only `-Wno-*` flags via `CMAKE_CXX_FLAGS`. The plugin is genuinely Clang-only on Windows by design — can't be force-routed onto MSVC without a vendor-level patch. User chose **Option A: install ClangCL in Visual Studio Installer** as the durable fix.
- User selected line 3 of `cmds/make_cmd.txt` in their IDE (which reads "also give me cmds/build_debug_windows.bat which build flutter windows and start debug") and then typed: "also give me flutter_app/build_debug_windows.bat which build flutter windows and start debug." So the request differs from the IDE-selected line in *location* — they want the script inside `flutter_app/`, not (or in addition to) `cmds/`.
- The `cmds/build_debug_windows.bat` already exists and works — this new file is just a convenience duplicate placed at the project root.

## Decisions / call-outs

- **Used `%~dp0` (script's own directory)** rather than `%~dp0..\flutter_app` like the cmds/ version, because this script *is* inside `flutter_app/`. That `pushd %~dp0` is essentially a no-op when run from the same directory but keeps the script working if invoked with a different CWD.
- **Did not delete `cmds/build_debug_windows.bat`.** Kept both — the cmds/ version is reachable from project root for symmetry with the other build/start scripts; the flutter_app/ version is for when you're already inside the Flutter project.
- **Kept hot-reload (`flutter run`)** rather than `flutter build windows --debug` since the user asked for "build … and start debug". `flutter run` does both (compile + launch + attach for hot reload) in one shot.
- **No companion script for Android** added inside `flutter_app/`. User only asked for the Windows one.

## User prompt (verbatim)

> also give me flutter_app/build_debug_windows.bat which build flutter windows and start debug.

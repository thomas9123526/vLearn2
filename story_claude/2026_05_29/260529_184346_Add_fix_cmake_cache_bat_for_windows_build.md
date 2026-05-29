# Conversation - Add fix_cmake_cache.bat for corrupted Windows CMake cache

| Field | Value |
|---|---|
| Saved | 2026-05-29 18:43:46 |
| Commit | cmds: add fix_cmake_cache.bat to clear corrupted Windows CMake cache |
| Project | C:\project\vLearn2 |

---

## Context

Moving to the Windows desktop target, `flutter run -d windows` failed with a
wall of MSB3073 errors. Diagnosis (toolchain was healthy - flutter doctor green,
MSVC cl.exe present):

1. Real error hidden under MSB3073: CMake INSTALL step tried to write to
   `C:/Program Files/flutter_app` ("Maybe need administrator privileges").
   build\windows\x64\CMakeCache.txt had
   `CMAKE_INSTALL_PREFIX = C:/Program Files/flutter_app` (CMake default)
   instead of Flutter's `$<TARGET_FILE_DIR:flutter_app>`.
2. Deleting only build\windows left a half-configured tree -> secondary
   "No CMAKE_C_COMPILER could be found" for the transitive `jni` plugin
   (LANGUAGES C), despite cl.exe (MSVC 14.44) being present.

Fix that worked: full `flutter clean` (wipes build\, .dart_tool\, and
windows\flutter\ephemeral\) + `flutter pub get` + rebuild -> correct prefix
`$<TARGET_FILE_DIR:flutter_app>`, build succeeded.

## User

can you make a bat to cleanup if there's corrupted CMake cache for further
development?

## Assistant

Created cmds\fix_cmake_cache.bat (sibling to fix_gradle_cache.bat), same style:
- Default: surgical - delete only flutter_app\build\windows (the generated
  CMake tree). Fast; fixes the common bad-CMakeCache.txt / wrong-prefix case.
- --full: `flutter clean` + `flutter pub get` for the harder cases (e.g.
  "No CMAKE_C_COMPILER", which needs windows\flutter\ephemeral\ regenerated).
- Warns (does not auto-kill) if flutter_app.exe is running, since it locks the
  build output. Verifies the delete actually completed. Offline note: --full's
  pub get resolves from C:\pub-cache.

Verified surgical mode runs cleanly (deleted build\windows, clear next-steps
output). Kicked off a rebuild afterward to restore a working tree.

---

## Prompt

can you make a bat to cleanup if there's corrupted CMake cache for further
development?

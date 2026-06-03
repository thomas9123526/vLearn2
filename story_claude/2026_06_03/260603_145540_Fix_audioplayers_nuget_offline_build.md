# Conversation - Fix audioplayers_windows nuget offline build

| Field | Value |
|---|---|
| Saved | 2026-06-03 14:55:40 |
| Commit | Fix audioplayers_windows offline build: pre-seed nuget.exe via FETCHCONTENT_SOURCE_DIR_NUGET |
| Project | C:\project\vLearn2 |

---

## User

last error was on the vmware where there's no internet.
[flutter run -d windows fails: CMake tries to download nuget.exe from dist.nuget.org, DNS fails]

## Assistant

Root cause: `audioplayers_windows` CMakeLists.txt line 20 uses CMake `FetchContent_MakeAvailable(nuget)` which downloads `nuget.exe` from `https://dist.nuget.org/win-x86-commandline/v6.5.0/nuget.exe` on every CMake configure step. In an offline VM, DNS fails.

Fix: Set the CMake cache variable `FETCHCONTENT_SOURCE_DIR_NUGET` in `flutter_app/windows/CMakeLists.txt` to point at a local directory. When this variable is set, CMake's FetchContent skips the download entirely and uses the pre-placed directory as the source.

Changes:
1. `flutter_app/windows/CMakeLists.txt` — added `set(FETCHCONTENT_SOURCE_DIR_NUGET ...)` before the flutter subdirectory
2. `.gitignore` — added `flutter_app/windows/nuget/` (nuget.exe is binary, not committed)

To use on the offline VM: copy `nuget.exe` (v6.5.0, 7.3 MB) to `flutter_app\windows\nuget\nuget.exe` on the VM, then `flutter run -d windows` works without internet.

---

## Prompt

last error was on the vmware where there's no internet.

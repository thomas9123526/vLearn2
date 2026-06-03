# Conversation - Fix sqlite3_flutter_libs offline build

| Field | Value |
|---|---|
| Saved | 2026-06-03 15:27:28 |
| Commit | Fix sqlite3_flutter_libs offline build: pre-seed sqlite3 source via FETCHCONTENT_SOURCE_DIR_SQLITE3 |
| Project | C:\project\vLearn2 |

---

## User

I passed audioplayer problem. now i get new error.
[flutter run -d windows fails: FetchContent tries to download sqlite-autoconf-3520000.tar.gz from sqlite.org, DNS fails]

## Assistant

Scanned all Windows plugins for FetchContent/ExternalProject downloads. Only two real build deps (googletest is test-only, not needed for flutter run):
1. nuget.exe — already fixed
2. sqlite3 source — this fix

Downloaded sqlite-autoconf-3520000.tar.gz (3 MB) on host, extracted with --strip-components=1 into flutter_app/windows/sqlite3_src/ (contains sqlite3.c, sqlite3.h, sqlite3ext.h). Set FETCHCONTENT_SOURCE_DIR_SQLITE3 in windows/CMakeLists.txt to point at that directory.

To use on offline VM: copy flutter_app/windows/sqlite3_src/ folder to same path on VM, git pull for the CMakeLists change, then flutter run -d windows.

---

## Prompt

I passed audioplayer problem. now i get new error. [sqlite3 download failed]

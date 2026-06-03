# Conversation - Offline Windows build step-by-step user guide

| Field | Value |
|---|---|
| Saved | 2026-06-03 19:17:37 |
| Commit | auto: add offline Windows build step-by-step guide |
| Project | C:\project\vLearn2 |

---

## User

"can you make a user guide for above ? step by step."

## Assistant

Wrote `cmds/offline_windows_build_guide.md` — a step-by-step guide for the
air-gapped VMware VM Windows build. Sections:

1. What needs the network and the repo-local offline source for each (nuget.exe,
   WIL, CppWinRT, NuGet.Config, sqlite3_src, rive_native_prebuilt, pub cache).
2. Prerequisites.
3. Phase A — one-time online setup (pub get, nuget.exe, populate feed, sqlite
   source, rive prebuilt DLLs, install_rive_native.ps1) with exact commands.
4. Phase B — verify the offline build with network off.
5. Phase C — daily offline build/debug.
6. Adding a new NuGet package later.
7. Troubleshooting (the harmless "Nuget.exe not found" STATUS line, package-not-
   in-feed, sqlite/rive offline failures, and the Rive GPU crash cross-reference).
8. File reference table.

Grounded in the actual repo wiring verified earlier (FetchContent overrides in
windows/CMakeLists.txt, the <clear/> repo-local NuGet.Config, populate_nuget_feed.ps1,
install_rive_native.ps1).

---

## Prompt

can you make a user guide for above ? step by step.

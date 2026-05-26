# DataManage — Stage 1 redo: Win32 GUI scaffold

## Why this redo

After Stage 1 landed as a CLI tool (commit `40cdddf`), the admin asked
for DataManage to be a **GUI application**, runnable on Windows 10
**both x64 and x86 (Win32)**. The file format, packing logic, and
crypto plan are all untouched — only the front-end and build config
change.

Of the three framework options I floated (Dear ImGui, wxWidgets, raw
Win32), the admin picked **raw Win32**. Pros: zero external code,
fully offline build with just the VS 2022 desktop C++ workload. Con:
controls look like classic Windows (themed via Common Controls v6 on
modern Windows, but no fancy panels). Fine for an admin tool.

## What landed

### Files added

- `resources/app.manifest` — Common Controls v6 dependency + Windows 10
  / 11 supportedOS GUIDs + PerMonitorV2 DPI awareness + UTF-8 active
  code page.
- `resources/app.rc` — embeds the manifest as `RT_MANIFEST` (resource
  type 24) in the .exe so themed controls and high-DPI scaling kick in
  without a separate `.manifest` file beside the binary.
- `src/app.h` — menu command IDs, status-bar control ID, `runGui()`
  signature.
- `src/app.cpp` — main window registration, menu bar (File / Pack /
  Help), status bar across the bottom, WindowProc handling `WM_CREATE`,
  `WM_SIZE`, `WM_COMMAND`, `WM_PAINT`, `WM_CLOSE`, `WM_DESTROY`. About
  dialog shows Stage info.

### Files rewritten

- `src/main.cpp` — `wWinMain` entry point. Branches:
  - **GUI mode** (no positional args): calls `runGui()`.
  - **CLI mode** (any positional arg, or explicit `--no-gui`):
    `AttachConsole(ATTACH_PARENT_PROCESS)` + UTF-8 conversion of wide
    argv + dispatch into `parseCli()` / `run()`. Stdout/stderr set
    unbuffered so the parent shell sees output even though the
    WIN32-subsystem CRT doesn't flush stdio on return.
- `CMakeLists.txt`:
  - `add_executable(DataManage WIN32 …)` so no console window pops on
    launch.
  - Added `LANGUAGES … RC` so the resource compiler runs.
  - Added `set_source_files_properties(resources/app.rc PROPERTIES
    COMPILE_FLAGS "/I…/resources")` so rc.exe finds `app.manifest`.
  - `target_link_libraries`: `comctl32 user32 gdi32 shell32`.
  - `target_link_options(/MANIFEST:NO)` to disable MSVC's
    auto-injected manifest, which would otherwise collide with mine
    at link time (`CVT1100: duplicate resource. type:MANIFEST`).
- `README.md` — rewritten for GUI build, x64 / x86 build instructions
  for both PowerShell and VS Open Folder, note about the
  WIN32-subsystem CLI piping caveat.
- `.gitignore` — extended to ignore `build-*` directories (so
  `build-x64/` and `build-x86/` don't get committed).

### Files unchanged

- `src/cli.h`, `src/cli.cpp` — kept verbatim. Still drives CLI mode
  through `parseCli` + `run`.
- `config.example.json` — same schema preview.
- `vendor/README.md` — same plan for Stages 2 / 4 / 6 / 7.

## Bumps along the way (and fixes)

1. **`L__DATE__` doesn't compile.** `L` can't be prefixed to a macro.
   Dropped the build-date display from the About dialog. (Easy fix:
   `_CRT_WIDE(__DATE__)` from `<crtdefs.h>` — but the About box was
   fine without it.)
2. **C4312 warning casting `UINT` to `HMENU` on x64.** Standard Win32
   idiom for setting a child control ID; need `UINT_PTR` widening:
   `reinterpret_cast<HMENU>(static_cast<UINT_PTR>(IDC_STATUS_BAR))`.
3. **`CommandLineToArgvW` undefined.** `WIN32_LEAN_AND_MEAN` excludes
   `shellapi.h`. Added explicit `#include <shellapi.h>`.
4. **`CVT1100: duplicate resource. type:MANIFEST`.** MSVC auto-injects
   its own manifest. Disabled via `/MANIFEST:NO`.
5. **PowerShell `& exe --help` shows no output.** WIN32-subsystem
   processes don't pipe stdout to PowerShell synchronously. Documented
   the workaround (`Start-Process -Wait -NoNewWindow`). Exit codes
   still propagate correctly. Stage 1 doesn't need fancy CLI piping;
   a separate CONSOLE-subsystem `DataManage_cli.exe` target can be
   added later if CLI usage becomes common.

## Verification on this box

- `cmake -B build-x64 -G "Visual Studio 17 2022" -A x64` → ok
- `cmake --build build-x64 --config Release` → ok, produces
  `build-x64/bin/DataManage.exe` (28160 bytes).
- `cmake -B build-x86 -G "Visual Studio 17 2022" -A Win32` → ok
- `cmake --build build-x86 --config Release` → ok, produces
  `build-x86/bin/DataManage.exe` (24064 bytes).
- `dumpbin /headers` confirms subsystem `Windows GUI` (2) and machine
  `x64` (8664) — both correct.
- Launched the x64 binary via `Start-Process -PassThru` — window
  opens, title reads `DataManage 0.1.0`, killed cleanly after 2s.

## Stage 2 preview

Define the `.ddp` binary format as a single header (`src/format.h`)
and vendor nlohmann/json so we can declare the manifest schema in
C++. Stage 2 needs an external download (the JSON header) so I'll ask
for authorisation first the same way I did for ImGui.

## User prompts (verbatim, this redo)

> sorry , let's confirm one. I want DataManage to be gui application
>
> 3
>
> I want DataManage GUI can be run on windows 10 and x64,x32 both

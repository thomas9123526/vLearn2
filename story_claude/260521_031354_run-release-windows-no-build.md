# Add `run_release_windows.bat` — launch the built exe without rebuilding

## What this task did

Added `flutter_app/run_release_windows.bat`. It launches the already-built
release binary at `build\windows\x64\runner\Release\flutter_app.exe`
without going through `flutter build` again. If the exe doesn't exist
yet, the script prints a clear message pointing at
`build_release_windows.bat` rather than failing with a generic
"file not found".

Uses `start ""` so the launched process is detached from this shell —
the .bat returns immediately rather than tying the console to the
running app.

## Conversation summary

- User asked for the command to "just run build exe without build".
- I answered inline (`build\windows\x64\runner\Release\flutter_app.exe`
  works as-is since its DLLs and `data\` sit alongside it).
- User said yes to a wrapper script, so I added it in the same shape
  as `build_release_windows.bat`.

## Decisions / call-outs

- **`start ""` instead of direct invocation.** Direct invocation
  blocks the shell for the lifetime of the app. `start ""` (empty
  title) detaches the process, matching how a user would launch from
  Explorer. If you'd rather the script wait, drop the `start ""`.
- **Hard-coded x64 Release path.** Matches the only build flavor the
  release script produces. If we ever add ARM64 or Profile, the
  script would need a flag.
- **Pre-flight `exist` check.** Cheap, removes a common newcomer
  failure mode where you run the launcher before the first build.
- **Did not mirror to `cmds/`.** The flutter_app/ build scripts are
  the local-dev surface; `cmds/` is for backend + admin orchestration.
  Putting this batch there would mix concerns.

## User prompt (verbatim)

> yes

# DataManage — background packing, live progress, crash-resume

## What the admin asked for

Three connected things:
1. Show progress on the DataManage screen while packing.
2. Don't freeze the UI during a pack run.
3. Store each bundle's result as it finishes, so if the program
   exits/crashes mid-run, reopening and packing again **resumes**
   from where it stopped instead of re-doing finished bundles.

All three landed together — they're one cohesive feature.

## 1 + 2 — background thread + progress bar

Previously `onRunPack` called `packAll()` synchronously on the UI
thread; a 174 MB bundle froze the whole window for the duration.

Now:

- `onRunPack` loads + hashes the config on the UI thread (so a bad
  config still surfaces an error box immediately), then spawns a
  detached `std::thread` running `packWorker` and returns — the UI
  thread is free.
- `packWorker` drives the bundle loop itself and reports back only
  via `PostMessage` (Win32 controls are single-threaded; a worker
  can't touch them). Three new `WM_APP+n` messages:
  - `WM_APP_PACK_PROGRESS` — wParam = percent, lParam = heap
    `std::wstring*` status text (UI thread takes ownership, deletes).
  - `WM_APP_PACK_DONE` — lParam = the result-dialog text.
  - `WM_APP_PACK_ERROR` — lParam = the error text.
- A Win32 progress bar (`PROGRESS_CLASSW`) sits above the status
  bar, created hidden, shown by `beginPackingUI` / hidden by
  `endPackingUI`. `ICC_PROGRESS_CLASS` added to
  `InitCommonControlsEx`.
- Progress percent: each bundle owns an equal slice of the bar;
  within a bundle the slice fills by `completed_files / total_files`
  (from `packBundle`'s existing per-file callback). The status bar
  shows `Packing (2/5) — sherpa_models — encoder/model.onnx (45/363)`.
- The `Pack → Run Pack` menu item greys out while a run is active,
  so a second run can't start.

## 3 — crash-resume via a checkpoint file

New `PackSession` (`src/session.{h,cpp}`):

- A checkpoint file `<output_dir>/.datamanage_session.json` records
  every bundle the moment it finishes.
- After **each** bundle, `packWorker` calls `session.checkpoint(...)`,
  which rewrites the file **atomically** (write `.tmp`, rename).
- When the whole run finishes cleanly, `session.finish()` deletes
  the checkpoint.
- On a new run, `PackSession::open` reads the checkpoint:
  - keyed to a **SHA-256 of the config file** — a changed config
    discards the stale checkpoint (the bundle list may have moved).
  - a recorded bundle only counts as "done" if its `.dat` is still
    on disk **with the recorded byte size** — a half-written `.dat`
    from a crash-mid-write won't match, so it's re-packed.
- `packWorker` skips bundles `session.isDone(name)` reports, reusing
  the recorded result for the final summary; the progress / status
  shows `Resumed (3/5) — fonts (already packed)`.

Why a bundle is always either fully-done-or-not: `packBundle` flushes
+ closes the `.dat` before returning, and the checkpoint is written
**after** that. Crash before checkpoint → bundle re-packed (its
partial `.dat` is overwritten with `trunc`). Crash after → bundle
skipped. No half-states.

## Window-close guard

`WM_CLOSE` while packing now asks: "A pack run is still in progress.
Exit anyway? Finished bundles are already saved — the next run will
resume…" — making the resume promise explicit. Yes → exit (worker
dies with the process; checkpoint is the safety net). No → stay.

## Files

- **new** `src/session.h`, `src/session.cpp` — `PackSession`.
- **new** `src/session_smoke_test.cpp` + `session_smoke_test` CMake
  target — covers fresh open, checkpoint + reopen, config-hash
  invalidation, missing-`.dat` invalidation, size-mismatch
  invalidation, and `finish()`.
- `src/app.h` — `IDC_PROGRESS_BAR`, the three `WM_APP_PACK_*`
  message IDs.
- `src/app.cpp` — worker thread, progress bar, message handlers,
  `onRunPack` rewrite, packing-in-progress close guard, helper block
  (`hashConfigFile`, `percentForBundle`, `postProgress`,
  `buildResultText`, `packWorker`, `layoutProgressBar`,
  `beginPackingUI`, `endPackingUI`). Also tidied stale `.ddp`→`.dat`
  / "Stage 3" text in the About box + client-area placeholder.
- `CMakeLists.txt` — `src/session.cpp` added to `DataManage`; new
  `session_smoke_test` target.

## Verification

```text
cmake --build build-x64 / build-x86 --config Release  →  clean
manifest_smoke_test  →  PASS (x64)
packer_smoke_test    →  PASS (x64)
session_smoke_test   →  PASS (x64 + x86)
DataManage.exe       →  GUI window opens ("DataManage 0.1.0")
```

The threading + progress-bar UX itself can only be fully exercised
by running the GUI against a real config — but the resume logic
(the subtle part) is covered by `session_smoke_test`, and the build
is clean on both architectures.

## Note — CLI unchanged

`DataManage pack` (CLI) still runs `packAll` synchronously with no
session. The background-thread + progress-bar + resume work is
GUI-only, which is where the request was aimed. `PackSession` is a
standalone class, so the CLI could adopt resume later if wanted.

## User prompt (verbatim)

> I want show progress on DataManage Screen, and don't freeze the ui.
> While packing data, I want DataManage to store each result per
> bundles.
> Because If the program accidently exits, and then I open again and
> start pack, the DataManage resume the packing for last session if
> exists.

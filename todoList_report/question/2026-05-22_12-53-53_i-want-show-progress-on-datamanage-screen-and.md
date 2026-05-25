# I want show progress on DataManage Screen, and don't freeze the ui. While packin

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T03:53:53.479Z

## User

I want show progress on DataManage Screen, and don't freeze the ui.
While packing data, I want DataManage to store each result per bundles. 
Because If the program accidently exits, and then I open again and start pack, the DataManage resume the packing for last session if exists.

## Assistant

This is three connected features — background-thread packing (no freeze), live progress UI, and per-bundle resume. Let me build it. First the full current `app.cpp`.

## Assistant

Now building it. Session checkpoint module first.

## Assistant

Now `app.h` — add the worker→UI message constants + progress-bar control ID.

## Assistant

Now the substantial `app.cpp` work. Includes + state first.

## Assistant

Now the worker-thread + progress + resume helper block, inserted before `layoutStatusBar`.

## Assistant

Now rewrite `onRunPack` to spawn the worker.

## Assistant

Now WM_CREATE (progress bar), WM_SIZE, WM_CLOSE, and the three worker messages.

## Assistant

Now the `ICC_PROGRESS_CLASS` init + minor `.ddp`→`.dat` text cleanups.

## Assistant

Add `session.cpp` to CMake, then build.

## Assistant

x64 clean. The resume logic deserves a test — adding a session smoke test.

## Assistant

All three smoke tests pass. Now build x86 + verify the GUI window still opens.

## Assistant

All green — both archs build, all smoke tests pass, GUI launches. Committing.

## Assistant

Committed `894ede1`. All three features landed together.

## What you get now

**No more freeze** — packing runs on a detached `std::thread`; the UI thread stays responsive the whole time.

**Live progress** — a progress bar above the status bar, plus a status line like:
```
Packing (2/5) — sherpa_models — encoder/model.onnx (45/363)
```
Each bundle is an equal slice of the bar; within a bundle it fills by file count.

**Crash-resume** — a checkpoint file `<output_dir>/.datamanage_session.json` records every bundle the instant it finishes (atomic write). If DataManage crashes or you close it mid-run:
- Reopen, hit Run Pack again → already-finished bundles are **skipped** (status shows `Resumed (3/5) — fonts (already packed)`), packing continues from the first unfinished bundle.
- The checkpoint is keyed to a hash of the config — if you edit `config.json`, the stale checkpoint is discarded automatically.
- A bundle only counts as "done" if its `.dat` is still on disk with the recorded size — a half-written `.dat` from a crash-mid-write gets re-packed cleanly.
- On a fully clean run, the checkpoint file is deleted.

**Close-while-packing guard** — closing the window mid-pack asks "Exit anyway? Finished bundles are saved — the next run will resume…"

## Verified

| Check | Result |
| --- | --- |
| x64 + x86 build | clean |
| `manifest_smoke_test` | PASS |
| `packer_smoke_test` | PASS |
| `session_smoke_test` (new — covers resume logic) | PASS x64 + x86 |
| GUI launches | window opens |

The threading + progress bar can only really be judged by running the GUI — but the tricky part (the resume checkpoint logic: config-hash invalidation, missing-`.dat` detection, size-mismatch detection, `finish()`) is now covered by `session_smoke_test`.

## Try it

Rebuilt binaries are at `build-x64\bin\DataManage.exe` (and x86). Run a pack — you'll see the progress bar move and the window stay responsive. To test resume: start a multi-bundle pack, kill DataManage partway (Task Manager or close the window → "Exit anyway"), reopen, Run Pack again — it picks up where it stopped.

Note: the CLI (`DataManage pack`) is unchanged — still synchronous, no session. This work is GUI-only, which is where you pointed. `PackSession` is a standalone class, so the CLI could get resume too later if you want it.

# Phased unpacking, Stage C — on-demand group unpack + progress UI

Stage B made the splash install only `unpack_phase: "splash"` packs;
`on-demand` packs come back `deferred`. Stage C builds the on-demand
path: a feature can unpack its group when first needed, with a live
0–100% progress view, all on a background isolate (no ANR).

## Changes

### `datapack_factory.dart` — per-file progress

`unpack()` gained an optional `onFileProgress(filesDone, filesTotal)`
callback, fired once per file as the data section decodes. Drives the
progress fraction.

### `datapack_installer.dart` — `installGroup`

New `installGroup(group, {onProgress})` — the on-demand counterpart
to `installPending`:

- Scans every `.dat`, peeks each manifest, keeps those whose
  `manifest.group` matches.
- Splits matched packs into already-cached (SHA-256 in the state
  file → reported `cached`) vs needs-unpack.
- Sums total files across the to-unpack packs; unpacks each with
  `onFileProgress`, translating per-file counts into one overall
  0.0–1.0 fraction + a status string for `onProgress`.
- Checkpoints the state file after **every** pack, so an interrupted
  group unpack resumes cleanly.
- Returns outcomes only for the named group's packs.

New private `_ScannedPack` (file + peeked manifest + SHA-256) holds a
scan result.

### `datapack_provider.dart` — `DataPackGroupController`

The on-demand unpack is heavy (pure-Dart AES + zlib on tens of MB) so
— like the splash install — it must not run on the UI isolate. But it
also needs **streaming** progress, which `Isolate.run` (one-shot)
can't do. So it uses `Isolate.spawn` + a `ReceivePort`:

- `_groupWorker` runs `installGroup` in a spawned isolate and
  `send`s `_GroupProgress` per file, then `_GroupDone` / `_GroupError`.
- `DataPackGroupController` (a Riverpod `Notifier<DataPackGroupState>`)
  exposes `ensureGroup(group)`: spawns the worker, listens on the
  port, folds each message into `DataPackGroupState`
  (`idle / running / done / error` + `fraction` + `status`).
- `dataPackGroupControllerProvider` — `NotifierProvider`.

`ensureGroup` is idempotent and cheap on an already-installed group
(the worker reports everything `cached` and finishes near-instantly);
safe to retry after a failure (per-pack checkpointing).

### `lib/shared/widgets/datapack_progress_view.dart` (new)

`DataPackProgressView` — a stateless, theme-driven 0–100% view:
title, `LinearProgressIndicator(value: fraction)`, a big `NN%`, and
the status line. Drops into a dialog / overlay / full screen
unchanged. Stage D hosts it on the conversation screen.

## Tests

`installer_test.dart`: new test `installGroup unpacks only the named
group + reports progress to 100%` — packs a `core` pack and a 2-file
`speech` pack; `installGroup("speech")` returns only the speech pack
(`installed`, 2 files), the progress callback fires and ends at 1.0,
and a second call reports `cached`.

## Verification

```text
flutter analyze (datapack + progress widget + test)  → No issues
flutter test test/datapack/                          → 6/6 pass
```

The new test's log confirms the group filter + cache:
`installer: group "speech" — 1 pack(s) matched` … then on the second
call `CACHED  speech_pack.dat` / `all packs already installed`.

## Next — Stage D

Wire it into the conversation screen: on first start, if the speech
models aren't ready, call `ensureGroup("speech")` and show
`DataPackProgressView` until done. Then Stage E — `ModelRegistry`
resolves its root from the unpacked `speech` group.

## User prompt (verbatim)

> ok

(green light for Stage C after the plan was laid out)

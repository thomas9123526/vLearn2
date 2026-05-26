# Phased unpacking, Stage D+E — speech setup unpacks on-demand

D and E are inseparable (do D alone → unpack happens but sherpa can't
find the models; do E alone → ModelRegistry points at an empty folder
nothing fills), so they shipped together. Confirmed scope with the
admin first — this touches `ModelRegistry`, which the router, STT,
TTS and settings all depend on.

## Stage E — ModelRegistry resolves from the unpacked "speech" group

### `datapack_installer.dart`
- Install state entries (`installPending` + `installGroup`) now also
  record `group` and `unpacked_subroot` — the absolute model-root
  directory `<unpackedRoot>/<out_folder>`. New `_subrootFor(manifest)`
  computes it (every file in a bundle shares one `out_folder`).
- New top-level `unpackedRootForGroup(paths, group)` — reads the
  state file and returns where that group's pack(s) unpacked to, or
  null if the group isn't installed.

### `model_registry.dart`
- `resolveModelRoot()` rewired: was Android `getExternalStorageDirectory()
  /models` / Windows `%APPDATA%\VLearn2\models`. Now it resolves the
  datapack paths and calls `unpackedRootForGroup(paths, "speech")` —
  the model root is wherever the admin's `out_folder` put it, read
  back from the install state, no guessing.
- Before the speech group is installed → returns a placeholder
  `_speech_not_installed` dir (no `manifest.json` inside) →
  `snapshot()` reports `manifestMissing` → router sends the user to
  the speech-setup screen.
- A test `overrideRoot` still wins (`<override>/models`).
- `path_provider` import dropped (no longer used directly —
  `DataPackPaths` owns that now).
- **Public API unchanged** — `snapshot()`, `resolveFile()`,
  `modelRegistrySnapshotProvider` all keep the same shape, so the
  router / STT / TTS / settings need no edits and follow
  automatically (verified: all analyze clean).

## Stage D — ModelsNotInstalledScreen runs the unpack with progress

`ModelsNotInstalledScreen` reworked from a static "drop the bundle
manually" page into a `ConsumerStatefulWidget` that:

- On first frame (if no group unpack has run this session) calls
  `ensureGroup("speech")` — the Stage C on-demand, background-isolate
  unpack.
- **running** → shows `DataPackProgressView` (live 0–100% bar +
  status), no UI freeze.
- **done** → `ref.invalidate(modelRegistrySnapshotProvider)` so the
  registry re-resolves the freshly-unpacked location; then:
  - registry **ready** → a "Speech is ready" card + Continue → /home.
  - registry **not ready** (no speech `.dat` on the device) → "not
    installed" guidance showing where models would land, plus Retry
    (re-runs `ensureGroup`) and the text-only opt-out.
- **error** → error message + Retry.

The screen never consults the *old* model path, so there's no
"unpack-to-A, check-B" re-trigger loop.

## End-to-end flow now

1. User taps a scenario → tries `/conversation/:id`.
2. Router sees `ModelRegistry` not ready → redirects to `/setup/models`.
3. `ModelsNotInstalledScreen` auto-runs `ensureGroup("speech")` →
   background isolate decrypts/decompresses the speech `.dat` →
   live progress bar.
4. Done → registry re-resolves → models found at the unpacked
   location → "Speech is ready" → Continue → /home → user re-enters
   the conversation, router now lets them through, STT/TTS load the
   models via the same `ModelRegistry.resolveFile`.

## Tests

`installer_test.dart`: new test `unpackedRootForGroup resolves the
group model root` — before install the group resolves null; after
`installGroup('speech')` it resolves `<unpackedRoot>/<out_folder>`,
the directory exists, the unpacked files are under it; an unknown
group resolves null.

## Verification

```text
flutter analyze — datapack, model_registry, setup screen, router,
                  settings, speech/, tutor_mode_view  → No issues
flutter test test/datapack/                            → 7/7 pass
```

## Phased-unpacking feature — complete

| Stage | |
|---|---|
| A | C++ group/unpack_phase fields → manifest |
| B | Flutter installer phase filter (splash vs deferred) |
| C | on-demand `installGroup` + isolate progress + progress widget |
| D+E | ModelRegistry → unpacked location; setup screen runs the unpack with progress |

Speech models now flow end-to-end through the datapack pipeline:
admin packs a `group:"speech"` `.dat` → app unpacks it on first
conversation with a progress bar → sherpa-onnx loads from the
unpacked location.

## User prompt (verbatim)

> go

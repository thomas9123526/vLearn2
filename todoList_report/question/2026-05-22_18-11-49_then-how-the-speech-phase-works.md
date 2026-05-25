# then how the speech phase works?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T09:11:49.526Z

## User

then how the speech phase works?

## Assistant

Good question — and the key thing to clear up first: **"speech" is a group name, not a phase.** There are only two phase names — `"splash"` and `"on-demand"` — and a separate, independent axis of *group* names (`"core"` by default, `"speech"`, etc.).

A speech `.dat` is tagged in its manifest with **both**: `group: "speech"` and `unpack_phase: "on-demand"`.

Here's how the speech flow actually runs:

**1. Splash — speech is deliberately skipped.**
`installPending()` runs with phase `"splash"`. A speech pack's `unpack_phase` is `"on-demand"`, so it doesn't match → it's logged as `deferred` and left alone ([datapack_installer.dart:169-174](flutter_app/lib/core/datapack/datapack_installer.dart#L169-L174)). Nothing speech-related is unpacked at startup.

**2. Trigger — user enters a conversation.**
The router checks `ModelRegistry`, finds the speech models aren't there, and redirects to `/setup/models` (`ModelsNotInstalledScreen`).

**3. That screen calls `ensureGroup("speech")`** on `DataPackGroupController` ([datapack_provider.dart:213](flutter_app/lib/core/datapack/datapack_provider.dart#L213)).

**4. Background isolate.**
`ensureGroup` spawns `_groupWorker` on a fresh isolate, which runs `installGroup("speech")` — so the UI thread stays free, no ANR ([datapack_provider.dart:235-247](flutter_app/lib/core/datapack/datapack_provider.dart#L235-L247)).

**5. `installGroup` filters by GROUP, not phase.**
It scans every `.dat`, peeks each manifest, and keeps the ones where `manifest.group == "speech"` ([datapack_installer.dart:296](flutter_app/lib/core/datapack/datapack_installer.dart#L296)). Notice it never looks at `unpack_phase` here — group selection is purely by group name. Already-installed packs (matching SHA-256 in the state file) are reported `cached` and skipped.

**6. Unpack + checkpoint.**
For each pack still needing work, `factory.unpack()` decrypts/decompresses, then the state file records `group`, `unpacked_subroot` (`<unpackedRoot>/<out_folder>`), and the file list — checkpointed after **every** pack, so an interrupted speech install resumes cleanly.

**7. Progress streaming.**
Per-file progress is streamed back over the isolate's `SendPort` as `_GroupProgress` → `DataPackGroupState{fraction, status}`, which drives the 0–100% `DataPackProgressView`.

**8. Done → registry re-resolves.**
The screen invalidates `modelRegistrySnapshotProvider`; `ModelRegistry.resolveModelRoot()` calls `unpackedRootForGroup(paths, "speech")`, reads the recorded `unpacked_subroot` from the state file, and sherpa-onnx loads the models from exactly where the speech pack unpacked.

So the symmetry is:
- **`"splash"` phase** → `installPending()` selects packs by **phase**.
- **`"speech"` group** → `installGroup()` selects packs by **group**, ignoring phase entirely.

A speech pack uses the `"on-demand"` phase only so the splash pass leaves it alone; the actual unpacking is driven by the `"speech"` *group* lookup.

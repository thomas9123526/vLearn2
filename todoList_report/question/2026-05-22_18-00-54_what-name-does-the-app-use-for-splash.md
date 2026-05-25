# what name does the app use for splash unpack?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T09:00:54.170Z

## User

what name does the app use for splash unpack?

## Assistant

At splash time the app calls `installPending()` with no arguments, and that defaults its `phase` parameter to the string **`"splash"`** — see [datapack_installer.dart:117-121](flutter_app/lib/core/datapack/datapack_installer.dart#L117-L121) and the call site in [datapack_provider.dart:91-95](flutter_app/lib/core/datapack/datapack_provider.dart#L91-L95).

So two names are in play:

- **Phase** = `"splash"` — this is what selects *which* packs get unpacked at startup. Only `.dat` files whose manifest `unpack_phase == "splash"` are unpacked in the splash pass; anything tagged `"on-demand"` is skipped and logged as `deferred` ([datapack_installer.dart:62-63](flutter_app/lib/core/datapack/datapack_installer.dart#L62-L63), [:169-174](flutter_app/lib/core/datapack/datapack_installer.dart#L169-L174)).

- **Group** = `"core"` (the default) — a pack with no explicit group falls back to `group: "core"`. The splash pass doesn't filter by group, though; it takes every `"splash"`-phase pack regardless of group.

In short: the splash unpack is keyed on the **phase name `"splash"`**, not a group name. The `installPendingDataPacksProvider` runs `installPending()` on a background isolate, which uses that `"splash"` default.

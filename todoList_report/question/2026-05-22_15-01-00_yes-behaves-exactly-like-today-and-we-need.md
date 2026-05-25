# yes behaves exactly like today. And  we need to preserve app_config.json to less

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T06:01:00.814Z

## User

yes behaves exactly like today.
And  we need to preserve app_config.json to less than 1kb, so it is possible with this limitation?

## Assistant

**Yes — fully compatible, and it adds *zero* bytes to `app_config.json`.**

That was the whole point of recommendation #2: the group/phase metadata lives **inside the `.dat` files** (via `config.json` → manifest), never in `app_config.json`. The 1 KB ceiling is untouched by this feature.

`app_config.json` today holds only `backendBaseUrl`, `requestTimeout`, `topicSyncInterval`, `environment` — a few hundred bytes at most. This datapack work doesn't go near it. If the group config had gone into `app_config.json` (a list of packs × groups) it *could* have threatened the budget — which is exactly why the design keeps it out.

Starting **Stage A** — C++ `config.json` + manifest fields. Let me read the current bundle parser + manifest serializer.

## Assistant

Now the manifest type + serialization.

## Assistant

Now `packer.cpp` writes them into the manifest.

## Assistant

Update `config.example.json` + the manifest smoke test round-trip.

## Assistant

Adding a backward-compat test — legacy manifest without the new fields must default to core/splash.

## Assistant

Build + run all smoke tests.

## Assistant

x64 all pass. Real CLI check — pack with `group`/`unpack_phase` and confirm the manifest carries them.

## Assistant

Manifest carries `"group":"speech"` + `"unpack_phase":"on-demand"`. Build x86 + confirm Flutter side still reads these `.dat` files (it should ignore unknown manifest keys).

## Assistant

All green. Committing Stage A.

## Assistant

Committed `e349261`. **Stage A done.**

## Answering your `app_config.json` question directly

**Yes, fully compatible — this feature adds 0 bytes to `app_config.json`.** The group/phase metadata lives inside the `.dat` files (set via `config.json` at pack time, stored in the manifest). `app_config.json` is never touched, so its <1 KB ceiling is safe. That was the design intent of recommendation #2 — and your size constraint reinforces it.

## What Stage A landed (C++ side)

`config.json` per-bundle now accepts two optional fields:

```jsonc
{
  "name": "sherpa_2021",
  "out_folder": "models/sherpa_2021",
  "group": "speech",            // feature bucket
  "unpack_phase": "on-demand"   // "splash" | "on-demand"
}
```

Both flow into the `.dat` manifest. **Backward compatible exactly as you confirmed** — a bundle (or older `.dat`) that sets neither reads back as `group: "core"`, `unpack_phase: "splash"` — identical to today.

## Verified

- x64 + x86 build clean.
- All 3 C++ smoke tests pass both archs (incl. new `test_legacy_manifest_defaults` proving the "behaves like today" promise).
- `flutter test test/datapack/` 4/4 — the Flutter unpacker reads `.dat` files with the new manifest keys and ignores them gracefully.
- Real CLI pack confirmed: `group:"speech"` + `unpack_phase:"on-demand"` land in the manifest.

## Remaining stages

| Stage | Side | Work |
| --- | --- | --- |
| **A** | C++ | group + unpack_phase fields ✅ **done** |
| B | Flutter | installer reads group/phase; `installPending(phase)` filter; splash only does `phase: splash` |
| C | Flutter | `ensureGroup(name, onProgress)` + reusable 0–100% progress screen |
| D | Flutter | conversation screen: first start → if speech not ready → `ensureGroup("speech")` |
| E | Flutter | `ModelRegistry` resolves its root via the unpacked `speech` group instead of the hardcoded `/models` path |

Stage B is the natural next step — and it's safe: with the backward-compat defaults, existing `.dat` files all read as `phase: splash`, so a phase filter changes nothing until you actually tag a bundle `on-demand`.

Want me to go to Stage B?

# DataManage — phased unpacking, Stage A: group + unpack_phase fields

## Context

Admin wants unpacking split into phases: a small "core" set unpacked
at splash, feature-specific sets (e.g. speech models) unpacked
on-demand when the feature is first used. Design decision (confirmed
with the admin): the phasing metadata lives **in the pack itself**
(config.json → .dat manifest), not in app_config.json — which also
keeps app_config.json well under its 1 KB ceiling, since this feature
adds zero bytes to it.

Stage A is the C++ foundation: the `group` + `unpack_phase` fields.
Stages B–E (Flutter installer phase filter, on-demand unpack API +
progress screen, conversation-screen trigger, ModelRegistry rewire)
come later.

## What changed

### `config.json` — two new optional per-bundle fields

```jsonc
{
  "name": "sherpa_2021",
  "source_dir": "...", "out_folder": "models/sherpa_2021",
  "group": "speech",            // feature bucket
  "unpack_phase": "on-demand"   // "splash" | "on-demand"
}
```

- `src/config.h` — `BundleConfig` gained `std::string group = "core"`
  and `std::string unpack_phase = "splash"`.
- `src/config.cpp` — parses both as optional. `group` defaults to
  `"core"` (empty string also normalised to `"core"`). `unpack_phase`
  defaults to `"splash"` and is validated against
  `{"splash", "on-demand"}` with a bundle-named error message.

### `.dat` manifest carries them

- `src/manifest.h` — `Manifest` gained `group` + `unpack_phase`
  (same defaults).
- `src/manifest.cpp` — `manifestToJson` always writes both;
  `manifestFromJson` reads them if present, else defaults to
  `core` / `splash`, and validates `unpack_phase`.
- `src/packer.cpp` — `packBundle` copies `bundle.group` /
  `bundle.unpack_phase` into the manifest it writes.

### Backward compatibility — the explicit promise

A bundle (or an older `.dat`) that sets **neither** field behaves
exactly as before: `group = "core"`, `unpack_phase = "splash"`.
`manifestFromJson` on a legacy manifest with no `group`/`unpack_phase`
keys returns those defaults. No existing pack or config breaks.

## Tests

`manifest_smoke_test` extended:
- round-trip now also sets + checks `group` / `unpack_phase`.
- new `test_legacy_manifest_defaults` — a manifest JSON with neither
  field parses back as `core` / `splash`.
- new `test_reject_unknown_phase` — `"unpack_phase":"whenever"` is
  rejected.

## Verification

```text
x64 + x86  — build clean
manifest_smoke_test / packer_smoke_test / session_smoke_test
           — PASS on both archs
flutter test test/datapack/  — 4/4 pass (the Flutter unpacker reads
           .dat files whose manifest now has group/unpack_phase and
           ignores the unknown keys — backward compatible both ways)
```

Real CLI pack with `group:"speech"`, `unpack_phase:"on-demand"` →
the produced `.dat`'s manifest contains
`"group":"speech"` and `"unpack_phase":"on-demand"`.

## config.example.json

Updated to demonstrate the fields: an `out_font` bundle as
`core`/`splash`, a `sherpa_2021` bundle as `speech`/`on-demand`.

## Next — Stage B

Flutter installer reads `group` + `unpack_phase` from each `.dat`'s
manifest; `installPending` gains a phase filter so the splash only
unpacks `unpack_phase == "splash"`. Then Stage C (`ensureGroup` +
progress screen), D (conversation-screen trigger), E (ModelRegistry
resolves its root from the unpacked `speech` group).

## User prompt (verbatim)

> yes behaves exactly like today.
> And we need to preserve app_config.json to less than 1kb, so it is
> possible with this limitation?

# Phased unpacking, Stage B — Flutter installer phase filter

Stage A put `group` + `unpack_phase` into the `.dat` manifest
(C++ side). Stage B teaches the Flutter installer to read them and
unpack only the packs whose phase matches the current pass. The
splash now installs only `unpack_phase == "splash"` packs; the rest
come back `deferred`, to be unpacked on-demand later (Stage C).

## Changes

### `datapack_manifest.dart`

`DataPackManifest` gained `group` + `unpackPhase`. `parse()` reads
`group` / `unpack_phase` from the JSON; both optional — a manifest
without them defaults to `core` / `splash` (older packs behave
exactly as before). `unpack_phase` is validated against
`{splash, on-demand}`.

### `datapack_factory.dart` — new `readPackManifest(packPath)`

A top-level function that reads **only** the 64-byte header + the
(plaintext) manifest section of a `.dat` — no signature check, no
decrypt, no whole-file read, no keys needed. The installer uses it
to learn a pack's phase cheaply before deciding whether to touch it.
The real security gate (cert chain + signature) still runs inside
`DataUnpackFactory.unpack`; the manifest peeked here is routing
metadata only.

### `datapack_installer.dart`

- New enum value `DataPackInstallStatus.deferred` — "skipped, not
  this run's phase".
- `installPending({String phase = 'splash'})`:
  - For each `.dat`, `readPackManifest` first. Unreadable manifest →
    `failed`.
  - `manifest.unpackPhase != phase` → `deferred`, left untouched
    (no hash, no unpack).
  - Otherwise the existing hash → cached-check → unpack flow.
- Summary log now includes the `deferred` count.

### `datapack_provider.dart`

`_installOnIsolate` calls `installPending()` — which defaults to
`phase: "splash"`, so the splash pass installs only splash-phase
packs. On-demand packs come back `deferred`.

### Splash — no change needed

`_runDataPackInstall` filters outcomes for `status == failed`.
`deferred` ≠ `failed`, so deferred packs are correctly ignored — no
false failure banner. The installer's `dpLog` already reports the
deferred count.

## Backward compatibility

A `.dat` whose manifest has no `group` / `unpack_phase` reads back as
`core` / `splash` → it matches the splash pass → installed at splash,
exactly as before Stage A/B. Every existing pack keeps working
untouched. Confirmed: the 4 pre-existing datapack tests all still
pass.

## Tests

`installer_test.dart`:
- `_pack` helper gained optional `group` / `unpackPhase` params.
- New test `installer: phase filter — splash installs, on-demand
  deferred`: packs a `splash` bundle + an `on-demand` bundle; the
  splash pass installs the first and `deferred`s the second; the
  on-demand pass then installs the second.

## Verification

```text
flutter analyze lib/core/datapack/ lib/features/splash/ test/datapack/
    → No issues
flutter test test/datapack/   → 5/5 pass
```

The new test's log confirms the filter:
`installer: done — 1 installed, 0 cached, 1 deferred, 0 failed`.

## Next — Stage C

`ensureGroup(group, onProgress)` for the on-demand path + a reusable
0–100% progress screen. Then D (conversation-screen trigger) and E
(ModelRegistry resolves its root from the unpacked `speech` group).

## User prompt (verbatim)

> go Stage B

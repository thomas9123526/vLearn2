# DataManage — per-bundle pack_mode override

## What changed

`config.json` now supports a **per-bundle `pack_mode`** that overrides
the top-level one. A bundle without its own block inherits the global
pack_mode; a bundle with one overrides it (sub-fields it omits still
inherit the global). One config, one `DataManage.exe pack` run, mixed
compression/encryption per bundle.

This came straight out of the admin's workflow problem: model bundles
should be `encrypt: "none"` (fast unpack), but they wanted the option
of an encrypted bundle in the same run without juggling two config
files.

## Schema

```jsonc
{
  "version": 1,
  "pack_mode": { "compress": "zlib", "encrypt": "none" },   // global default
  "signing": { ... },
  "bundles": [
    { "name": "out_model", "source_dir": "...", "out_folder": "models" },
      // ^ no pack_mode → inherits global (zlib / none)
    { "name": "out_secret", "source_dir": "...", "out_folder": "secret",
      "pack_mode": { "compress": "zlib", "encrypt": "aes-256-gcm" } }
      // ^ overrides → compressed + encrypted
  ],
  "output_dir": "./output"
}
```

## Files changed

### `src/config.h`

- Moved `PackMode` declaration above `BundleConfig` (BundleConfig now
  has a `PackMode` member).
- `BundleConfig` gained `PackMode pack_mode` — always fully populated
  after `loadConfig()` (either the bundle's own or a copy of the
  global).
- Fixed stale comments (`.ddp` → `.dat`, `"zstd"` → `"zlib"`).

### `src/config.cpp`

- New `parsePackMode(json, fallback, field)` helper — parses +
  validates a `pack_mode` object, inheriting any omitted sub-field
  from `fallback`. Used for both the global block (fallback =
  built-in defaults) and per-bundle blocks (fallback = resolved
  global).
- Top-level `pack_mode` parsed through the helper.
- In the bundle loop: if the bundle JSON has a `pack_mode` key, parse
  it with the global as fallback; otherwise copy the global whole.
  Error messages name the bundle, e.g.
  `bundles["out_secret"].pack_mode.encrypt must be one of {…}`.

### `src/packer.cpp`

- `packAll` now passes `b.pack_mode` (the per-bundle resolved mode)
  to `packBundle` instead of `config.pack_mode`.

### `config.example.json`

- Top-level `pack_mode` set to `encrypt: "none"` (the fast default).
- Added a third bundle `out_secret` demonstrating a per-bundle
  `pack_mode` override that turns encryption back on.
- Dropped the dead `encrypt_options` block — it was a leftover from
  the abandoned "partial encryption" design and was never read by
  `config.cpp`.

## No Flutter changes

The `.dat` format is self-describing — each file's header flags +
manifest record exactly what was done to it. The Flutter unpacker
reads each pack independently and doesn't care that two packs in the
same run used different modes. The Dart side never reads
`config.json` at all (that's C++-only). Zero Flutter changes.

## Verification

```text
cmake --build build-x64 / build-x86  →  clean
manifest_smoke_test  →  PASS (x64)
packer_smoke_test    →  PASS (x64 + x86)
flutter test test/datapack/  →  4/4 pass
```

Real per-bundle CLI run — one config, global `zlib`/`none`, with one
bundle overriding to `aes-256-gcm`:

```text
models_bundle.dat  flags=1   (compressed only — inherited global)
secret_bundle.dat  flags=3   (compressed + encrypted — its override)
```

flags bit 0 = compressed, bit 1 = encrypted. Confirms the inherit /
override split works end-to-end.

(One pre-existing C4244 warning in packer_smoke_test.cpp on the x86
build — uint64_t→size_t in test code, tiny test values, unrelated to
this change. Left alone.)

## User prompt (verbatim)

> Can i set pack_mode per bundle in config.json?
>
> yes

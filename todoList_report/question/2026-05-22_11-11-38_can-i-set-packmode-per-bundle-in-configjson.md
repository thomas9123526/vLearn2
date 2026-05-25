# Can i set pack_mode per bundle in config.json?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T02:11:38.239Z

## User

Can i set pack_mode per bundle in config.json?

## Assistant

Not currently — `pack_mode` is a single global block, applied to every bundle in the run. That's the limitation I flagged last message ("one `pack_mode` for the whole run → two config files").

But it's a small, clean change to make it per-bundle. Here's the design:

## Proposed: global default + per-bundle override

```jsonc
{
  "version": 1,
  "pack_mode": { "compress": "zlib", "encrypt": "none" },   // default for all bundles
  "signing": { "cert_path": "...", "key_path": "..." },
  "bundles": [
    {
      "name": "sherpa_models",
      "source_dir": "C:/data/models",
      "out_folder": "models"
      // no "pack_mode" → inherits the global one (zlib / none) → fast
    },
    {
      "name": "secret_stuff",
      "source_dir": "C:/data/secret",
      "out_folder": "secret",
      "pack_mode": { "compress": "zlib", "encrypt": "aes-256-gcm" }   // override
    }
  ]
}
```

- A bundle **with** a `pack_mode` block uses its own.
- A bundle **without** one inherits the top-level `pack_mode`.
- Top-level `pack_mode` stays optional and still defaults to `compress: "none", encrypt: "none"`.

## Why it's small

- **C++ only.** The `.dat` format is self-describing — each file's header flags + manifest already record exactly what was done to it. The Flutter unpacker reads each pack independently and doesn't care that two packs in the same run used different modes. **Zero Flutter changes.**
- `config.cpp`: parse the global `pack_mode`, then per bundle — if it has a `pack_mode` key, parse+validate it; else copy the global. Each `BundleConfig` ends up with a fully-resolved `PackMode`.
- `packer.cpp`: `packAll` currently passes `config.pack_mode` to every `packBundle`. Change it to pass `bundle.pack_mode` (the resolved per-bundle one).
- ~30 lines total. Both smoke tests still pass unchanged (they use the default path).

## This solves your exact situation

One config, one `DataManage.exe pack` run:
- model/font bundles → `encrypt: "none"` → fast install
- anything sensitive → `encrypt: "aes-256-gcm"`

No more juggling two config files.

Want me to implement it? If yes I'll also update `config.example.json` and the README so the per-bundle override is documented.

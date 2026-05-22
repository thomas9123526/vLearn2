# I see the  unpack progress and the decrypt part takes long time.  So When I pack

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T02:10:19.466Z

## User

I see the  unpack progress and the decrypt part takes long time. 
So When I pack files , is there a option to do only compress , not do encrypt? So unpacking speed is fast then encrypt option. suggest me

## Assistant

Yes — that option **already exists**, no code change needed. Just set `encrypt` to `"none"` in your `config.json`.

## The one-line change

```jsonc
"pack_mode": {
  "compress": "zlib",
  "encrypt":  "none"      // ← was "aes-256-gcm"
}
```

**Keep the `signing` block.** The Flutter unpacker still *requires* a valid signature — it refuses unsigned packs (`.dat is unsigned (refused in production)`). So:

```json
{
  "version": 1,
  "pack_mode": { "compress": "zlib", "encrypt": "none" },
  "signing": {
    "cert_path": "ca/issued/admins/alice/admin.crt",
    "key_path":  "ca/issued/admins/alice/admin.key"
  },
  "bundles": [ ... ],
  "output_dir": "./output"
}
```

`compress: "zlib"` + `encrypt: "none"` + signing = **signed, compressed, not encrypted.**

## Why this is faster

The Flutter unpack does several passes over the data. Rough pure-Dart speeds on a phone:

| Pass | Speed | Needed when |
| --- | --- | --- |
| AES-256-GCM decrypt | **~10–50 MB/s** ← the bottleneck | `encrypt: "aes-256-gcm"` |
| zlib inflate | ~50–150 MB/s | `compress: "zlib"` |
| SHA-256 (signature + per-file verify) | ~100–200 MB/s | always |

Dropping encryption removes **the slowest pass entirely**. For your sherpa models, expect roughly **2–4× faster** unpack. The per-file log line goes from:

```
(read → decrypt → inflate → sha256 OK)
```
to:
```
(read → inflate → sha256 OK)
```

## The trade-off — and why it's fine for you

| | Encrypted | Not encrypted (signed only) |
| --- | --- | --- |
| Tampering / forgery | rejected (signature) | **rejected (signature)** — unchanged |
| Came from you, untampered | guaranteed | **guaranteed** — unchanged |
| Someone pulls the `.dat` off the sdcard | can't read contents | can decompress + read the model files |

The **only** thing you lose is confidentiality of the bytes-at-rest. For **sherpa-onnx models** that's a non-loss — they're publicly downloadable models, not secrets. The signature still guarantees nobody can swap in a malicious model.

Encryption only mattered for your earlier "anti-casual-poking" requirement. If you don't actually need the model files hidden, **signed-only is the right call** — same security against tampering, much faster install.

## My suggestion

Use **two pack modes depending on the bundle**:

- **Model bundles** (big, not secret) → `encrypt: "none"` — fast install.
- **Anything genuinely sensitive** (if you ever have it) → `encrypt: "aes-256-gcm"` — slower but confidential.

Since `config.json` has one `pack_mode` for the whole run, that means **two config files** (or two runs) — one per mode. For now, if everything you're packing is models/fonts, just flip the single config to `encrypt: "none"` and you're done.

## To apply

1. Edit `config.json` → `"encrypt": "none"`.
2. Re-run `DataManage.exe pack` → produces new `.dat` files (smaller header, no cert-encryption overhead).
3. Replace the files on the device, clear `datapack_state.json`, restart the app.

You should see the splash "Preparing your data…" finish noticeably faster, and the `[datapack]` logs show `[5/6] pack not encrypted — no key derivation` plus per-file lines without the `decrypt` step.

Want me to write you the `encrypt: "none"` config to disk?

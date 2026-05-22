# can u available list for pack_mode ?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T02:35:36.146Z

## User

can u available list for pack_mode ?

## Assistant

`pack_mode` is an object with exactly two fields, each with two valid values:

## `pack_mode.compress`

| Value | Effect |
| --- | --- |
| `"none"` | raw blobs, no compression (default) |
| `"zlib"` | DEFLATE level 9, sets `FLAG_COMPRESSED` |

## `pack_mode.encrypt`

| Value | Effect |
| --- | --- |
| `"none"` | no encryption (default) |
| `"aes-256-gcm"` | ECDH-derived AES-256-GCM, sets `FLAG_ENCRYPTED`, **requires the `signing` block** |

## All 4 valid combinations

```jsonc
{ "compress": "none", "encrypt": "none" }          // raw
{ "compress": "zlib", "encrypt": "none" }          // ← recommended for models (fast unpack)
{ "compress": "none", "encrypt": "aes-256-gcm" }   // encrypted, uncompressed
{ "compress": "zlib", "encrypt": "aes-256-gcm" }   // compressed + encrypted (slowest unpack)
```

## Where `pack_mode` can appear

- **Top-level** — the default for every bundle.
- **Inside a bundle** — overrides the default for that bundle only. Omitted sub-fields inherit the global.

```jsonc
{
  "pack_mode": { "compress": "zlib", "encrypt": "none" },   // global
  "bundles": [
    { "name": "a", ... },                                    // inherits zlib/none
    { "name": "b", ..., "pack_mode": { "encrypt": "aes-256-gcm" } }
      // ← overrides encrypt only; compress still inherits "zlib"
  ]
}
```

## Anything else is rejected

`config.cpp` validates strictly. `"deflate"`, `"gzip"`, `"zstd"`, `"rar"`, `"aes-128-gcm"`, `"chacha20"`, etc. all fail at load with:

```
config: pack_mode.compress must be one of {…}, got 'gzip'
```

So the complete list is: **compress ∈ {`none`, `zlib`}**, **encrypt ∈ {`none`, `aes-256-gcm`}**. Two each, four combinations.

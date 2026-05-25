# what are the types for compress and encrypt? give me all list.

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T14:16:27.600Z

## User

what are the types for compress and encrypt? give me all list.

## Assistant

Two each. That's the whole list — anything else is rejected by `config.cpp::validateAlgo`.

## `pack_mode.compress`

| Value | What it does |
| --- | --- |
| `"none"` | Each blob written as raw plaintext. `stored_size == size`. |
| `"zlib"` | Each blob run through DEFLATE at level 9, RFC 1950 zlib stream format. Sets `FLAG_COMPRESSED` in the header. |

## `pack_mode.encrypt`

| Value | What it does |
| --- | --- |
| `"none"` | No encryption. |
| `"aes-256-gcm"` | Generates a per-pack ephemeral ECDH P-256 keypair against the admin's cert pubkey, runs the shared secret through HKDF-SHA-256 → 32-byte AES-256 key, then each blob is AES-256-GCM with a fresh random 12-byte IV + 16-byte tag. Sets `FLAG_ENCRYPTED` in the header. **Requires the `signing` block.** |

## So the only valid combinations are

```text
compress:  none | zlib
encrypt:   none | aes-256-gcm
```

→ 4 combinations:

| compress | encrypt | Use case |
| --- | --- | --- |
| `none` | `none` | dev / smoke tests only — unsigned packs |
| `zlib` | `none` | signed-but-public packs (integrity, not confidentiality) |
| `none` | `aes-256-gcm` | rare — encrypted but uncompressed (e.g. already-compressed payloads) |
| `zlib` | `aes-256-gcm` | recommended for production |

Anything else — `"deflate"`, `"gzip"`, `"zstd"`, `"rar"`, `"aes-128-gcm"`, `"chacha20"`, etc. — will fail config validation immediately with a message like:

```
config: pack_mode.compress must be one of {…}, got 'gzip'
```

Adding new algorithms means changing **both** sides: `datamanage/src/{config,manifest,packer}.cpp` on the pack side, plus `flutter_app/lib/core/datapack/datapack_*.dart` on the unpack side. Worth doing if you really need something else, but not a configuration-only change.

# I get error again, can you add option for datamanage to go no compress so when u

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-25T23:47:37.218Z

## User

I get error again, can you add option for datamanage to go no compress so when unpack in the application, datafactory just copy from the .dat file

## Assistant

Let me check the existing pack_mode options in DataManage and what the Flutter unpacker does with them:

## Assistant

Good news — DataManage *already* supports `"compress": "none", "encrypt": "none"` per bundle ([config.cpp:73-76](datamanage/src/config.cpp#L73-L76)). What's missing is a **stream-copy path in the unpacker** for that case — right now it still loads each file blob into RAM. With pure passthrough we can read 64 KB at a time and write straight through, so a single 1 GB file uses ~64 KB of RAM.

Let me read the current per-file loop and add the stream branch:

## Assistant

Clean + 7/7 tests pass. Committing:

## Assistant

Committed as `a13f35b`.

## What you need to do

DataManage already supports it — just update **`config.json`** to turn both transforms off:

```json
{
  "version": 1,
  "pack_mode": { "compress": "none", "encrypt": "none" },
  "signing":  { "cert_path": "...", "key_path": "..." },
  "bundles":  [ ... ]
}
```

(or scope it to one bundle by adding the same `"pack_mode": {...}` block inside that bundle's entry)

Then: **repack → push the new `.dat` to the sdcard → recompile + reinstall the APK → speech setup**.

## What the unpacker does now

The per-file loop branches:

- **passthrough** (compress=none AND encrypt=none) → reads the blob in 64 KB chunks via `File.openRead(start, end)`, writes straight through to disk, hashes on the fly with `package:crypto`. Peak RAM ≈ one chunk — **a 1 GB file is fine**. You'll see this in the logs:
  ```
  unpack:   [6/6] decoding N file(s) (passthrough: stream-copy)…
  unpack:   [1/2] foo.onnx  (stream-copy 524288000B → sha256 OK)  →  …
  ```
- **transformed** (any compression or encryption) → unchanged whole-buffer pipeline.

If the hash doesn't match, the partial output file is deleted before throwing — no half-written files left behind.

## Trade-offs of passthrough mode

- The `.dat` is **bigger** (no zlib — though `.onnx` weights barely compress anyway) and **plaintext** (no AES).
- The pack is **still signed** — admin cert + ECDSA chain, exactly as before — so tampering is still detected. Only confidentiality is dropped, not authenticity. For shipping AI model weights this is usually the right trade.

`flutter analyze` clean, 7/7 datapack tests pass.

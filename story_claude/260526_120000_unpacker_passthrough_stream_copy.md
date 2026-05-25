# Datapack unpacker — passthrough stream-copy for big files

## The ask

> can you add option for datamanage to go no compress so when unpack
> in the application, datafactory just copy from the .dat file

DataManage *already* supports `"compress": "none"` and `"encrypt":
"none"` per bundle ([config.cpp:73-76](../datamanage/src/config.cpp#L73-L76))
— the missing half was on the Flutter side: even with both transforms
off, the unpacker still loaded each file's whole blob into a single
`Uint8List` before writing it, so a single multi-hundred-MB file
still OOM'd the process.

## Fix — per-file passthrough path in `datapack_factory.dart`

The per-file loop now branches on whether any transform is in play:

```dart
final passthrough = aesKey == null && !hdr.isCompressed;
```

- **passthrough (compress=none AND encrypt=none)** — stream the blob
  from the `.dat` straight to the output file via
  `File.openRead(start, end)` (Dart-chunked) → `IOSink.add`, with
  `package:crypto.sha256.startChunkedConversion` updating the file
  hash on the same chunks. Peak RAM ≈ one chunk; a 1 GB file is fine.
  If the final SHA-256 doesn't match the manifest, the partial output
  is deleted before throwing.
- **transformed (compress=zlib or encrypt=aes-256-gcm)** — unchanged
  whole-buffer path: load blob → decrypt → inflate → hash → write.

A sanity check rejects a pack that claims passthrough mode but has
`storedSize != size` (a packer/unpacker disagreement that would
otherwise silently truncate or pad files).

The new code path is logged so a passthrough pack is obvious in the
trace:

```
unpack:   [6/6] decoding N file(s) (passthrough: stream-copy)…
unpack:   [1/2] foo.onnx  (stream-copy 524288000B → sha256 OK)  →  …
```

## How to use it

In DataManage `config.json`, set both algorithms to `"none"`:

```json
{
  "version": 1,
  "pack_mode": { "compress": "none", "encrypt": "none" },
  "signing":  { "cert_path": "...", "key_path": "..." },
  "bundles":  [ … ]
}
```

…or scope it to a single bundle:

```json
{
  "name": "sherpa_models",
  "source_dir": "…",
  "out_folder": "models/sherpa_xxx",
  "pack_mode": { "compress": "none", "encrypt": "none" },
  "group": "speech",
  "unpack_phase": "on-demand"
}
```

Repack → drop the new `.dat` on the device → speech setup → the
unpacker logs `passthrough: stream-copy` and copies in chunks. No
size ceiling from the unpacker side.

## Trade-offs

- The `.dat` is **larger on disk** (no zlib) and **plaintext** (no
  AES). Pick this mode when the files are already compressed
  (`.onnx` weights are basically incompressible anyway) and the
  contents aren't confidential.
- The pack is still **signed** — admin cert + ECDSA over the full
  prefix, exactly as before — so tampering is still detectable. Only
  *encryption* is dropped, not authenticity.

## Verification

```text
flutter analyze lib/core/datapack/  → No issues found
flutter test test/datapack/         → 7/7 pass
```

The existing tests cover the transformed path. The passthrough path
will get its own coverage once the user confirms it unblocks them.

## User prompt (verbatim)

> I get error again, can you add option for datamanage to go no
> compress so when unpack in the application, datafactory just copy
> from the .dat file

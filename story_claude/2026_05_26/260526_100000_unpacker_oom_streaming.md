# Datapack unpacker — fix "Out of Memory" on 2.dat

## The error

> Speech setup failed — `2.dat: Out of Memory`

When the user packed new files into a `2.dat` with DataManage and the
Flutter unpacker tried to extract it on Android, the unpack crashed
with an `OutOfMemoryError`.

## Cause

`DataUnpackFactory.unpack()` started with:

```dart
final pack = Uint8List.fromList(await File(packPath).readAsBytes());
```

That loads the **entire `.dat` into a Dart `Uint8List`** before doing
anything. `readAsBytes()` already allocates a `Uint8List` of the full
file size, and `Uint8List.fromList(...)` then copies it — so peak
RAM is briefly 2× the pack size. A multi-hundred-MB speech pack
easily blows past Android's per-process heap limit.

`_digestOverPack` then built a second pack-sized buffer (`BytesBuilder`
concatenating header + manifest + data + cert) just to feed SHA-256.

## Fix

Refactored the unpacker to stream. New shape:

- Open the `.dat` once as a `RandomAccessFile`; keep it open through
  the whole unpack.
- Read **only the small fixed sections** into memory: 64-byte header,
  manifest JSON, X.509 cert.
- For signature verification, stream-hash
  `header_with_sig_zeroed ‖ manifest ‖ data ‖ cert` — the data
  section is read in **64 KB chunks** straight into a `Sha256Streamer`
  (new in `datapack_crypto.dart`, wraps pointycastle's
  `SHA256Digest.update / doFinal`).
- For each manifest file, **seek to its blob, read only that blob**,
  decrypt → inflate → hash → write. The pack as a whole is never in
  memory.

Peak RAM is now bounded by:
- one 64 KB hash chunk during verification, plus
- one file's encrypted + decrypted + decompressed bytes during decode.

…instead of "the entire pack, twice."

## What I did NOT change

- The signed-prefix layout (`header_with_sig_zeroed ‖ manifest ‖
  data ‖ cert`) is identical, so packs signed by the C++ packer still
  verify byte-for-byte.
- Per-file encrypt/inflate are still whole-buffer. For a *single*
  file bigger than ~150 MB this is still tight; if the user ever hits
  that ceiling, streaming AES-GCM + zlib would be the follow-up.

## Files

- `flutter_app/lib/core/datapack/datapack_crypto.dart` — added
  `Sha256Streamer`.
- `flutter_app/lib/core/datapack/datapack_factory.dart` — rewrote
  `DataUnpackFactory.unpack()`; replaced `_digestOverPack` with a
  streaming `_streamedDigest`.

## Verification

```text
flutter analyze lib/core/datapack/   → No issues found
flutter test test/datapack/          → 7/7 pass
```

The tests exercise the full pipeline (header, manifest, cert chain,
ECDSA signature, AES-GCM decrypt, zlib inflate, SHA-256 verify,
disk write) — all still green, so the streamed digest is producing
the same bytes the old `BytesBuilder` digest did.

## User prompt (verbatim)

> I get "out of memory", when extracting /sdcard/룡마/가상외국어회화/data/2.dat
> I pack new files with datamanage

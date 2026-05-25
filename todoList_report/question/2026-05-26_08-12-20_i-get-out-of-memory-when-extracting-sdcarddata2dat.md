# I get "out of memory", when extracting /sdcard/룡마/가상외국어회화/data/2.dat I pack new 

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-25T23:12:20.349Z

## User

I get "out of memory", when extracting /sdcard/룡마/가상외국어회화/data/2.dat
I pack new files with datamanage

## Assistant

Found the cause — line 93 reads the **entire .dat into RAM** in one shot:

```dart
final pack = Uint8List.fromList(await File(packPath).readAsBytes());
```

For a multi-hundred-MB pack this exhausts the Android heap. `_digestOverPack` then builds *another* full-pack-sized buffer to hash. Let me check the crypto helpers so I can stream them:

## Assistant

Now I'll fix it. Plan:
1. Add a streaming `Sha256Streamer` to the crypto helpers.
2. Rewrite `unpack()` to use a `RandomAccessFile` — read sections on demand, stream-hash the data section in 64 KB chunks, decode one file at a time. Peak memory drops from "whole pack" to "one file's blob."

## Assistant

All 7 datapack tests pass. Let me commit:

## Assistant

Committed as `3ee32c3`.

**Cause:** [datapack_factory.dart:93](flutter_app/lib/core/datapack/datapack_factory.dart#L93) used to start with `Uint8List.fromList(await File(packPath).readAsBytes())` — loading the **entire `.dat` into RAM** before doing anything (and briefly doubling it via the `fromList` copy). For a multi-hundred-MB pack on Android, that overruns the per-process heap.

**Fix — stream everything:**

- Open the `.dat` as a `RandomAccessFile` and keep it open through the whole unpack.
- Read only the small fixed sections into memory: 64-byte header, manifest JSON, X.509 cert.
- For signature verification, **stream-hash** `header_with_sig_zeroed ‖ manifest ‖ data ‖ cert` — the data section is read in **64 KB chunks** into a new `Sha256Streamer` (wraps pointycastle's `SHA256Digest.update/doFinal`).
- For each manifest file, **seek to its blob, read only that blob**, decrypt → inflate → hash → write. The pack as a whole is never resident.

Peak RAM is now bounded by **one 64 KB hash chunk + one file's encrypted/decrypted/decompressed bytes**, instead of "the entire pack, twice."

The signed-prefix byte layout is unchanged, so packs from the C++ packer still verify byte-for-byte. `flutter analyze` clean, all 7 datapack tests pass.

If a *single* file in a pack ever exceeds ~150 MB you might still hit a ceiling — at that point we'd need streaming AES-GCM + zlib too. Let me know if you see it.

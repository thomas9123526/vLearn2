# Datapack unpacker — diagnostics + faster streaming hash

## The problem

After the streaming-unpack fix, the user reported:

> The app closed unexpectedly.
> when "unpack: START /storage/emulated/0/룡마/가상외국어회화/data/2.dat"

The previous logs jump straight from `unpack: START` to
`unpack: [1/6] header OK …` and then are silent for the whole
signature hash. With a multi-hundred-MB data section that silent gap
can be 30 s+ of pure-Dart SHA-256, which looks indistinguishable from
a crash — and there are several spots between log lines where a
corrupt header could still OOM the process.

## Changes — `datapack_factory.dart`

### Diagnostics (so we can see where it really dies)

- **Pack size logged up front** (`bytes` + `MB`).
- **Every header field logged** after parse: manifest / data / cert /
  sig — offset and length.
- **Each manifest file's stored + plain size logged** before decode —
  a single huge file is the remaining OOM ceiling and now visible
  before we touch it.
- **Hash progress logged every 32 MB** — a multi-hundred-MB hash no
  longer looks like a hang.

### Sanity check on the header

Before any `raf.read(len)`, every declared section is range-checked
against the file size:

```dart
checkRange('manifest', hdr.manifestOffset, hdr.manifestLen);
checkRange('data',     hdr.dataOffset,     hdr.dataLen);
…
```

A corrupt or mis-packed header that previously sent `raf.read(2GB)`
off to allocate (and OOM the process) now throws a clean
`FormatException` with the offending field name.

### Faster, lower-overhead streaming hash

`_streamedDigest` rewritten to use **`package:crypto`'s
`sha256.startChunkedConversion`** fed by **`File.openRead(start,
end)`** instead of a hand-rolled loop over `RandomAccessFile.read`:

- `package:crypto` is the standard SDK SHA-256 — better-tuned than
  the pointycastle path for multi-hundred-MB inputs.
- `File.openRead(start, end)` gives a `Stream<List<int>>` that Dart
  chunks for us, so the hash consumes the data section without ever
  materialising it.
- Manifest + cert are still added directly (small, already in memory);
  only the large data section flows through the stream.

`Sha256Streamer` in `datapack_crypto.dart` is left in place — it was
introduced in the prior commit, is still a valid streaming helper,
and removing it now would be churn.

## What I did NOT change

- The signed-prefix byte layout is identical; existing `.dat`s still
  verify byte-for-byte. **No repack needed.**
- Per-file decrypt/inflate are still whole-buffer. If a single file
  in the pack exceeds the heap, that's the next ceiling — the new
  per-file size log will now make this visible *before* the decode,
  so a future failure mode is obvious in the trace.

## Verification

```text
flutter analyze lib/core/datapack/  → No issues found
flutter test test/datapack/         → 7/7 pass
```

## What the user should do

Recompile + reinstall, run Speech setup once more, and report the
**last `[datapack]` line in the log before the crash**. Combined with
the new pack-size and per-file-size lines, that pinpoints whether
we're losing the process to the hash phase or to a specific file's
decode.

## User prompt (verbatim)

> The app closed unexpectidly.
> when "unpack: START /storage/emulated/0/룡마/가상외국어회화/data/2.dat"

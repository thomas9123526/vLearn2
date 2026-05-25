# The app closed unexpectidly. when "unpack: START /storage/emulated/0/룡마/가상외국어회화/

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-25T23:32:44.702Z

## User

The app closed unexpectidly.
when "unpack: START /storage/emulated/0/룡마/가상외국어회화/data/2.dat"

## Assistant

Let me first see what dependencies are available and what `dpLog` looks like, so I can diagnose with more logging plus possibly speed up the hashing:

## Assistant

`crypto` package is already a dep. Let me make several diagnostic improvements: log file size early, log every step, and switch the streaming hash to `package:crypto` + `File.openRead` (faster + uses Dart's native stream chunking instead of my manual loop).

## Assistant

Clean + 7/7 tests pass. Let me commit:

## Assistant

Committed as `b34a456`.

## What I changed and why

The previous "OOM fix" left a long silent gap between `unpack: START` and `[1/6] header OK …` — actually the gap is fine, but the **bigger gap is between `[3/6] cert chain OK` and `[4/6] signature OK`** where pure-Dart SHA-256 hashes the entire data section. On a multi-hundred-MB pack that's 30 s+ of silent CPU, and **a corrupt header field could still send `raf.read(huge)` off to OOM the process**.

Three things changed in [datapack_factory.dart](flutter_app/lib/core/datapack/datapack_factory.dart):

1. **Loud logging** — pack file size, every header offset/length, every manifest file's stored + plain size, and a hash-progress line every 32 MB. Now the trace pinpoints exactly where a future crash happens.

2. **Header sanity check** — every declared section (`manifest`/`data`/`cert`/`sig`) is range-checked against the file size before any `raf.read(len)`. A bad header that previously triggered a multi-GB allocation now throws a clean `FormatException`.

3. **Faster streaming hash** — `_streamedDigest` now uses `package:crypto`'s `sha256.startChunkedConversion` fed by `File.openRead(start, end)`. The data section flows through a `Stream<List<int>>` Dart chunks for us — no manual `while` loop, less per-iteration overhead, and `package:crypto` is the SDK's standard SHA-256 (better-tuned than the pointycastle path I used last commit).

`flutter analyze` clean. 7/7 datapack tests pass. **No repack needed** — the signed bytes are unchanged.

## Next step

Recompile, reinstall, run Speech setup, and tell me the **last `[datapack]` line you see before the app dies**. With the new pack-size + per-file-size + hash-progress lines, that single log entry will tell us whether the failure is in the hash phase or a specific file's decode — and if it's a single huge file (≥150 MB), that's the next ceiling and we'll know what to fix.

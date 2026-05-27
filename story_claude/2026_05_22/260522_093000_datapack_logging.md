# Datapack pipeline — verbose `[datapack]` logging

## What changed

Added step-by-step logging across the whole `.ddp` install + unpack
flow so it's visible in `flutter logs` / logcat exactly:

- where the sdcard folder is and where decoded files go,
- when the scan starts and what it finds,
- when each unpack starts and finishes,
- every step + every file as it's processed.

## Files

### `lib/core/datapack/datapack_log.dart` (new)

One-liner shared logger:

```dart
void dpLog(String message) => debugPrint('[datapack] $message');
```

`debugPrint` (not `print`) so logcat's burst-throttling doesn't drop
lines. Single `[datapack]` tag — filter with
`flutter logs | findstr "[datapack]"`. Logs stay on in release too:
the install pass runs once at startup, volume is tiny, and the trace
is worth having for field diagnostics.

### `datapack_paths.dart`

`resolve()` now logs, on both Android and Windows:

```
[datapack] paths: platform=Android, MANAGE_EXTERNAL_STORAGE granted=true
[datapack] paths: using PUBLIC path
[datapack] paths: .ddp folder (drop files here) = /storage/emulated/0/룡마/가상외국어회화/datapacks
[datapack] paths: decoded files go to          = /data/.../datapack_unpacked
[datapack] paths: install state file           = /data/.../datapack_state.json
```

If the permission isn't granted it says so explicitly and prints the
fallback path — directly answers "where is the sdcard folder, and
where do decoded files go?".

### `datapack_installer.dart`

`installPending()` logs:

```
[datapack] installer: scanning <packsDir>
[datapack] installer: found N .ddp file(s)
[datapack] installer: CACHED  out_font.ddp (sha256 abc123def456… already installed)
[datapack] installer: INSTALL out_model.ddp (sha256 789… — new or changed)
[datapack] installer: OK      out_model.ddp → bundle "out_model", 12 file(s)
[datapack] installer: FAILED  bogus.ddp — FormatException: bad magic …
[datapack] installer: done — 1 installed, 1 cached, 1 failed. State saved to …
```

When no packs are found it prints a "drop .ddp files into <dir> and
relaunch" hint.

### `datapack_factory.dart`

`unpack()` logs START, six numbered steps, every file, and DONE:

```
[datapack] unpack: START /sdcard/.../out_model.ddp
[datapack] unpack:   → output root /data/.../datapack_unpacked
[datapack] unpack:   read 5242880 bytes from disk
[datapack] unpack:   [1/6] header OK — version 1, compressed=true, encrypted=true, signed=true
[datapack] unpack:   [2/6] manifest OK — bundle "out_model", 12 file(s), compression=zlib, encryption=aes-256-gcm
[datapack] unpack:   [3/6] cert chain OK — admin cert chains to pinned root
[datapack] unpack:   [4/6] signature OK — ECDSA verifies against admin cert
[datapack] unpack:   [5/6] AES-256 key derived via ECDH + HKDF
[datapack] unpack:   [6/6] decoding 12 file(s)…
[datapack] unpack:   [1/12] models/encoder.onnx  (read 1048576B → decrypt → inflate→2097152B → sha256 OK)  →  /data/.../datapack_unpacked/models/encoder.onnx
[datapack] unpack:   [2/12] models/decoder.onnx  (…)
...
[datapack] unpack: DONE "out_model" — 12 file(s) written under /data/.../datapack_unpacked
```

Each file's line shows the exact transform chain that ran
(`read → decrypt → inflate → sha256 OK`), the byte sizes at each
stage, and the final output path. A failed file logs a `FAIL` line
naming what mismatched before the exception propagates.

## Verification

```text
flutter analyze lib/core/datapack/  →  No issues found
flutter test test/datapack/         →  All tests passed (4/4)
```

The test run output confirms the logs fire — visible
`[datapack] installer: …` and `[datapack] unpack: …` lines
interleaved with the test progress.

## How to watch the logs on a device

```powershell
flutter logs                       # all logs from the running app
# filter to just datapack lines:
flutter logs | Select-String "\[datapack\]"
# or via adb:
adb logcat -s flutter | findstr "[datapack]"
```

## User prompt (verbatim)

> I want print log when read files to answer "where is the sdcard
> folder, and where do decoded files go?".
> Also I want print log when the unpack starts and when unpack
> finishes.
> Print logs each step, each files while unpacking.

# so where is the part for unpack the sdcard data

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T00:22:34.794Z

## User

so where is the part for unpack the sdcard data

## Assistant

The unpacking is spread across four files by responsibility. Here's the full trace, with the actual call path:

## The flow, top to bottom

```text
splash_screen.dart  _runDataPackInstall()         ← TRIGGER (on app launch)
   │
   ▼
datapack_provider.dart  installPendingDataPacksProvider
   │
   ▼
datapack_paths.dart  DataPackPaths.resolve()       ← FINDS the sdcard folder
   │
   ▼
datapack_installer.dart  installPending()          ← SCANS sdcard for *.ddp
   │
   ▼
datapack_factory.dart  unpack()                    ← ACTUALLY unpacks one .ddp
```

## File by file — what each does

### 1. [datapack_paths.dart](flutter_app/lib/core/datapack/datapack_paths.dart) — *where* the sdcard data is

The file you have open. It only **resolves paths** — it doesn't unpack anything. `DataPackPaths.resolve()` returns three locations:

- `packsDir` → `/storage/emulated/0/룡마/가상외국어회화/datapacks/` (where you drop `.ddp` files)
- `unpackedRoot` → `<appSupport>/datapack_unpacked/` (where decoded files land)
- `stateFile` → `<appSupport>/datapack_state.json` (tracks what's been done)

### 2. [datapack_installer.dart](flutter_app/lib/core/datapack/datapack_installer.dart) — *scans* the sdcard

`DataPackInstaller.installPending()` is the part that **reads the sdcard folder**:

Let me show you the exact lines.

## Assistant

- **[datapack_installer.dart:81-86](flutter_app/lib/core/datapack/datapack_installer.dart#L81-L86)** — lists `packsDir` (the sdcard folder), filters to `*.ddp`.
- **[datapack_installer.dart:90-101](flutter_app/lib/core/datapack/datapack_installer.dart#L90-L101)** — SHA-256 each pack, skip if already in `datapack_state.json` (→ `cached`).
- **[datapack_installer.dart:104-107](flutter_app/lib/core/datapack/datapack_installer.dart#L104-L107)** — calls `factory.unpack()` for new packs. **This is the line that hands one .ddp to the actual unpacker.**

### 3. [datapack_factory.dart](flutter_app/lib/core/datapack/datapack_factory.dart) — *unpacks* one `.ddp`

`DataUnpackFactory.unpack()` is **the actual extraction** — read bytes, verify chain, verify signature, ECDH→HKDF→AES decrypt, zlib inflate, SHA-256 verify, write files:

## Assistant

## Direct answer to "where is the part for unpack the sdcard data"

| What | File | Function / lines |
| --- | --- | --- |
| **Triggers it on app launch** | [splash_screen.dart](flutter_app/lib/features/splash/splash_screen.dart) | `_runDataPackInstall()` |
| **Finds the sdcard folder** | [datapack_paths.dart](flutter_app/lib/core/datapack/datapack_paths.dart) | `DataPackPaths.resolve()` → `packsDir` |
| **Scans the sdcard for `.ddp` files** | [datapack_installer.dart](flutter_app/lib/core/datapack/datapack_installer.dart) | `installPending()`, [lines 81-86](flutter_app/lib/core/datapack/datapack_installer.dart#L81-L86) |
| **Unpacks one `.ddp`** | [datapack_factory.dart](flutter_app/lib/core/datapack/datapack_factory.dart) | `unpack()` — the whole method |
| **The actual decrypt + decompress + write loop** | [datapack_factory.dart:119-151](flutter_app/lib/core/datapack/datapack_factory.dart#L119-L151) | the `for (final mf in manifest.files)` loop |

## The "extraction" in one place

The real work — read encrypted blob from the `.ddp`, AES-GCM decrypt, zlib inflate, SHA-256 verify, write to disk — is the loop at [datapack_factory.dart:119-151](flutter_app/lib/core/datapack/datapack_factory.dart#L119-L151):

```dart
for (final mf in manifest.files) {
  Uint8List bytes = stored;                                  // raw blob from .ddp
  if (aesKey != null)   bytes = aesGcmDecrypt(...);           // decrypt
  if (hdr.isCompressed) bytes = ZLibDecoder().decodeBytes();  // decompress
  // ... SHA-256 verify against manifest ...
  await File(outPath).writeAsBytes(bytes, flush: true);       // write to disk
}
```

The lines **before** that loop (in the same `unpack()` method, roughly [lines 40-114](flutter_app/lib/core/datapack/datapack_factory.dart#L40-L114)) do the security gate: parse header → parse manifest → verify cert chain to pinned root → verify ECDSA signature → derive the AES key via ECDH+HKDF.

## So the file you have open (`datapack_paths.dart`) is *not* where unpacking happens

`datapack_paths.dart` only answers **"where is the sdcard folder, and where do decoded files go?"** — it returns paths. The unpacking itself is in `datapack_factory.dart`. The scan-and-dispatch glue is in `datapack_installer.dart`.

If you want to read the unpack logic end-to-end, open **[datapack_factory.dart](flutter_app/lib/core/datapack/datapack_factory.dart)** and read `unpack()` from top to bottom — that's the complete pipeline for one `.ddp` file.

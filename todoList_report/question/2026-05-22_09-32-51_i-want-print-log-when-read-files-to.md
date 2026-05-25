# I want print log when read files to answer "where is the sdcard folder, and wher

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T00:32:51.896Z

## User

I want print log when read files to answer "where is the sdcard folder, and where do decoded files go?" .
Also I want print log when the unpack starts and when unpack finishes.
Print logs each step, each files while unpacking.

## Assistant

Let me check the project's existing logging convention so the new logs match.

## Assistant

Project convention is `debugPrint('[tag] ...')`. Adding a tiny shared `[datapack]` logger, then instrumenting all three files. Let me read the full `unpack()` first so I place step logs correctly.

## Assistant

Now I have the full picture. Creating the shared logger first.

## Assistant

Now instrument `datapack_paths.dart` — log the resolved folders.

## Assistant

Now `datapack_installer.dart` — log the scan + per-pack decisions.

## Assistant

The counters need a summary line. Let me read the tail of the method.

## Assistant

Now `datapack_factory.dart` — log start, each step, each file, finish.

## Assistant

Now the step logs through `unpack()`.

## Assistant

Now per-file logs inside the decode loop + the finish log.

## Assistant

Verify analyze + tests.

## Assistant

All 4 tests pass and the logs print exactly as designed. Committing.

## Assistant

Committed `eb90d22`. **Verbose logging added across the whole datapack pipeline.**

## What you'll see in the logs now

When the app launches, filter the logs to `[datapack]`:

```
[datapack] paths: platform=Android, MANAGE_EXTERNAL_STORAGE granted=true
[datapack] paths: using PUBLIC path
[datapack] paths: .ddp folder (drop files here) = /storage/emulated/0/룡마/가상외국어회화/datapacks
[datapack] paths: decoded files go to          = /data/data/<pkg>/files/datapack_unpacked
[datapack] paths: install state file           = /data/data/<pkg>/files/datapack_state.json
[datapack] installer: scanning /storage/emulated/0/룡마/가상외국어회화/datapacks
[datapack] installer: found 2 .ddp file(s)
[datapack] installer: INSTALL out_font.ddp (sha256 a1b2c3d4e5f6… — new or changed)
[datapack] unpack: START /storage/emulated/0/.../out_font.ddp
[datapack] unpack:   → output root /data/data/<pkg>/files/datapack_unpacked
[datapack] unpack:   read 1234567 bytes from disk
[datapack] unpack:   [1/6] header OK — version 1, compressed=true, encrypted=true, signed=true
[datapack] unpack:   [2/6] manifest OK — bundle "out_font", 12 file(s), compression=zlib, encryption=aes-256-gcm
[datapack] unpack:   [3/6] cert chain OK — admin cert chains to pinned root
[datapack] unpack:   [4/6] signature OK — ECDSA verifies against admin cert
[datapack] unpack:   [5/6] AES-256 key derived via ECDH + HKDF
[datapack] unpack:   [6/6] decoding 12 file(s)…
[datapack] unpack:   [1/12] fonts/Lora.ttf  (read 89234B → decrypt → inflate→218432B → sha256 OK)  →  /data/.../datapack_unpacked/fonts/Lora.ttf
...
[datapack] unpack: DONE "out_font" — 12 file(s) written under /data/.../datapack_unpacked
[datapack] installer: done — 1 installed, 1 cached, 0 failed. State saved to /data/.../datapack_state.json
```

## How to watch them

```powershell
cd c:\project\vLearn2\flutter_app
flutter run -d <device>

# in another terminal — filter to just datapack lines:
flutter logs | Select-String "\[datapack\]"
```

Or via adb directly:
```powershell
adb logcat -s flutter | findstr "[datapack]"
```

## Coverage

| Question | Log line |
| --- | --- |
| Where is the sdcard folder? | `paths: .ddp folder (drop files here) = …` |
| Where do decoded files go? | `paths: decoded files go to = …` |
| Did the permission resolve? | `paths: MANAGE_EXTERNAL_STORAGE granted=…` + `using PUBLIC/FALLBACK path` |
| When does unpack start? | `unpack: START …` |
| When does it finish? | `unpack: DONE … — N file(s) written` |
| Each step | `unpack: [1/6] header OK …` through `[6/6] decoding …` |
| Each file | `unpack: [3/12] fonts/Lora.ttf (read → decrypt → inflate → sha256 OK) → …` |
| Why a pack failed | `installer: FAILED …` + `unpack: [n/N] FAIL … —` |

If a pack is bad, the exact failing step and file are named before the exception surfaces — so the splash's red failure banner gets a precise reason and `flutter logs` shows the full trace.

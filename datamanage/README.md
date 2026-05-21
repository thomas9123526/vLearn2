# DataManage

Windows 10 GUI tool (with optional CLI mode) that packs directories of
files into signed, optionally encrypted, optionally compressed bundles
(`.ddp`) consumed by the Flutter app at first-run.

Built with raw Win32 + Common Controls v6. No external UI framework —
the project builds offline on a fresh Windows 10 box with just
**Visual Studio 2022 + Desktop C++ workload** installed.

## Status

**Stage 1 of 9: project scaffold.**
The window opens, the menu works, About dialog displays. No real
packing yet.

| # | Stage | Lands |
| --- | --- | --- |
| 1 | Project scaffold (Win32 GUI + CLI fallback) | **done** |
| 2 | `.ddp` file format definition (header + manifest) | next |
| 3 | Packer MVP — walk dirs, build manifest, write uncompressed .ddp | |
| 4 | Compression — vendor zstd, compress data blocks | |
| 5 | CA setup — PowerShell scripts: root CA + admin sub-CAs | |
| 6 | Signing — ECDSA P-256 over (header ‖ manifest ‖ data) | |
| 7 | Encryption — AES-256-GCM + ECDH-wrapped session key | |
| 8 | Flutter `DataUnpackFactory` — verify → decompress → write | |
| 9 | App startup wiring — first-run unpack into private storage | |

## Build

Requirements:

- Windows 10 or 11
- Visual Studio 2022 with **Desktop development with C++** workload
- CMake 3.20+ (ships with VS 2022)

### x64

```powershell
cd datamanage
cmake -B build-x64 -G "Visual Studio 17 2022" -A x64
cmake --build build-x64 --config Release
```

Output: `build-x64/bin/Release/DataManage.exe`.

### x86 (Win32)

```powershell
cd datamanage
cmake -B build-x86 -G "Visual Studio 17 2022" -A Win32
cmake --build build-x86 --config Release
```

Output: `build-x86/bin/Release/DataManage.exe`.

Both directories live side-by-side in the same source tree.

### Open in Visual Studio 2022

> File → Open → CMake... → `datamanage/CMakeLists.txt`

VS will create build folders under `out/`. Switch between
`x64-Release` and `x86-Release` from the configuration dropdown.

## Usage

GUI mode — no positional args:

```powershell
.\DataManage.exe
```

CLI mode — any positional arg (or the explicit `--no-gui` flag):

```powershell
.\DataManage.exe pack --config config.json
.\DataManage.exe info <pack.ddp>
.\DataManage.exe verify <pack.ddp>
.\DataManage.exe --help
```

CLI output goes to the parent shell's console via
`AttachConsole(ATTACH_PARENT_PROCESS)`. Launching with no parent
console (e.g. double-click) and CLI args is silently ignored — there's
no popup window.

**Known Win32-subsystem caveat:** PowerShell and `cmd.exe` start
WIN32-subsystem processes asynchronously, so they don't pipe stdout
back into the shell the way they do for CONSOLE-subsystem processes.
To see CLI output:

```powershell
# PowerShell — synchronous + visible
Start-Process -FilePath .\DataManage.exe -ArgumentList 'pack', '--config', 'config.json' -NoNewWindow -Wait
```

```bat
:: cmd.exe — start /wait pins to the parent console
start /wait "" DataManage.exe pack --config config.json
```

Exit codes propagate correctly in both shells regardless. If CLI use
becomes common, a separate CONSOLE-subsystem `DataManage_cli.exe`
target can be added.

## Offline build

After Stages 2–7 land, all third-party source lives under `vendor/`:

| Lib | License | Purpose | Lands at |
| --- | --- | --- | --- |
| `nlohmann_json` | MIT | single-header JSON for the manifest | Stage 2 |
| `mbedtls` | Apache 2.0 | AES-256-GCM, ECDSA P-256, ECDH P-256, X.509 | Stage 4 / 6 / 7 |
| `zstd` | BSD 3-clause | block compression | Stage 4 |

Stage 1 itself has **zero external dependencies** — Win32 API + C++
standard library only. Clone the repo, install VS 2022 with the
desktop C++ workload, run the cmake commands above. No internet
required.

## Pack format (preview — finalised in Stage 2)

```text
+----------------------+
| MAGIC "DDDP" (4)     |  file fingerprint
| version u32          |
| flags u32            |  bit 0 = compressed, bit 1 = encrypted
| manifest_len u32     |
| manifest_offset u64  |
| data_len u64         |
| data_offset u64      |
| sig_len u32          |
| sig_offset u64       |
| cert_len u32         |
| cert_offset u64      |
+----------------------+
| MANIFEST (JSON)      |  list of {name, rel_path, size, sha256,
|                      |          offset_in_data, out_folder}
+----------------------+
| DATA blocks          |  (compressed then encrypted)
+----------------------+
| EMBEDDED CERT (PEM)  |  admin's sub-CA cert + intermediates
+----------------------+
| SIGNATURE            |  ECDSA over SHA-256 of (header ‖ manifest ‖ data)
+----------------------+
```

Self-contained: the Flutter unpacker just calls
`DataUnpackFactory.unpack(packPath)` — names, folder structure, and
`out_folder` for every file all travel inside the manifest.

# DataManage

Windows 10 / VS 2022 C++ command-line tool that packs directories of
files into signed, optionally encrypted, optionally compressed bundles
(`.ddp`) that the Flutter app verifies and unpacks at runtime.

## Status

**Stage 1 of 9: project scaffold.**
Subcommands parse but don't do anything useful yet.

| # | Stage | Lands |
|---|---|---|
| 1 | Project scaffold (CMake + CLI skeleton) | **done** |
| 2 | `.ddp` file format definition (header + manifest) | next |
| 3 | Packer MVP — walk dirs, build manifest, write uncompressed .ddp | |
| 4 | Compression — vendor zstd, compress data blocks | |
| 5 | CA setup — PowerShell scripts: root CA, admin sub-CAs | |
| 6 | Signing — ECDSA P-256 over (header ‖ manifest ‖ data) | |
| 7 | Encryption — AES-256-GCM + ECDH-wrapped session key | |
| 8 | Flutter `DataUnpackFactory` — verify → decompress → write | |
| 9 | App startup wiring — first-run unpack into private storage | |

## Build

Requirements:

- Windows 10 or 11
- Visual Studio 2022 with the **Desktop development with C++** workload
- CMake 3.20+ (ships with VS 2022)

Open in VS 2022:

> File → Open → CMake... → select `datamanage/CMakeLists.txt`

Or from a `Developer PowerShell for VS 2022`:

```powershell
cd datamanage
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```

Result: `build/bin/Release/DataManage.exe`.

## Usage (Stage 1)

```powershell
DataManage --help
DataManage pack --config config.json   # echoes args, packing not implemented yet
DataManage info <pack.ddp>             # not implemented yet
DataManage verify <pack.ddp>           # not implemented yet
```

## Offline build

All third-party code is vendored under `vendor/` as plain source —
nothing is downloaded at build time. After Stages 4 / 7 land, the
project will build on any fresh Windows 10 machine with VS 2022
installed, with no internet access.

Vendored libraries (added in their respective stages):

| Lib | License | Purpose | Lands at |
|---|---|---|---|
| `mbedtls` | Apache 2.0 | AES-256-GCM, ECDSA P-256, ECDH P-256, X.509 | Stage 4 / 6 / 7 |
| `zstd` | BSD 3-clause | block compression | Stage 4 |
| `nlohmann_json` | MIT | single-header JSON for the manifest | Stage 2 |

Stage 1 itself has **zero external dependencies** — standard library
only.

## Pack format (preview — finalised in Stage 2)

```
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

The `out_folder` per-file in the manifest is what makes the bundle
self-contained: the Flutter unpacker calls `unpack(packPath)` and every
file lands where the admin specified, under the app's private storage
root. No extra arguments needed.

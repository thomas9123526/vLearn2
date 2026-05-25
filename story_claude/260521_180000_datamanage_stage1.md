# DataManage — Stage 1: project scaffold

## What landed

A new Windows-only C++ CLI project at `c:\project\vLearn2\datamanage\`,
buildable with Visual Studio 2022 and CMake. Stage 1 of 9 of a longer
plan to build a packing tool ("DataManage") that produces signed,
encrypted, compressed `.ddp` bundles consumed by the Flutter app.

This stage is the scaffold only: CMake build, CLI argument parsing,
"what it would do" stubs. No third-party dependencies yet — Stage 1
builds with the C++ standard library alone.

## Architecture decisions locked in before Stage 1

Captured here for future reference because they shape every later
stage:

| Decision | Pick | Reason |
|---|---|---|
| Project target | Windows 10 + VS 2022 C++20 | matches admin's dev machine |
| Crypto library | **mbedTLS** vendored as source | small (~3 MB), Apache 2.0, X.509 + AES-GCM + ECDSA — same primitives as OpenSSL. Vendored so build is offline-capable on fresh machine |
| Compression | **zstd** vendored | beats zlib on ratio + speed. RAR dropped (licensed for writing) |
| Manifest format | JSON via nlohmann/json (vendored single header) | debuggable, compresses fine |
| Encryption cipher | **AES-256-GCM** full-file | auth + encrypt in one pass. **Partial encryption (encrypt only 4 KB header per 1 MB block) explicitly rejected** — full-file is fast enough on Android (50 MB unpacks in ~20–150 ms on most devices) |
| Key wrap | **ECDH P-256 + HKDF + AES-GCM (ECIES)** | maps to admin's "FastECD" instinct; RSA available as alt if ever wanted |
| Signing | **ECDSA P-256** over SHA-256 of (header ‖ manifest ‖ data) | smaller signatures than RSA, faster verify on Android |
| PKI | Root CA (offline) + admin sub-CAs, X.509 chain | standard PKI, app pins root CA public key |
| Self-contained pack | **yes** — manifest carries names, folder structure, out_folder per file. `DataUnpackFactory.unpack(packPath)` is the only API call |
| Output paths | `out_folder` per-file in manifest is **relative** | app provides the base root (its private storage); rejects absolute paths + `..` traversal as a security boundary |
| Build offline | all third-party source committed under `vendor/` | clone repo on fresh Windows 10 + VS 2022 → `cmake -B build && cmake --build build` → working `.exe`, no network |

## Files created

```
datamanage/
├── .gitignore
├── CMakeLists.txt
├── README.md
├── config.example.json
├── src/
│   ├── cli.h
│   ├── cli.cpp
│   └── main.cpp
└── vendor/
    └── README.md
```

### `CMakeLists.txt`

- CMake 3.20+, C++20, MSVC `/W4 /utf-8 /permissive- /Zc:__cplusplus`.
- `WIN32_LEAN_AND_MEAN`, `NOMINMAX`, `_CRT_SECURE_NO_WARNINGS`.
- Output binary goes to `build/bin/DataManage.exe` (predictable for
  scripts / README).
- Reserves `add_subdirectory(...)` lines for future vendor trees as
  comments so Stages 2 / 4 / 6 / 7 just uncomment.

### `src/main.cpp`

- `SetConsoleOutputCP(CP_UTF8)` for proper non-ASCII path printing on
  Windows.
- Wraps `parseCli` + `run` in a try/catch that writes the error to
  stderr and points at `--help`.
- Returns 1 on parse error so PowerShell `$LASTEXITCODE` behaves.

### `src/cli.h` + `src/cli.cpp`

Tiny hand-rolled argument parser. No third-party CLI library yet — the
surface is small enough that 90 lines suffice.

Subcommands:

| Command | Args | Stage 1 behaviour | Lands in |
|---|---|---|---|
| `pack` | `--config <path>` | echoes config path | Stage 3 |
| `verify` | `<pack.ddp>` | echoes pack path | Stage 6 |
| `info` | `<pack.ddp>` | echoes pack path | Stage 3 |
| `--help` / `-h` / `help` / no args | — | prints usage | — |

Unknown commands throw, which `main` catches and reports.

### `config.example.json`

Template config showing the schema we'll fill in:

```json
{
  "version": 1,
  "pack_mode": { "compress": "zstd", "encrypt": "aes-256-gcm" },
  "encrypt_options": { "mode": "full" },
  "signing": { "cert_path": "ca/admin1.crt", "key_path": "ca/admin1.key" },
  "bundles": [
    { "name": "out_model", "source_dir": "C:/data/models", "out_folder": "models" },
    { "name": "out_font",  "source_dir": "C:/data/fonts",  "out_folder": "fonts" }
  ],
  "output_dir": "./output"
}
```

The admin edits this file and runs `DataManage pack`. Single source of
truth — no positional args.

### `.gitignore`

Excludes:
- `build/`, `out/`, `cmake-build-*/` (CMake output)
- `.vs/`, `*.user`, `*.suo`, `CMakeSettings.json` (VS state)
- `ca/`, `*.key`, `*.pem`, `*.pfx` (admin's private cert material —
  these live outside the repo, **never** committed)
- `config.json` (local, may have absolute paths)
- `output/`, `*.ddp` (build output, not source)

### `README.md`

Roadmap (all 9 stages), build instructions for VS 2022 open-folder and
PowerShell command line, planned vendor table, preview of the .ddp
format.

## Verification

Configure + build + smoke test on the current Windows 10 box:

```powershell
PS> cmake -B build -G "Visual Studio 17 2022" -A x64
-- Configuring done (5.6s)
-- Generating done (0.0s)

PS> cmake --build build --config Release
  main.cpp
  cli.cpp
  DataManage.vcxproj -> C:\...\build\bin\DataManage.exe

PS> & build\bin\DataManage.exe --help
DataManage 0.1.0 — pack files for the Flutter app
...

PS> & build\bin\DataManage.exe pack --config foo.json
[pack]   config=foo.json
[pack]   not implemented yet — arriving in Stage 3

PS> & build\bin\DataManage.exe bogus; $LASTEXITCODE
error: unknown command: bogus
run `DataManage --help` for usage
1
```

All paths verified: help, valid command stub, error path with exit
code 1.

CMake found at:
`C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe`
(ships with VS 2022 — no separate install needed).

## What's next: Stage 2

Define the `.ddp` file format as a single header (`src/format.h`)
shared in spirit with the Flutter unpacker:

- Magic bytes, version, flag bits.
- Section offsets + lengths.
- Manifest JSON schema (one struct per file: rel_path, out_folder,
  size, sha256, offset_in_data).

Stage 2 also brings the first vendored library: nlohmann/json single
header at `vendor/nlohmann_json/`.

## User prompts (verbatim, this stage)

> I want make a standalone app which can be opened via visualstudio 2022 c++.
> Let's call this app "DDD"
> ... (full architecture brief — see prior conversation)

> Before I have to mention something.
> Let's call 'DDD' as "DataManage".
> And are you confirm that there's no speed problem when using encryption?
> And Do you encrypt only small header part per data block?
> And I want the encrypt and cert files are based at least openssl 1.0 above.

> Some more.
> DataManage can be windows app and run under windows 10 system.
> I want full code for encrypt algorithm so if i move another environment
> i can build the DataManage fully without any internet download. So
> pick suitable algorithms.
> And Are you sure all the filenames and structure information is packed
> with the output names? So the application only do the unpack against
> the packed files without additional argument.

> yes

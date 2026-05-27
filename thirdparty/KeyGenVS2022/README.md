# KeyGenVS2022

Standalone Visual Studio 2022 build of the vLearn2 license key
generator. Same Qt 5 / OpenSSL / Nayuki QR codebase as
`thirdparty/KeyGenerator`, but with the CMake path stripped out —
this project is driven entirely by `KeyGenVS2022.sln` /
`KeyGenVS2022.vcxproj`.

For the full design of what the tool does (X.509 leaf cert issuance,
custom OIDs, optional Postgres logging), see
[`docs/0525/17_license_plan.md`](../../docs/0525/17_license_plan.md).

## Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Visual Studio 2022 | MSVC v143 | "Desktop development with C++" workload |
| Qt | 5.15 LTS | MSVC 2019 64-bit prebuilt |
| OpenSSL | 1.1.1+ | Easiest via vcpkg (`vcpkg install openssl:x64-windows`) |
| git | any | The pre-build step clones Nayuki QR on first build |

One-time env-var setup (the .vcxproj reads these directly):

```bat
setx QTDIR            "C:\Qt\5.15.2\msvc2019_64"
setx OPENSSL_ROOT_DIR "C:\vcpkg\installed\x64-windows"
```

Open a fresh shell after `setx` so the new values are visible.

## Build

### From Visual Studio

1. File -> Open -> Project/Solution -> `KeyGenVS2022.sln`
2. Select `Release | x64` (or `Debug | x64`).
3. Build -> Build Solution.

Output: `bin\x64\Release\KeyGenVS2022.exe` with Qt DLLs deployed
alongside by the `windeployqt` post-build step.

### From the command line

The repo-level wrapper does the same thing without opening the IDE:

```bat
thirdparty\build_KeyGenVS2022.bat
```

It locates VS 2022 via `vswhere`, sources `vcvars64.bat`, and runs
`msbuild` on `KeyGenVS2022.sln`.

Or call MSBuild directly:

```bat
msbuild thirdparty\KeyGenVS2022\KeyGenVS2022.sln /p:Configuration=Release /p:Platform=x64
```

## What happens on first build

1. **Pre-build event** clones Nayuki QR-Code-generator v1.8.0 into
   `external\qrcodegen\` (one-time; cached for later builds).
2. **moc** runs on `src\MainWindow.h` -> `generated\moc_MainWindow.cpp`.
3. **uic** runs on `src\MainWindow.ui` -> `generated\ui_MainWindow.h`.
4. **MSVC** compiles all sources to `bin\x64\Release\KeyGenVS2022.exe`.
5. **Post-build event** runs `windeployqt` to copy the required Qt
   DLLs next to the exe.

`external/`, `generated/`, `bin/`, and `obj/` are all in `.gitignore`
— only sources live under version control.

## Project layout

```
KeyGenVS2022/
  KeyGenVS2022.sln
  KeyGenVS2022.vcxproj
  KeyGenVS2022.vcxproj.filters
  KeyGenVS2022.vcxproj.user
  README.md
  .gitignore
  src/
    main.cpp
    MainWindow.{h,cpp,ui}
    LeafCa.{h,cpp}        // PEM cert + key loader (OpenSSL)
    CertIssuer.{h,cpp}    // X.509 v3 issuance + custom OIDs
    QrWriter.{h,cpp}      // QR-PNG via Nayuki qrcodegen
    LicenseLog.{h,cpp}    // CSV + optional QPSQL
```

## License DB (optional)

Set `LICENSE_DB_URL` to a `postgres://user:pw@host:5432/vLearnLicense`
URL before launching the exe to also log issuances to the
`vLearnLicense.generate_log` table (see
[`docs/0525/17_license_plan.md`](../../docs/0525/17_license_plan.md)
§ 4). When unset, the tool falls back to `generate_log.csv` next to
the configured output directory.

## Differences vs. `thirdparty/KeyGenerator`

- No `CMakeLists.txt`, no FetchContent — pure VS 2022 / MSBuild.
- New solution/project GUIDs so both can be loaded in one VS instance.
- Output binary is named `KeyGenVS2022.exe` (the other path produces
  `KeyGenerator.exe`).

Everything else — source code, custom OIDs, UI layout, log schema — is
identical to `thirdparty/KeyGenerator`.

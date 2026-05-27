# KeyGenVS2022

Standalone Visual Studio 2022 build of the vLearn2 license key
generator. Pure Win32 UI — **no Qt, no MFC**. Only the
"Desktop development with C++" workload is needed from the VS
installer; the UI is a single `DIALOGEX` template in
[`src/MainWindow.rc`](src/MainWindow.rc) driven by a Win32 dialog
proc.

For the design of what the tool does (X.509 leaf cert issuance,
custom OIDs, QR-encoded payload), see
[`docs/0525/17_license_plan.md`](../../docs/0525/17_license_plan.md).

## Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Visual Studio 2022 | MSVC v143 | "Desktop development with C++" workload |
| OpenSSL | 1.1.1+ | Easiest via vcpkg (`vcpkg install openssl:x64-windows`) |
| git | any | The pre-build step clones Nayuki QR on first build |

One-time env-var setup (the .vcxproj reads this directly):

```bat
setx OPENSSL_ROOT_DIR "C:\vcpkg\installed\x64-windows"
```

Open a fresh shell after `setx` so the new value is visible.

## Build

### From Visual Studio

1. File → Open → Project/Solution → `KeyGenVS2022.sln`
2. Select `Release | x64` (or `Debug | x64`).
3. Build → Build Solution.

Output: `bin\x64\Release\KeyGenVS2022.exe` — single self-contained
executable (statically links against the CRT-DLL; OpenSSL DLLs need
to be next to it or on PATH, which vcpkg sets up automatically).

### From the command line

```bat
thirdparty\build_KeyGenVS2022.bat
```

The script locates VS 2022 via `vswhere`, sources `vcvars64.bat`,
and runs `msbuild` on `KeyGenVS2022.sln`.

Or call MSBuild directly:

```bat
msbuild thirdparty\KeyGenVS2022\KeyGenVS2022.sln /p:Configuration=Release /p:Platform=x64
```

## What happens on first build

1. **Pre-build event** clones Nayuki QR-Code-generator v1.8.0 into
   `external\qrcodegen\` (one-time; cached for later builds).
2. **rc.exe** compiles `src\MainWindow.rc` (the dialog template +
   string resources) into a `.res`.
3. **MSVC** compiles all sources to `bin\x64\Release\KeyGenVS2022.exe`.

Libraries linked (all ship with Windows / VS):

| Lib | Used for |
| --- | --- |
| `gdiplus.lib` | PNG encoding for the QR image |
| `comctl32.lib` | v6 themed common controls |
| `comdlg32.lib` | GetOpenFileName for cert/key picking |
| `shell32.lib` | SHBrowseForFolder, SHGetKnownFolderPath |
| `ole32.lib` | CoTaskMemFree (shell APIs allocate via the COM heap) |
| `advapi32.lib` | HKCU registry for remembered field values |
| `user32.lib`, `gdi32.lib` | Dialogs / drawing |
| `libcrypto.lib` | OpenSSL — X.509 + ECDSA + PEM |

## Project layout

```text
KeyGenVS2022/
  KeyGenVS2022.sln
  KeyGenVS2022.vcxproj
  KeyGenVS2022.vcxproj.filters
  KeyGenVS2022.vcxproj.user
  README.md
  .gitignore
  src/
    main.cpp            // wWinMain + DialogBoxParam
    MainWindow.{h,cpp}  // Win32 dialog proc + handlers
    MainWindow.rc       // DIALOGEX template
    resource.h          // control IDs
    WinStrings.h        // utf-8 <-> utf-16 helpers
    LeafCa.{h,cpp}      // PEM cert + key loader (OpenSSL)
    CertIssuer.{h,cpp}  // X.509 v3 issuance + custom OIDs
    QrWriter.{h,cpp}    // QR-PNG via Nayuki qrcodegen + GDI+
    LicenseLog.{h,cpp}  // append-only CSV log
```

## Settings persistence

Field values (paths, user name, license days) are persisted under
`HKCU\Software\vLearn2\KeyGenVS2022`. Per-operator state.

## Differences vs. `thirdparty/KeyGenerator`

- **No Qt.** UI is a Win32 `DIALOGEX` template + dialog proc; the
  whole `QApplication`/`QMainWindow`/`QSettings`/`QSqlDatabase`
  stack is gone.
- **No CMake.** Pure `msbuild`.
- **GDI+ for PNG** instead of `QImage::save`.
- **Registry for persistence** instead of `QSettings`.
- **CSV-only logging.** The Qt version also tried a best-effort
  Postgres INSERT via QPSQL when `LICENSE_DB_URL` was set. That
  path is dropped here — the CSV is the source of truth, and
  re-importing into Postgres later is a one-line `\copy`.
- Output binary is `KeyGenVS2022.exe`.

The X.509 issuance logic, custom OIDs (`1.3.6.1.4.1.99999.{1,2,3}`),
key usage, and DER size budget are unchanged.

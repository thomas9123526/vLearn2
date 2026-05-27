# KeyGenerator

Qt 5 desktop tool for issuing the X.509 leaf certificates the
vLearn2 license system consumes. See
[`docs/0525/17_license_plan.md`](../../docs/0525/17_license_plan.md)
for the full design.

For every issuance the tool:

1. Loads a Leaf CA cert + private key (PEM).
2. Generates an X.509 v3 leaf cert containing the user identity,
   the device's machine ID, license mode (`period` | `permanent`),
   and the requested validity window.
3. Signs it with the Leaf CA (ECDSA-with-SHA256).
4. Writes `<serial>.lic` (DER-encoded cert, target ≤ 1 KB) and
   `<serial>.png` (QR code of the base64-encoded `.lic`) to the
   configured output directory.
5. Appends an audit row to `generate_log.csv` next to the outputs
   and (when `LICENSE_DB_URL` is set) inserts into the
   `vLearnLicense.generate_log` Postgres table.

## UI

```
+-----------------------------------------------+
|  License Generator                            |
|                                               |
|  Leaf CA cert (PEM):  [.....]  [Browse...]    |
|  Leaf CA key  (PEM):  [.....]  [Browse...]    |
|  Machine ID:          [.....]                 |
|  User name:           [.....]                 |
|  License days:        [100  ]  (permanent =   |
|                                  36500)       |
|  Output dir:          [.....]  [Browse...]    |
|                                               |
|                              [  Generate  ]   |
|                                               |
|  +-- Status --------------------------------+ |
|  | [ISO] Leaf CA loaded (subject=...)      | |
|  | [ISO] Issued serial=... days=100 ...    | |
|  | [ISO] Wrote .../<serial>.lic            | |
|  | [ISO] Wrote .../<serial>.png            | |
|  | [ISO] Logged to .../generate_log.csv    | |
|  +-----------------------------------------+ |
+-----------------------------------------------+
```

## Project layout

```
KeyGenerator/
  CMakeLists.txt
  README.md
  .gitignore
  src/
    main.cpp
    MainWindow.{h,cpp,ui}
    LeafCa.{h,cpp}         // PEM cert + key loader (OpenSSL)
    CertIssuer.{h,cpp}     // X.509 v3 issuance + custom OIDs
    QrWriter.{h,cpp}       // QR-PNG via Nayuki qrcodegen
    LicenseLog.{h,cpp}     // CSV + optional QPSQL
```

## Build

Two equivalent paths -- pick the one that fits your workflow.

### A. Open `KeyGenerator.sln` in Visual Studio 2022 (no CMake)

Set two env vars once, then File -> Open -> `thirdparty\KeyGenerator\KeyGenerator.sln`:

```bat
setx QTDIR             "C:\Qt\5.15.2\msvc2019_64"
setx OPENSSL_ROOT_DIR  "C:\vcpkg\installed\x64-windows"
```

On first build the project's pre-build event clones Nayuki QR
into `external\qrcodegen\` (needs `git` on PATH). moc / uic run
as custom build steps; windeployqt runs as the post-build step
so the Qt DLLs land next to `KeyGenerator.exe` in
`bin\x64\Release\`.

### B. CMake (cross-platform, also produces a .sln in `build\`)

Toolchain:

| Tool | Version | Notes |
| --- | --- | --- |
| Visual Studio 2022 | MSVC v143 | "Desktop development with C++" workload |
| CMake | 3.22+ | The copy bundled with VS works |
| Qt | 5.15 LTS | Set `Qt5_DIR` or `CMAKE_PREFIX_PATH` to `<Qt>/5.15.x/msvc2019_64/lib/cmake` |
| OpenSSL | 1.1.1+ | Easiest via vcpkg (`vcpkg install openssl:x64-windows`) |
| Nayuki QR | v1.8.0 | Fetched at configure time by CMake — no manual install |

The simplest setup on a clean Windows dev box:

```bat
:: 1. Visual Studio 2022 with "Desktop development with C++".
:: 2. Qt 5.15 from https://www.qt.io/offline-installers
::    Install the MSVC 2019 64-bit prebuilt -- pick the same when
::    the installer asks. Note the install path, e.g.
::      C:\Qt\5.15.2\msvc2019_64
::
:: 3. vcpkg for OpenSSL:
git clone https://github.com/microsoft/vcpkg C:\vcpkg
C:\vcpkg\bootstrap-vcpkg.bat
C:\vcpkg\vcpkg install openssl:x64-windows

:: 4. Tell the build script where Qt + vcpkg live (one-time):
setx Qt5_DIR        "C:\Qt\5.15.2\msvc2019_64\lib\cmake\Qt5"
setx VCPKG_ROOT     "C:\vcpkg"
```

Then build:

```bat
thirdparty\build_KeyGenerator.bat
```

The script locates VS 2022 via `vswhere`, sources `vcvars64.bat`,
runs `cmake -G "Visual Studio 17 2022" -A x64`, builds Release,
and runs `windeployqt` on the resulting `KeyGenerator.exe` so the
Qt DLLs land next to it.

Output: `thirdparty/KeyGenerator/build/Release/KeyGenerator.exe`.

### Manual build

```bat
cmake -S thirdparty\KeyGenerator ^
      -B thirdparty\KeyGenerator\build ^
      -G "Visual Studio 17 2022" -A x64 ^
      -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake ^
      -DQt5_DIR=%Qt5_DIR%
cmake --build thirdparty\KeyGenerator\build --config Release
```

## License DB (optional)

Set `LICENSE_DB_URL` to a `postgres://user:pw@host:5432/vLearnLicense`
URL before launching `KeyGenerator.exe`. Each successful issuance
will then also INSERT into `generate_log` per the schema in
`docs/0525/17_license_plan.md` § 4. When unset, the tool falls back
to the local CSV so an offline operator can keep working and
re-import later.

Schema (excerpt):

```sql
CREATE TABLE generate_log (
  id BIGSERIAL PRIMARY KEY,
  serial TEXT UNIQUE NOT NULL,
  machine_id TEXT NOT NULL,
  user_name TEXT,
  mode TEXT NOT NULL CHECK (mode IN ('period','permanent')),
  days INT NOT NULL,
  not_before TIMESTAMPTZ NOT NULL,
  not_after TIMESTAMPTZ NOT NULL,
  operator TEXT NOT NULL,
  cert_der BYTEA NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

The Qt `QPSQL` driver plugin is required for the Postgres path —
it ships with the standard Qt 5.15 installer when you tick "Qt
SQL".

## Custom OIDs on the issued cert

The leaf carries three UTF8String extensions under the vLearn2 OID
arc `1.3.6.1.4.1.99999.*`:

| OID | Contents |
| --- | --- |
| `1.3.6.1.4.1.99999.1` | Machine ID (64-char hex SHA-256) |
| `1.3.6.1.4.1.99999.2` | License mode (`period` / `permanent`) |
| `1.3.6.1.4.1.99999.3` | License days as a decimal string |

`days >= 36500` (~100 years) is treated as `permanent`. The leaf
also pins `keyUsage = digitalSignature` (critical) so the cert
can't be repurposed as a CA.

## License

Project-internal. Same license as the rest of the vLearn2 repo.

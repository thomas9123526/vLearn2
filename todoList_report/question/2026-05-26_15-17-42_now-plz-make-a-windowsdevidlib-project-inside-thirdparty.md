# now plz make a WindowsDevIDLib project inside thirdparty which produce dll

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T06:17:42.235Z

## User

now plz make a WindowsDevIDLib project inside thirdparty which produce dll

## Assistant

I'll mirror AndroidDevIDLib's design: a small native lib that exposes `GetDeviceId` returning a SHA-256 over stable host sources, built via CMake + VS2022, with a parallel bat script. Sources for Windows: `MachineGuid` (registry), C: volume serial, CPU brand from `__cpuid`. SHA-256 via Windows CNG (`bcrypt.lib`) so no external deps.

Let me first check what's there and what the Flutter Windows runner expects.

## Assistant

VS2022 Enterprise is installed but `cmake` isn't on the user's PATH. The script should source `vcvars64.bat` via `vswhere` — that brings in VS's bundled CMake. Let me build it now.

## Assistant

Now the build script. I'll write it ASCII-only (no em-dashes) and convert to CRLF immediately to dodge the pitfalls from the Android script.

## Assistant

Now run the build end-to-end.

## Assistant

Classic cmd trap: parens inside `echo` inside an `if (...)` block close the block early. Two of my error messages had `(or the ...)` — fix by escaping with `^`.

## Assistant

cmake configure + MSVC build ran fine. Two issues to fix:
1. `vswhere.exe` "not recognized" — that's noise from inside vcvars64.bat (benign, build still proceeded).
2. Real error: `WIN32_LEAN_AND_MEAN` macro redefinition — I set it both via `target_compile_definitions` AND with `#define` in source, and `/WX` treats the warning as error.

## Assistant

Build succeeded — 20480-byte DLL. Quick smoke test that the export actually works.

## Assistant

DLL exports correctly: `WindowsDevID_GetDeviceId` returned 64 chars of valid SHA-256 hex. Let me commit.

## Assistant

Committed (09653c8). Verified end-to-end.

**`thirdparty/WindowsDevIDLib/`** — Windows parallel of AndroidDevIDLib:

```
WindowsDevIDLib/
  CMakeLists.txt          # VS 2022, MSVC v143, C++17, /MD, /W4 /WX
  README.md
  .gitignore
  src/
    windevid.h            # public C ABI (extern "C", __declspec)
    windevid.cpp          # impl
```

**`WindowsDevID_GetDeviceId(char* buf, int bufSize)`** — returns 64-char hex `SHA-256` over a `|`-joined fingerprint of three Windows-native sources:

| Source | Where |
|---|---|
| `machine_guid` | `HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid` |
| `volume_c` | `GetVolumeInformationW("C:\\")` serial → 8-digit hex |
| `cpu_brand` | `__cpuid` 0x80000002..04 brand string, trimmed |

SHA-256 via Windows CNG (`bcrypt.lib`) — no third-party crypto dependency. Same fixed-input-shape design as AndroidDevID: missing sources fold in as empty strings.

**`thirdparty/build_WindowsDevIDLib.bat`** — same shape as the Android script:

1. Locates VS 2022 via `vswhere` (no `cmake` on the user's PATH required — the bat sources `vcvars64.bat` to pull in the VS-bundled `cmake`).
2. `cmake -G "Visual Studio 17 2022" -A x64` configure + Release build.
3. Copies `WindowsDevID.dll` to `flutter_app/windows/runner/libs/WindowsDevID.dll`.
4. Prints the `add_custom_command(... POST_BUILD ...)` snippet to append to `flutter_app/windows/runner/CMakeLists.txt` to bundle the DLL next to `runner.exe`.

**Verified on this machine:**
- Build: 20480-byte `WindowsDevID.dll` produced and copied.
- P/Invoke smoke test: `WindowsDevID_GetDeviceId` returned `1277cb0a7cd26be47ce737e28b72ce9e1ddcfcfe871f455523277f78d8f0650f` (64 chars, valid lowercase SHA-256 hex).

Two batch-scripting gotchas hit and fixed:
- Parens inside `echo` inside an `if (...)` block close the block early — escaped `(` `)` with `^` in error messages.
- `#define WIN32_LEAN_AND_MEAN` in the source duplicated the one CMake passes via `/D`, which `/WX` upgraded to error — removed the `#define`.

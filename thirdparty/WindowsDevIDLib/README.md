# WindowsDevIDLib

Windows counterpart of [`AndroidDevIDLib`](../AndroidDevIDLib/README.md).
Produces `WindowsDevID.dll`, exposing one C entry point:

```c
int WindowsDevID_GetDeviceId(char* buf, int bufSize);
```

Returns a 64-character hex `SHA-256` over a `|`-joined fingerprint
of three Windows-native sources:

| Source | Where | Notes |
| --- | --- | --- |
| `machine_guid` | `HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid` | Per-install GUID, stable across reboots and component reinstalls. |
| `volume_c` | `GetVolumeInformationW("C:\\")` serial | 32-bit serial of the system volume, formatted as 8-digit uppercase hex. |
| `cpu_brand` | `__cpuid` 0x80000002..0x80000004 | 48-char CPU brand string, leading/trailing spaces trimmed. |

Empty sources fold in as empty strings, so the input shape is fixed
and the hash is deterministic for the same install on the same
machine.

## Project layout

```
WindowsDevIDLib/
  CMakeLists.txt
  .gitignore
  README.md
  src/
    windevid.h           // public C ABI
    windevid.cpp         // implementation
```

## Build

Toolchain locked to what the Flutter Windows runner uses (so the
resulting `.dll` drops in cleanly):

| Tool | Version |
| --- | --- |
| Visual Studio 2022 | MSVC v143 (17.4+) |
| CMake | 3.22+ (the one bundled with VS works) |
| Windows SDK | 10.0.19041+ |
| Runtime | `/MD` dynamic CRT |
| Architecture | x64 |

From the repo root just run the build script:

```bat
thirdparty\build_WindowsDevIDLib.bat
```

It locates VS 2022 via `vswhere`, sources `vcvars64.bat` (which
puts the bundled `cmake` on PATH so no separate install is
required), runs `cmake -G "Visual Studio 17 2022" -A x64`, builds
Release, then copies the DLL to
`flutter_app/windows/runner/libs/WindowsDevID.dll`.

To build by hand:

```bat
cmake -S thirdparty\WindowsDevIDLib -B thirdparty\WindowsDevIDLib\build -G "Visual Studio 17 2022" -A x64
cmake --build thirdparty\WindowsDevIDLib\build --config Release
```

Output: `thirdparty/WindowsDevIDLib/build/Release/WindowsDevID.dll`.

## Wiring into the Flutter Windows runner

The build script drops the DLL at
`flutter_app/windows/runner/libs/WindowsDevID.dll`. To copy it next
to `runner.exe` at build time, append to
`flutter_app/windows/runner/CMakeLists.txt`:

```cmake
add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_SOURCE_DIR}/runner/libs/WindowsDevID.dll"
            "$<TARGET_FILE_DIR:${BINARY_NAME}>/WindowsDevID.dll")
```

Then call from Dart via FFI:

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _GetDeviceIdC = Int32 Function(Pointer<Uint8> buf, Int32 bufSize);
typedef _GetDeviceIdDart = int Function(Pointer<Uint8> buf, int bufSize);

final _dll = DynamicLibrary.open('WindowsDevID.dll');
final _fn = _dll.lookupFunction<_GetDeviceIdC, _GetDeviceIdDart>(
    'WindowsDevID_GetDeviceId');

String windowsDeviceId() {
  final buf = calloc<Uint8>(65);
  try {
    final n = _fn(buf, 65);
    if (n != 64) return '';
    return String.fromCharCodes(buf.asTypedList(64));
  } finally {
    calloc.free(buf);
  }
}
```

## License

Project-internal. Same license as the rest of the vLearn2 repo.

# build_KeyGenVS2022.bat get error

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T03:07:16.336Z

## User

build_KeyGenVS2022.bat get error

## Assistant

The errors are all `IStream` / cascade from it. GDI+ headers need `IStream` from `objidl.h`, which `WIN32_LEAN_AND_MEAN` excludes. Fix is one extra include:

## Assistant

Build succeeded:

```
KeyGenVS2022.vcxproj -> ...\bin\x64\Release\KeyGenVS2022.exe
Copying OpenSSL runtime DLLs next to KeyGenVS2022.exe

=== Success ===
KeyGenVS2022.exe (128512 bytes) is in place.
```

Let me commit the three fixes that got us there:

## Assistant

Build is green. `bin\x64\Release\KeyGenVS2022.exe` (128 KB) and `libcrypto-3-x64.dll` are in place — you can launch the exe directly. Committed as `8aeaa91`.

Three issues fixed in this round:
1. `IStream` cascade — `gdiplus.h` needs `<objidl.h>`, which `WIN32_LEAN_AND_MEAN` omits.
2. `IDC_STATIC` not defined in [src/resource.h](thirdparty/KeyGenVS2022/src/resource.h) — added as `-1`.
3. `WIN32_LEAN_AND_MEAN` C4005 macro-redefinition warning — wrapped each `#define` in an `#ifndef` guard.

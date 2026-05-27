# btw I don't want Qt inside KeyGenVS2022, I want Desktop development with c++ wit

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T02:17:32.865Z

## User

btw I don't want Qt inside KeyGenVS2022, I want Desktop development with c++ without qt

## Assistant

This is a substantial rewrite — every Qt type, the UI builder, the PNG writer, the QPSQL log path, the moc/uic build steps all go away. I'll convert it to pure Win32 + Windows SDK (Desktop development with C++ workload only), keep OpenSSL + Nayuki QR, use GDI+ for the PNG (ships with Windows), and drop the Postgres path (it was Qt-coupled via QSqlDatabase; CSV stays as the source of truth).

Starting with the small utility files, then UI, then port the OpenSSL files.

## Assistant

Now the main entry point, MainWindow, and the OpenSSL files ported to std types:

## Assistant

Now the OpenSSL files ported to std types (LeafCa, CertIssuer):

## Assistant

Now QrWriter (GDI+ PNG) and LicenseLog (CSV-only):

## Assistant

Now remove the leftover `MainWindow.ui` (no longer used) and update the project files:

## Assistant

Now rewrite the .vcxproj — strip Qt entirely, drop moc/uic/windeployqt, add the .rc compile and the new libraries:

## Assistant

Update the build script and README and gitignore to drop Qt:

## Assistant

One safety tweak to the edit-text helper and then commit:

## Assistant

Done. Stripped Qt from [thirdparty/KeyGenVS2022/](thirdparty/KeyGenVS2022/) — the project now needs only the "Desktop development with C++" workload (plus OpenSSL from vcpkg). Committed as `b4b5022`.

What changed under the hood:

| Was (Qt) | Is (Win32 only) |
| --- | --- |
| `QMainWindow` + `MainWindow.ui` | `DIALOGEX` template in [MainWindow.rc](thirdparty/KeyGenVS2022/src/MainWindow.rc) + dialog proc |
| `QFileDialog`, `QString` | `GetOpenFileNameW`, `SHBrowseForFolderW`, `std::wstring`/`std::string` |
| `QSettings` | HKCU registry under `Software\vLearn2\KeyGenVS2022` |
| `QImage::save("PNG")` | GDI+ `Bitmap::Save` |
| `QSqlDatabase` (QPSQL) | dropped — CSV stays the source of truth |
| `moc` / `uic` / `windeployqt` custom build steps | removed; only `rc.exe` + `cl.exe` left |
| `Qt5Widgets.lib` etc. | `gdiplus.lib`, `comctl32.lib`, `comdlg32.lib`, `shell32.lib`, `ole32.lib`, `advapi32.lib` (all SDK-shipped) |

Files added: [src/MainWindow.rc](thirdparty/KeyGenVS2022/src/MainWindow.rc), [src/resource.h](thirdparty/KeyGenVS2022/src/resource.h), [src/WinStrings.h](thirdparty/KeyGenVS2022/src/WinStrings.h). Files removed: `src/MainWindow.ui`. The X.509 issuance logic, custom OIDs, and cert size budget are unchanged — only the framework around them was replaced.

To build: `setx OPENSSL_ROOT_DIR "C:\vcpkg\installed\x64-windows"`, then open `KeyGenVS2022.sln` or run `thirdparty\build_KeyGenVS2022.bat`. First build clones Nayuki QR once into `external\`.

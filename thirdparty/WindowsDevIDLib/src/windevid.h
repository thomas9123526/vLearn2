/* WindowsDevID -- the Windows counterpart of AndroidDevIDLib.
 *
 * Single entry point: WindowsDevID_GetDeviceId. Returns a stable
 * 64-character hex SHA-256 fingerprint over a |-joined set of
 * host-specific sources. Sources mirror Android's three-source
 * pattern, but use Windows-native equivalents:
 *
 *   machine_guid  HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid
 *   volume_c      Volume serial of C:\ (GetVolumeInformationW)
 *   cpu_brand     CPUID 0x80000002..0x80000004 brand string
 *
 * The function is exposed with a plain C ABI so Dart FFI, Flutter
 * plugins, or any future C/C++ caller can use it without C++ name
 * mangling. */

#pragma once

#ifdef WINDEVID_EXPORTS
#define WINDEVID_API __declspec(dllexport)
#else
#define WINDEVID_API __declspec(dllimport)
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Writes a 64-char lowercase hex SHA-256 fingerprint plus a NUL
 * terminator into `buf`. Returns the number of bytes written (not
 * counting NUL), or 0 if `buf` is NULL or `bufSize` is less than 65.
 *
 * Missing sources (e.g. C: not present, CPUID brand unsupported)
 * are folded in as empty strings so the input shape is fixed --
 * the function never returns 0 for benign reasons. 0 only means
 * the caller's buffer was too small. */
WINDEVID_API int WindowsDevID_GetDeviceId(char* buf, int bufSize);

#ifdef __cplusplus
}
#endif

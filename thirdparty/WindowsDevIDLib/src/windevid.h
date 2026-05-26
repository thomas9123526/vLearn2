/* WindowsDevID -- the Windows counterpart of AndroidDevIDLib.
 *
 * Single entry point: WindowsDevID_GetDeviceId. Writes a stable
 * 20-digit decimal string into the caller's buffer:
 *
 *   Characters  0-15  content  — first 8 SHA-256 bytes over a |-joined
 *                               set of host sources, treated as a big-endian
 *                               uint64, taken mod 10^16, zero-padded.
 *   Characters 16-19  checksum — weighted digit sum
 *                               (Σ (i+1)·d[i] for i=0..15) mod 10000,
 *                               zero-padded to 4 digits.
 *
 * Sources mirror Android's three-source pattern:
 *   machine_guid  HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid
 *   volume_c      Volume serial of C:\ (GetVolumeInformationW)
 *   cpu_brand     CPUID 0x80000002..0x80000004 brand string
 *
 * Plain C ABI for Dart FFI / Flutter plugin / C caller compatibility. */

#pragma once

#ifdef WINDEVID_EXPORTS
#define WINDEVID_API __declspec(dllexport)
#else
#define WINDEVID_API __declspec(dllimport)
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Writes a 20-char decimal fingerprint plus a NUL terminator into `buf`.
 * Returns 20 on success, or 0 if `buf` is NULL or `bufSize` is less than 21.
 * Missing sources are folded in as empty strings — the function never
 * returns 0 for benign reasons; 0 only means the buffer was too small. */
WINDEVID_API int WindowsDevID_GetDeviceId(char* buf, int bufSize);

#ifdef __cplusplus
}
#endif

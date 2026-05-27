# ok before it, there can be tcard that user put additionally 4g or 16g like memor

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T05:49:15.104Z

## User

ok before it, there can be tcard that user put additionally 4g or 16g like memory, so app scans inside for this kind of memory too?

## Assistant

Yes — and you need Kotlin for it. Flutter's `dart:io` only sees the primary "internal SD" path; it can't enumerate physical SD cards. The Android `StorageManager.getStorageVolumes()` API lists everything mounted (internal + removable + USB OTG if present), and only Kotlin can call it.

Updated flow with SD-card support:

1. **Method channel call** Flutter → Kotlin: "scan all storage volumes for `룡마/가상외국어회화/license/*.lic`".
2. **Kotlin handler** iterates `StorageManager.getStorageVolumes()`, builds the candidate path on each volume (`<volume root>/룡마/가상외국어회화/license/`), and returns the list of file paths (plus their bytes, since reading them in Kotlin avoids a second permission round-trip).
3. **Flutter** receives the list, calls `/license/verify` on each in newest-first order, picks the first `valid: true`.
4. Same permission story — `MANAGE_EXTERNAL_STORAGE` covers both internal and SD card without extra scoping per volume.

Edge cases worth pinning down:
- **No SD inserted**: only internal-storage path scanned, no error.
- **SD inserted but no `룡마/가상외국어회화/license/` on it**: silently skipped.
- **SD ejected during scan**: caught as IOException, skipped, scan continues on other volumes.

So the scope is: one Kotlin handler (~50 lines), Flutter call site that already exists pivots to use it. Tradeoff vs. internal-only: more code surface in MainActivity / a new helper class.

Confirm and I'll implement A (MANAGE_EXTERNAL_STORAGE) **with** SD-card enumeration as one unit.

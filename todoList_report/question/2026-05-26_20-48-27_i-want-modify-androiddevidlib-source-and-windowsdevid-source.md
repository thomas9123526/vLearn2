# I want modify AndroidDevIDLib source and WindowsDevID source to produce machine 

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T11:48:27.841Z

## User

I want modify AndroidDevIDLib source and WindowsDevID source to produce machine id as the following format.
20 length digit string , 16-len digit is content and 4-len digit is checksum for 16-len digit

## Assistant

Let me find the source files for both libraries.

## Assistant

Reading both source files now.

## Assistant

Now let me check the Flutter machine ID service and Windows flutter_window files.

## Assistant

Now I have full context. I'll make changes to all four files:
1. `AndroidDevID.java` → 20-digit format
2. `windevid.cpp` → 20-digit format  
3. `windevid.h` → update buffer requirement
4. `flutter_window.cpp` → fix API mismatch (uses `WindowsDevID_Get`/`Free` but DLL exports `WindowsDevID_GetDeviceId`)

**Algorithm:** first 8 SHA-256 bytes as big-endian uint64 mod 10¹⁶ → 16-digit content; weighted digit sum (Σ(i+1)·dᵢ) mod 10000 → 4-digit checksum.

## Assistant

Now fix `flutter_window.cpp` — it currently calls the non-existent `WindowsDevID_Get`/`Free` exports; update it to use `WindowsDevID_GetDeviceId` with the 21-byte buffer.

## Assistant

Now commit all four changes.

## Assistant

Done. Four files changed and committed.

**What changed:**

| File | Change |
|---|---|
| [AndroidDevID.java](thirdparty/AndroidDevIDLib/androiddevid/src/main/java/com/vlearn2/devid/AndroidDevID.java) | SHA-256 → 8 bytes mod 10¹⁶ → 16-digit content + 4-digit checksum via `BigInteger` |
| [windevid.cpp](thirdparty/WindowsDevIDLib/src/windevid.cpp) | Same algorithm in C++ with `uint64_t % 10000000000000000ULL`; buf size 21 |
| [windevid.h](thirdparty/WindowsDevIDLib/src/windevid.h) | Updated docs: 20-char decimal, bufSize ≥ 21 |
| [flutter_window.cpp](flutter_app/windows/runner/flutter_window.cpp) | Fixed API mismatch: now calls `WindowsDevID_GetDeviceId(buf, 21)` instead of the non-existent `WindowsDevID_Get`/`WindowsDevID_Free` exports |

**Rebuild required:** rebuild `AndroidDevIDLib` to get a new `.aar`, and rebuild `WindowsDevIDLib` to get a new `.dll`, before running on device.

# let's talk about "ANR" problem as we do before

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T02:05:29.727Z

## User

let's talk about "ANR" problem as we do before

## Assistant

Sure. Quick recap of where we landed, then tell me what you're seeing.

## Current state

Commit `7e4e95f` moved the install onto a **background isolate**. That fixed the **freeze** — the UI thread is free, the splash spinner animates, Android's ANR watchdog shouldn't fire anymore.

But it did **not** make the install *faster*. The total wall-clock time is the same — pure-Dart pointycastle AES-256-GCM + zlib on tens-of-MB sherpa models is just slow (~10–50 MB/s on a phone). You still wait at the splash; you just wait with a working spinner instead of a frozen app.

## So which is it?

**A. The ANR dialog still appears** even after the isolate fix.
→ That would be a real bug. Possible causes: the install isn't actually reaching the isolate, or something *else* on the main thread blocks (e.g. a huge synchronous file read, or the sherpa model loading itself after unpack). I'd need the `[datapack]` logs + the exact timing of when the dialog appears.

**B. No more ANR, but the wait is too long** — the splash sits on "Preparing your data…" for many seconds and you want it genuinely fast.
→ This is optimization, not a bug. Three routes:

| Option | Effort | Speedup | Trade-off |
| --- | --- | --- | --- |
| **Skip encryption for model bundles** | small | huge — decrypt cost → 0 | models stored in plaintext on disk; still signed, so still tamper-proof |
| **Native crypto via FFI to mbedTLS** | large | ~10–50× decrypt | adds an NDK build + `dart:ffi` layer to the Flutter app |
| **Per-file progress bar** | small | none (perception only) | the wait *feels* shorter; doesn't actually shorten it |

**C. Something else** — you want to discuss the design, or there's a different symptom.

Which one are you hitting? If A, paste the `flutter logs | Select-String "\[datapack\]"` output and say when the dialog pops. If B, my honest recommendation is **skip encryption for the model bundles** — they're large but not secret, and the signature still guarantees they came from you untampered. That makes the install basically just zlib-inflate + file-write, which is fast.

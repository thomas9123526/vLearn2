# Datapack — move install onto a background isolate (fix ANR)

## The bug

The admin's device showed Android's "Virtual Foreign Language isn't
responding — Close app / Wait" ANR dialog while the splash's
"Preparing your data…" spinner was up.

Cause: the datapack install ran **synchronously on the main (UI)
isolate**. Sherpa-onnx model bundles are tens of MB; the per-file
pipeline is pure-Dart AES-256-GCM decrypt + zlib inflate + SHA-256,
plus a SHA-256 over the whole pack for signature verification.
Pure-Dart pointycastle crypto runs at maybe 10–50 MB/s on a phone,
so decrypting a large bundle blocks the UI thread for many seconds —
well past Android's ~5 s ANR watchdog. The whole app froze.

This was a known caveat — the Stage 9 wiring note said
"the install runs synchronously in the same Dart isolate as the
splash UI … if that becomes an issue, move the install into an
Isolate.spawn." It became an issue.

## The fix

`installPendingDataPacksProvider` now runs the entire install on a
**background isolate** via `Isolate.run`. The UI thread stays free,
the splash spinner animates smoothly, no ANR.

### Split of work

| Stays on main isolate | Moves to background isolate |
|---|---|
| `DataPackPaths.resolve()` — needs path_provider plugin | PEM parsing (EC key + cert) |
| `rootBundle.loadString()` — needs the asset bundle | `.ddp` scan + per-file SHA-256 |
| (these can't run off-isolate — platform channels) | AES-GCM decrypt, zlib inflate |
| | SHA-256 verify, file writes |
| | `datapack_state.json` read/write |

Plugin-dependent prep can't run on a background isolate, so it stays
on main and produces plain strings; everything CPU-heavy crosses
over.

### `datapack_provider.dart` rewrite

- New `DataPackInstallInputs` — a 5-string value object (admin key
  PEM, root CA PEM, packs dir path, unpacked root path, state file
  path). All-string so it copies cleanly across the isolate
  boundary.
- `dataPackInstallerProvider` → renamed `dataPackInstallInputsProvider`.
  Runs on the main isolate, resolves paths + loads the two asset
  PEMs, returns a `DataPackInstallInputs`.
- New top-level `_installOnIsolate(DataPackInstallInputs)` —
  reconstructs `DataUnpackFactory` + `DataPackPaths` +
  `DataPackInstaller` from the strings and runs `installPending()`.
  Top-level (not a closure capturing `this`) so it's a valid
  `Isolate.run` body.
- `installPendingDataPacksProvider` now does
  `await Isolate.run(() => _installOnIsolate(inputs))`.

`DataPackInstallOutcome` (the return type, in a `List`) is already
isolate-sendable — String / enum / int / String? fields only.

Nothing else changed. `DataPackInstaller`, `DataUnpackFactory`,
`DataPackPaths`, the splash wiring — all untouched. The splash's
`_runDataPackInstall()` still just awaits the provider; it doesn't
know or care that the work now happens off-isolate.

## Why this is the right fix (and what it doesn't fix)

- **Fixes:** UI freeze + ANR. The main isolate never blocks; the
  "Preparing your data…" spinner stays smooth for the whole install.
- **Doesn't change:** total install *time*. Pure-Dart AES-GCM is
  still slow — a big bundle still takes the same wall-clock seconds
  to decrypt, the user still waits at the splash. But waiting with a
  live spinner is fine; waiting with a frozen app that Android
  offers to kill is not.
- If the install ever needs to be genuinely *fast* (not just
  non-blocking), that's a separate effort — native crypto via FFI,
  or a lighter cipher. Out of scope here.

## Verification

```text
flutter analyze lib/core/datapack/ lib/features/splash/  →  No issues
flutter test test/datapack/                              →  4/4 pass
```

The unit tests construct `DataPackInstaller` / `DataUnpackFactory`
directly so they exercise the same `installPending()` logic; the
isolate is a thin wrapper and doesn't change behaviour, only the
thread it runs on.

`dpLog` still works from the background isolate — `debugPrint` falls
through to `print`, which the engine merges into the process log
stream, so the `[datapack] unpack: …` trace still shows in
`flutter logs`. A new main-isolate line brackets it:
`[datapack] provider: spawning background isolate for install pass`
… `provider: background isolate finished`.

## User prompt (verbatim)

> Does the unpacking data affect the entire app?
> It seems like it freeezes the app ui.   You can reference the png
> i give you
> continue / continue / continue

(png showed Android's "Virtual Foreign Language isn't responding"
ANR dialog over the home screen)

# DataManage - Stage 9: app startup wiring (scan + install pending)

## What landed

The final stage: the Flutter app reads `.ddp` files from external
storage and unpacks them into its private storage on launch, with
state tracking so a relaunch with the same packs is a no-op.

## Path layout

| Role | Android | Windows |
| --- | --- | --- |
| Where the admin drops `.ddp` files | `/storage/emulated/0/룡마/가상외국어회화/datapacks/` | `<exe-dir>/datapacks/` |
| Where decoded files land | `getApplicationSupportDirectory()/datapack_unpacked/` | same |
| State file (per-pack SHA-256 + outcome) | `getApplicationSupportDirectory()/datapack_state.json` | same |

The Android primary path sits inside the **existing** public folder
the app already uses for `app_config.json` — same
`MANAGE_EXTERNAL_STORAGE` permission, same USB-transfer workflow the
admin already knows. No new permission grant.

## Files added

### `lib/core/datapack/datapack_paths.dart`

`DataPackPaths.resolve()` — picks the platform-correct triple
(`packsDir`, `unpackedRoot`, `stateFile`), creates missing dirs.
Falls back to the app-scoped external dir when
`MANAGE_EXTERNAL_STORAGE` isn't granted yet, same fallback pattern
as `lib/core/config/app_config.dart::_resolveAndroid()`.

### `lib/core/datapack/datapack_installer.dart`

The orchestrator:

```dart
final installer = DataPackInstaller(factory: factory, paths: paths);
final outcomes = await installer.installPending();
```

For every `*.ddp` in `paths.packsDir`:

- Compute SHA-256 of the file bytes.
- If the state file already has the same `{filename, sha256}` pair,
  emit a `cached` outcome — no work.
- Otherwise, call `factory.unpack(packPath, paths.unpackedRoot.path)`,
  record the result, emit `installed`.
- On any thrown exception (bad signature, bad chain, etc.) emit
  `failed` with the error message. The installer keeps going so
  one bad pack doesn't block the rest.

State file:

```json
{
  "schema": 1,
  "installed": {
    "out_font.ddp": {
      "sha256":      "<64 hex>",
      "bundle_name": "out_font",
      "unpacked_at": "2026-05-21T10:00:00Z",
      "files":       ["/.../fonts/Lora-Regular.ttf", ...]
    },
    ...
  }
}
```

Atomic write via `<state>.tmp` + `rename` so a power-cut between
write-content and finalise can't corrupt the state.

### `lib/core/datapack/datapack_provider.dart`

Riverpod glue:

```dart
// Run once at startup, e.g. from a `LoadingScreen`:
final outcomes = await ref.read(installPendingDataPacksProvider.future);
```

Reads `assets/datamanage/admin.key` + `root_ca.crt` from
`rootBundle` exactly once (the heavy parse-PEM + EC-allocation
cost is amortised across the app's lifetime).

### `test/datapack/installer_test.dart`

Two tests:

1. **idempotent install + cache**: builds two real `.ddp` files
   via `DataManage.exe`, runs the installer twice. First run
   reports both as `installed`. Second run reports both as
   `cached`. Then rewrites one pack with new content (same
   filename, different SHA-256), reruns, asserts only that one
   re-installs.
2. **failure path**: a bogus `.ddp` (all zeros, wrong magic)
   surfaces as a `failed` outcome with a non-null error message.

Both pass.

## Verification

```text
PS> flutter analyze lib/core/datapack/ test/datapack/
No issues found! (ran in 15.8s)

PS> flutter test test/datapack/installer_test.dart
00:00 +0: installer: first run installs, second run caches
00:00 +1: installer: failure path produces a `failed` outcome
00:00 +2: All tests passed!
```

Plus the Stage 8 round-trip + tamper-detection tests still pass.

## How to wire it into app startup

For the app's `main.dart` or a splash/loading screen:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final outcomes = ref.watch(installPendingDataPacksProvider);
  return outcomes.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error:   (e, _) => DataPacksUnavailableScreen(error: e.toString()),
    data:    (list) {
      final failed = list.where((o) =>
          o.status == DataPackInstallStatus.failed).toList();
      if (failed.isNotEmpty) {
        return DataPacksFailedScreen(failures: failed);
      }
      return const HomeScreen();
    },
  );
}
```

This isn't wired into the existing splash yet — that's an app-UX
decision (and probably an interrupt to the user's existing splash
animation work). The provider is ready when you want it.

## Architecture summary across all 9 stages

```text
┌─────────────────────────────────────────────────────────────┐
│  Admin's Windows machine                                    │
│                                                             │
│  config.json  ─────────┐                                    │
│                        ▼                                    │
│  source dirs ──► DataManage.exe (mbedTLS)                   │
│                  ├─ walk + SHA-256                          │
│                  ├─ zlib deflate                            │
│                  ├─ AES-256-GCM (ECDH-derived key)          │
│                  ├─ embed admin cert (DER)                  │
│                  └─ ECDSA P-256 sign                        │
│                                ▼                            │
│                          out_font.ddp                       │
└──────────────────────────────┬──────────────────────────────┘
                               │ USB transfer
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  Android device                                             │
│                                                             │
│  /sdcard/룡마/가상외국어회화/datapacks/out_font.ddp         │
│                               │                             │
│                               ▼                             │
│   DataPackInstaller.installPending() (Stage 9)              │
│   └─ check SHA-256 vs datapack_state.json                   │
│      └─ if new: DataUnpackFactory.unpack() (Stage 8)        │
│         (pointycastle, archive, asn1lib — pure Dart)        │
│         ├─ verify chain → pinned root_ca.crt asset          │
│         ├─ verify ECDSA signature                           │
│         ├─ ECDH(admin.key asset, eph_pub) → HKDF → AES key  │
│         ├─ AES-256-GCM decrypt each blob                    │
│         ├─ zlib inflate each blob                           │
│         ├─ SHA-256 verify each plaintext                    │
│         └─ write to <support>/datapack_unpacked/<out_folder>/│
└─────────────────────────────────────────────────────────────┘
```

## User prompt (verbatim)

> yes

(yes to using `/sdcard/룡마/가상외국어회화/datapacks/` as the .ddp
drop location)

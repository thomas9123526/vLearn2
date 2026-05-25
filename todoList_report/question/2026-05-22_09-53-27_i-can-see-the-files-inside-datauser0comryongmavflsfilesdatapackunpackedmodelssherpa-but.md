# I can see the files inside "\data\user\0\com.ryongma.vfls\files\datapack_unpacke

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T00:53:27.607Z

## User

I can see the files inside "\data\user\0\com.ryongma.vfls\files\datapack_unpacked\models\sherpa"
But there's something to modify datamanage tool and android datafactory.
You put all files in the same folder level , for example I can see all model files inside "\data\user\0\com.ryongma.vfls\files\datapack_unpacked\models\sherpa".
But when i pack the files through datamanage.exe , the packed files have it's own folder structure.
I want preserve the unpacked folder,file structure the same as when pack folders, files.

## Assistant

Let me trace the bug. First confirm what the C++ packer writes into `rel_path`.

## Assistant

C++ side is **correct** — `forwardSlash` preserves the full nested path in `rel_path`. The bug is entirely Dart-side. Let me see `_safeJoin`.

## Assistant

Found it — [datapack_factory.dart:227](flutter_app/lib/core/datapack/datapack_factory.dart#L227): `_safeJoin` takes `relPath.split(...).last` — **only the basename**, discarding the directory prefix. So `encoder/model.onnx` becomes just `model.onnx` and everything lands flat.

Fix: preserve the full `relPath` structure.

## Assistant

Now strengthening the round-trip test to actually verify nested structure survives.

## Assistant

Fix confirmed — logs show `sub/deep/deep.txt` → `rt\sub\deep\deep.txt`. Run the installer test too, then commit.

## Assistant

Committed `b5a9a5b`. **Nested folder structure is now preserved.**

## What was wrong

Only the **Flutter unpacker** had the bug. `_safeJoin()` was doing `relPath.split(...).last` — taking just the basename and dropping every directory segment. So `encoder/encoder.onnx` → `encoder.onnx`, everything flat.

**The C++ `DataManage.exe` is correct** — `packer.cpp` already records the full nested `rel_path` (`encoder/encoder.onnx`) in the manifest. It needs no change. Your existing `.ddp` files are fine.

## The fix

`_safeJoin()` now builds `<root>/<out_folder>/<rel_path>` keeping every path segment. Result:

```
datapack_unpacked/models/sherpa/
├── encoder/encoder.onnx     ← "encoder/" preserved
├── decoder/decoder.onnx     ← "decoder/" preserved
└── tokens.txt
```

## Verified

- `flutter analyze` — clean.
- `unpack_test.dart` — now packs `sub/nested.txt` + `sub/deep/deep.txt`, asserts they land at `rt/sub/nested.txt` and `rt/sub/deep/deep.txt`, plus regression guards that the flat paths don't exist. 2/2 pass.
- `installer_test.dart` — 2/2 pass.
- Logs confirm: `sub/deep/deep.txt → …/unpacked/rt/sub/deep/deep.txt`.

## ⚠️ One thing you need to do on the device

The installer **caches by SHA-256**. Your `.ddp` files haven't changed (they were always correct), so the installer will see them as already-installed and **skip re-unpacking** — meaning the flat files from the buggy run will stay.

To get the corrected nested layout, on the device do **one** of:

1. **Delete the state file** so the installer treats all packs as new:
   ```powershell
   adb shell run-as com.ryongma.vfls rm files/datapack_state.json
   ```
   (or clear the app's data via Settings → Apps → vfls → Storage → Clear data)

2. **Also delete the stale flat output** so there's no leftover:
   ```powershell
   adb shell run-as com.ryongma.vfls rm -r files/datapack_unpacked
   ```

Then relaunch the app — the installer re-unpacks all `.ddp` files into the proper nested tree.

After that, `\data\user\0\com.ryongma.vfls\files\datapack_unpacked\models\sherpa\` will mirror exactly the folder structure you packed.

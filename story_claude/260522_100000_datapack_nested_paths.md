# Datapack — preserve nested folder structure on unpack

## The bug

When `DataManage.exe` packed a source directory with subdirectories,
the Flutter unpacker wrote **every file flat** into the out_folder
root, dropping the directory structure. e.g. a source tree:

```
models/sherpa/
├── encoder/encoder.onnx
├── decoder/decoder.onnx
└── tokens.txt
```

unpacked to:

```
datapack_unpacked/models/sherpa/
├── encoder.onnx     ← "encoder/" lost
├── decoder.onnx     ← "decoder/" lost
└── tokens.txt
```

## Root cause

Entirely on the Flutter side — the C++ packer was correct.

- `datamanage/src/packer.cpp`: `forwardSlash(fs::relative(p,
  source_root))` correctly stores the **full** relative path
  (e.g. `encoder/encoder.onnx`) in the manifest's `rel_path`.
  Verified — no change needed there.
- `flutter_app/lib/core/datapack/datapack_factory.dart`,
  `_safeJoin()`: built the output path from
  `relPath.split(RegExp(r'[/\\]')).last` — i.e. **only the
  basename**, throwing away every directory segment. So
  `encoder/encoder.onnx` collapsed to `encoder.onnx`.

## The fix

`_safeJoin()` now keeps the full `relPath` structure:

```dart
final folderParts =
    outFolder.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty);
final relParts =
    relPath.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty);
final joined = [root, ...folderParts, ...relParts]
    .join(Platform.pathSeparator);
```

Final layout is now `<root>/<out_folder>/<rel_path>` with every
segment preserved. The existing
`Directory(_dirOf(outPath)).create(recursive: true)` call already
creates intermediate directories, so once `_safeJoin` returns the
correct nested path the rest just works.

The under-root canonicalisation check is unchanged — still rejects
any path that would escape the unpack root.

## Test strengthening

`test/datapack/unpack_test.dart` round-trip test now packs two
nested files alongside the flat ones:

- `sub/nested.txt`     → must unpack to `rt/sub/nested.txt`
- `sub/deep/deep.txt`  → must unpack to `rt/sub/deep/deep.txt`

Plus explicit regression guards asserting the flattened paths
(`rt/nested.txt`, `rt/deep.txt`) do **not** exist. Before the fix
the test would have found the files at the flat paths and the
nested-path `exists()` checks would have failed.

## Verification

```text
flutter analyze lib/core/datapack/ test/datapack/  →  No issues
flutter test test/datapack/unpack_test.dart        →  2/2 pass
flutter test test/datapack/installer_test.dart     →  2/2 pass
```

The unpack log now shows the correct nested targets, e.g.:

```
[datapack] unpack:   [2/4] sub/deep/deep.txt  (read 59B → decrypt →
           inflate→23B → sha256 OK)  →  …/unpacked/rt/sub/deep/deep.txt
[datapack] unpack:   [3/4] sub/nested.txt  (…)  →  …/unpacked/rt/sub/nested.txt
```

## Note: DataManage.exe needs no change

The admin asked whether the C++ tool also needed a fix. It does not
— `packer.cpp` already records the full nested `rel_path` in the
manifest. The packs you produced earlier are correct; only the
unpacker was discarding the structure. Re-running the app with this
fix unpacks the *same* `.ddp` files into the proper tree (the
installer will re-unpack because... actually no — it caches by
SHA-256, and the .ddp bytes haven't changed. To force a re-unpack
of an already-installed pack after this fix, either delete
`<appSupport>/datapack_state.json` on the device, or bump the .ddp
by re-packing).

## User prompt (verbatim)

> I can see the files inside "\data\user\0\com.ryongma.vfls\files\
> datapack_unpacked\models\sherpa"
> But there's something to modify datamanage tool and android
> datafactory.
> You put all files in the same folder level …
> But when i pack the files through datamanage.exe , the packed
> files have it's own folder structure.
> I want preserve the unpacked folder,file structure the same as
> when pack folders, files.

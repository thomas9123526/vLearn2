# Speech-setup progress — drop the bundle name from the status line

## What changed

`flutter_app/lib/core/datapack/datapack_installer.dart`, the
`installGroup` per-file progress callback.

The live status line under the progress bar used to be:

```
Unpacking sherpa_models — 2/363 files
```

`sherpa_models` is `sp.manifest.bundleName` — the internal pack
identity. The line now reads:

```
Unpacking 2 of 363 files
```

No bundle/model name, and the wording reads naturally (the em-dash
+ duplicated "files" is gone too).

## Why

The admin asked not to surface the model/pack name on the
"Setting up speech…" progress screen (circled in red on the device).
The file count is enough to drive the bar; the pack name added
nothing for the user and exposed an internal name.

## Scope

`installGroup` is generic across feature groups, so this also
applies to any future on-demand group — none of them will print
their pack name. The screen title ("Setting up speech…") still
comes from `ModelsNotInstalledScreen` and is unaffected.

## Notes

- `sp` is still used elsewhere in the loop (`sp.file.path`,
  `sp.manifest.files.length`), so dropping `sp.manifest.bundleName`
  here leaves no unused variable.
- `flutter analyze` on the file → No issues found.

## User prompt (verbatim)

> ok. and on this screen, I don't want indicate the model
> information like the red part. remove it and put appropriate word.

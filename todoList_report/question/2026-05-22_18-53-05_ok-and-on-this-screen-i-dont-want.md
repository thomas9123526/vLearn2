# ok. and on this screen, I don't want indicate the model information like the red

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T09:53:05.743Z

## User

ok. and on this screen, I don't want indicate the model information like the red part. remove it and put appropriate word.

## Assistant

The "sherpa_models" text on the progress screen comes from the status string built in `installGroup` — [datapack_installer.dart:341](flutter_app/lib/core/datapack/datapack_installer.dart#L341), which embeds `sp.manifest.bundleName`.

I'll drop the bundle name and reword it to read naturally: **`Unpacking 2 of 363 files`**.

## Assistant

Done. Committed as `c841d85`.

The progress line now reads **`Unpacking 2 of 363 files`** instead of `Unpacking sherpa_models — 2/363 files`. The `sp.manifest.bundleName` (which was `sherpa_models`) is gone — the file count alone drives the bar.

Change in [datapack_installer.dart:337-344](flutter_app/lib/core/datapack/datapack_installer.dart#L337-L344). Since `installGroup` is generic, this also keeps any future on-demand group from printing its pack name. The screen title "Setting up speech…" is unaffected (it's set separately by `ModelsNotInstalledScreen`). `flutter analyze` is clean.

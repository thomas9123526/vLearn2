# Add batch script to build models/manifest.json

## What this task did

Added Windows launchers that run [tools/build-manifest.py](../tools/build-manifest.py) and write `manifest.json` into [models/](../models/):

- [cmds/build_models_manifest.bat](../cmds/build_models_manifest.bat) — main script (checks Python, models folder, prints adb hint)
- [models/build-manifest.bat](../models/build-manifest.bat) — shortcut when working inside the models folder

Extra CLI flags are passed through, e.g. `cmds\build_models_manifest.bat --tts-voices en_US-amy`.

## User prompt (verbatim)

> can u make me script or bat file that makes manifest.json and save it in models folder

# I put logic for stt read models from app_config.json for android, Can you do thi

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T01:22:11.155Z

## User

I put logic for stt read models from app_config.json for android,
Can you do this for windows also ?

## Assistant

Good news — the logic is **already cross-platform**. `ModelRegistry.resolveModelRoot()` takes the path from `app_config.json` and calls `Directory(path).existsSync()` / `_hasSherpaLayout()` without any Android-specific code. Windows accepts forward slashes too.

The problem is a typo in your Windows JSON: you wrote `"models"` (plural), but the code reads `"model"` (singular).

Two ways to fix this:

1. **Quick fix:** rename `"models"` → `"model"` in [app_config.json](flutter_app/build/windows/x64/runner/Debug/app_config.json).
2. **Robust fix:** accept both keys in the code so the typo never bites again. I'll do this — `"models"` is a natural-sounding key for a folder of model files.

## Assistant

Done. Now your existing Windows config works as-is.

**One thing to double-check** — your override path `C:/Users/aaa/Downloads/VLearn2/VLearn2/sherpa_2023` needs this layout for the registry to accept it:

```
sherpa_2023/
  stt/
    *.onnx          ← at least one .onnx file
    tokens.*        ← at least one tokens file
  tts/              ← (optional, but expected for TTS)
  vad/              ← (optional, but expected for VAD)
```

If the layout is right, on next launch you'll see in the console:
```
[model-registry] using app_config.json model override → C:/Users/aaa/Downloads/VLearn2/VLearn2/sherpa_2023
```

If the layout is wrong, you'll see:
```
[model-registry] model override path "..." missing or has no expected layout — falling back to unpacked .dat
```

Run with `flutter run -d windows` and check the console — the `[model-registry]` line tells you which path won.

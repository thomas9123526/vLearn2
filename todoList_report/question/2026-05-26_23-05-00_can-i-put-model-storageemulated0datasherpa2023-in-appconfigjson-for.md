# can i put "model": "/storage/emulated/0/룡마/가상외국어회화/data/sherpa_2023" in app_conf

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T14:05:00.187Z

## User

can i put "model": "/storage/emulated/0/룡마/가상외국어회화/data/sherpa_2023" in app_config.json for windows?  i have tested for android before

## Assistant

Let me find the model-loading logic to give a definitive answer.

## Assistant

**No** — that path is Android-only. The Flutter app passes the string straight into `Directory(_modelOverridePath)`, which is filesystem-literal: on Windows, `/storage/emulated/0/...` resolves to `\storage\emulated\0\...` on the current drive (which doesn't exist), so `dir.existsSync()` is false and the registry falls back to the unpacked `.dat` path.

You need a **Windows-style absolute path**. The model files have to be physically present on the Windows machine.

Two ways to set it:

**A. Use a Windows path in `app_config.json`** at `<exe dir>/app_config.json`:
```json
{
  "baseurl": "http://localhost:5101/api",
  "reqTout": 30,
  "tSync": 60,
  "dev": "dev",
  "model": "C:\\Users\\aaa\\룡마\\가상외국어회화\\data\\sherpa_2023"
}
```
- Backslashes must be doubled in JSON (`\\`), or use forward slashes (`C:/Users/.../sherpa_2023`) — Dart's `Directory` accepts either on Windows.
- The folder needs the expected layout: `stt/` with `.onnx` + `tokens`, plus `tts/` and `vad/` subdirs. If any are missing, the registry logs `model override path "..." missing or has no expected layout` and falls back.

**B. Use the platform-agnostic key `models` (plural)** — same effect, accepted as an alias by [app_config.dart:32](flutter_app/lib/core/config/app_config.dart#L32):
```json
{ "models": "C:/Users/aaa/룡마/가상외국어회화/data/sherpa_2023" }
```

**To verify it took effect**, watch the running app's log for `[model-registry] using app_config.json model override → C:\Users\...\sherpa_2023`. If you see `falling back to unpacked .dat` instead, double-check the path exists and contains the `stt/`, `tts/`, `vad/` subfolders.

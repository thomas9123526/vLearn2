# I have models in "E:\Upload_HKC\sherpa_2023"

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T14:06:52.751Z

## User

I have models in "E:\Upload_HKC\sherpa_2023"

## Assistant

Let me quickly verify the expected layout exists at that path.

## Assistant

Layout checks out — `stt/`, `tts/`, `vad/` all present with the expected files. Use this exact JSON, located at the same folder as `flutter_app.exe`:

`flutter_app/build/windows/x64/runner/Debug/app_config.json` (or `Release` for release builds):

```json
{
  "baseurl": "http://localhost:5101/api",
  "reqTout": 30,
  "tSync": 60,
  "dev": "dev",
  "model": "E:/Upload_HKC/sherpa_2023"
}
```

Forward slashes (cleaner than `"E:\\Upload_HKC\\sherpa_2023"` — Dart's `Directory` handles either on Windows). `model` and `models` are both accepted; pick one.

After saving, restart the app. The log should print:
```
[model-registry] using app_config.json model override → E:\Upload_HKC\sherpa_2023
```

If you see `falling back to unpacked .dat`, the registry's layout check (`_hasSherpaLayout`) found something missing — paste that log line and I'll point at the exact file it can't find.

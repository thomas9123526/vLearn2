# {   "baseurl": "http://127.0.0.1:5101/api",   "reqTout": 100,   "tSync": 120,   

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T02:50:52.067Z

## User

{
  "baseurl": "http://127.0.0.1:5101/api",
  "reqTout": 100,
  "tSync": 120,
  "dev": "dev",
  "model": "D:\Pending\sherpa_2023"
}
this is what i put

## Assistant

Found the bug. The `model` path has **unescaped Windows backslashes** — `D:\Pending\sherpa_2023` is invalid JSON because `\P` and `\s` are not valid JSON escape sequences. `jsonDecode` throws → catch block silently overwrites with defaults.

Two things to fix:
1. Make the parser tolerant of unescaped backslashes
2. The `D:\Pending\sherpa_2023` path is a Windows path — on Android you need an Android path

## Assistant

Need to add the `_fixBackslashes` method:

## Assistant

Now the parser will survive `D:\Pending\sherpa_2023` and convert it to `D:/Pending/sherpa_2023`.

**But** — that path is a Windows path and won't exist on Android. For the `model` field to work on the emulator, you need the Android path where you pushed the models. Based on our earlier session, that would be something like:

```json
{
  "baseurl": "http://10.0.2.2:5101/api",
  "reqTout": 100,
  "tSync": 120,
  "dev": "dev",
  "model": "/storage/emulated/0/Android/data/com.ryongma.vfls/files/models"
}
```

Or if you pushed the models to the `룡마/가상외국어회화` folder, a relative path works too:
```json
"model": "data/sherpa_2023"
```

Where is the models folder on the Android device? Run `adb shell ls /storage/emulated/0/Android/data/com.ryongma.vfls/files/` when connected and I can give you the exact path.

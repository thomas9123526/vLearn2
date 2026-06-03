# where the seed_fetch.ps1 save result?

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T05:44:52.129Z

## User

where the seed_fetch.ps1 save result?

## Assistant

The script saves to two places, depending on flags:

**Default (JSON only):**
```
flutter_app/assets/seed/scenarios.json
flutter_app/assets/seed/categories.json
```

**With `-WithImages`:**
```
flutter_app/assets/seed/scenarios.json     ← image URLs rewritten to asset: paths
flutter_app/assets/seed/categories.json
flutter_app/assets/seed/images/            ← downloaded image files here
```

All paths are relative to the project root (`c:\project\vLearn2`). The script calculates the path with:
```powershell
$root    = Split-Path $PSScriptRoot -Parent   # = c:\project\vLearn2
$seedDir = Join-Path $root "flutter_app\assets\seed"
```

So the full path is `c:\project\vLearn2\flutter_app\assets\seed\`.

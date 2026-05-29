# Conversation - Add VS Code debug configuration for the Windows target

| Field | Value |
|---|---|
| Saved | 2026-05-29 19:20:24 |
| Commit | story: add VS Code Flutter Windows (debug) launch config (local-only) |
| Project | C:\project\vLearn2 |

---

## User

i want add configuration for debug windows

## Assistant

Added a "Flutter: Windows (debug)" configuration to .vscode/launch.json
(previously had an empty `configurations: []`):

```jsonc
{
    "name": "Flutter: Windows (debug)",
    "request": "launch",
    "type": "dart",
    "cwd": "flutter_app",
    "program": "lib/main.dart",
    "flutterMode": "debug",
    "deviceId": "windows"
}
```

Key detail: `cwd: "flutter_app"` because the Flutter project lives in that
subfolder, not the repo root where launch.json sits - without it the Dart
extension wouldn't find pubspec.yaml. `deviceId: "windows"` pins the desktop
target so F5 launches there with the debugger (breakpoints / hot reload /
debug console). Validated the file as valid JSONC.

Note: `.vscode/` is gitignored (.gitignore:90), so launch.json is NOT tracked.
User chose to KEEP IT LOCAL (not add a !/.vscode/launch.json exception), so the
config exists on this machine only. This story file records the task since the
config itself isn't committable.

---

## Prompt

i want add configuration for debug windows

# I can't run android debug, when i go F5, backend start up

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T14:41:56.768Z

## User

I can't run android debug, when i go F5, backend start up

## Assistant

That's because F5 launches **the first config in `launch.json`** when nothing's explicitly selected — and the first one is the NestJS backend. Two fixes:

## Fix 1 (immediate, 5 seconds): pick the right config

1. Open the **Run and Debug** panel: `Ctrl+Shift+D`
2. At the top, you'll see a dropdown — currently showing `Backend: NestJS (debug + watch)`
3. Click it → select **`Flutter: debug — Android emulator (emulator-5554)`**
4. Now F5 launches the Flutter app

Once you pick a config, VS Code remembers it for next time.

## Fix 2 (permanent): reorder so Flutter is the default

Moving the Flutter configs to the top of `launch.json` so F5 hits Flutter by default. Backend stays available, just not first.

## Assistant

Done. Now F5 with nothing selected runs the Android emulator config.

## Try now

1. `Ctrl+Shift+D` to open Run & Debug. The top dropdown should now show **`Flutter: debug — Android emulator (emulator-5554)`** as the first/default entry.
2. **F5** — should start a debug build to your emulator (look for "Launching..." in the bottom status bar, then the app appearing on the emulator).

## If F5 still launches the backend

Possible causes:

| Symptom | Fix |
| --- | --- |
| Dropdown still shows "Backend: NestJS..." | VS Code remembered the last selection. Manually pick **`Flutter: debug — Android emulator`** from the dropdown — sticks for next time. |
| Configs say "Cannot find debug type 'dart'" | Dart-Code.flutter extension isn't installed. `View → Extensions → search "Flutter" → install the one by Dart Code`, then reload window. |
| Dropdown only shows backend, no Flutter entries | The Dart extension isn't recognising the `dart` type. Install it (above), reload VS Code, then F5. |
| Launches but immediately fails with "no device" | Emulator stopped between steps. Run `flutter devices` to confirm `emulator-5554` is still alive; restart the emulator if needed. |

## Quick way to confirm the extension is the issue

Run from terminal:

```powershell
code --list-extensions | findstr -i "dart\|flutter"
```

Should show:
```
Dart-Code.dart-code
Dart-Code.flutter
```

If those two lines are missing, install them and you're good. If they're there, the launch dropdown problem is just stale selection — pick the Flutter config explicitly once and F5 forever.

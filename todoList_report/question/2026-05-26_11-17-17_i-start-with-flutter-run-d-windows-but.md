# I start with flutter run -d windows But now showing for stt yet like attachment 

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T02:17:17.567Z

## User

I start with flutter run -d windows
But now showing for stt yet like attachment png file

## Assistant

The `flutter logs` command in your screenshot just listed devices and exited — it's an Android-attached-device tool, it won't capture anything from a `flutter run -d windows` process running in a different terminal.

The `[stt]` lines are streaming to the **terminal where you ran `flutter run -d windows`**, not this `flutter logs` terminal. Looking at your right-side panel you have three terminals: `dart flutter_app`, `dart`, `powershell`. Switch to the one where you started `flutter run -d windows` — that's where every `debugPrint` is appearing live.

You should see lines like:
```
[stt] mic.start ok — listening
[stt] mic.stop -> 96000 bytes pcm captured
[stt] engine.transcribe flavour=online-transducer samples=48000 duration=3.00s
[stt] engine.result (online) = "..."
```

If you want a single terminal for both running and grepping, kill the current `flutter run` (Ctrl+C) and start it like this:

```powershell
flutter run -d windows 2>&1 | Select-String -Pattern "\[stt\]|\[tts\]|\[model-registry\]"
```

That keeps the app running in the foreground AND only prints the lines you care about. Don't escape brackets without backslashes — `\[stt\]` works because `Select-String` uses regex by default.

If you switch to the right terminal and still see no `[stt]` line after tapping the mic, paste me the first ~20 lines after the `Connecting to VM Service…` banner and I can see why `debugPrint` isn't reaching stdout.

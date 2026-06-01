# LD Player is running on this windows system

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T15:59:04.168Z

## User

LD Player is running on this windows system

## Assistant

For LDPlayer, you interact with it via ADB — it exposes itself as an ADB device on a local port.

```
adb devices
```

That will show the LDPlayer instance (usually `127.0.0.1:5555` or `emulator-5554`). To connect if it's not listed:

```
adb connect 127.0.0.1:5555
```

Then run Flutter against it:

```
flutter run -d 127.0.0.1:5555
```

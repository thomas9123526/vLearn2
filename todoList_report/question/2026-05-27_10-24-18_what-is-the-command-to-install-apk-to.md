# what is the command to install apk to emulator-5554

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T01:24:18.878Z

## User

what is the command to install apk to emulator-5554

## Assistant

```
adb -s emulator-5554 install path\to\app.apk
```

Useful variants:
- Reinstall over existing: `adb -s emulator-5554 install -r path\to\app.apk`
- Reinstall + keep data (downgrade allowed): `adb -s emulator-5554 install -r -d path\to\app.apk`
- For a Flutter debug build in this project: `adb -s emulator-5554 install -r flutter_app\build\app\outputs\flutter-apk\app-debug.apk`

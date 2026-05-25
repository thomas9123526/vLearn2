# what is the command to run android emulator

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T04:07:02.357Z

## User

what is the command to run android emulator

## Assistant

A few ways, depending on what you have:

## Via Flutter (simplest — uses your project's toolchain)

```powershell
cd c:\project\vLearn2\flutter_app

flutter emulators                          # list available emulators
flutter emulators --launch Pixel_4a        # launch one by ID
```

Your project has two defined: **`Pixel_4a`** and **`Pixel_XL`**.

```powershell
flutter emulators --launch Pixel_4a
```

## Via the Android SDK `emulator` tool directly

```powershell
# The emulator binary lives here:
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -list-avds

# Launch one:
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_4a
```

To avoid the long path, add `%LOCALAPPDATA%\Android\Sdk\emulator` to your `PATH`, then just `emulator -avd Pixel_4a`.

## Launch emulator + run the app in one step

You don't actually need to launch the emulator separately — `flutter run` will start one for you if none is connected:

```powershell
cd c:\project\vLearn2\flutter_app
flutter run                                # picks/starts a device
flutter run -d Pixel_4a                    # target a specific emulator by name
```

## Check what's already running

```powershell
flutter devices                            # all connected devices/emulators
adb devices                                # raw adb view
```

Earlier in this session you had `emulator-5554` (an API 26 image) already running — if it's still up, `flutter run -d emulator-5554` targets it directly, no launch needed.

## For your datapack testing specifically

Reminder from before: the API 26 emulator doesn't model `MANAGE_EXTERNAL_STORAGE` cleanly, so `/sdcard/룡마/가상외국어회화/data/` won't resolve to the public path there — the installer falls back to the app-scoped external dir. For real sdcard testing you want a **physical Android 11+ device** (`flutter run -d <device-id>` after enabling USB debugging).

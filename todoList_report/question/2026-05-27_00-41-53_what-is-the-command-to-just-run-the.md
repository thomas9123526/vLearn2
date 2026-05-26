# what is the command to just run the apk on emulator with flutter

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T15:41:53.270Z

## User

what is the command to just run the apk on emulator with flutter

## Assistant

Two cases — pick by what you have:

**If you have a Flutter project (source) and want to build + run it:**
```bash
flutter run                          # auto-picks the only running emulator
flutter run -d <device-id>           # if multiple devices/emulators
flutter run --release                # release-mode APK (perf-realistic)
```
List devices first: `flutter devices`

**If you already have a built `.apk` and just want to install + launch it on a running emulator:**
```bash
flutter install                      # uses build/app/outputs/flutter-apk/app-debug.apk
flutter install --release            # uses ...app-release.apk
```
Or skip Flutter and use `adb` directly:
```bash
adb devices                          # confirm emulator is up
adb install -r path\to\app-release.apk
adb shell am start -n com.ryongma.vfls/.MainActivity
```

The `-r` reinstalls without uninstalling first (keeps app data).

**If no emulator is running yet:**
```bash
flutter emulators                    # list available AVDs
flutter emulators --launch <avd-id>
```
Then run any of the above.

For this repo specifically, `cd flutter_app && flutter run` is the one-liner once an emulator is up.

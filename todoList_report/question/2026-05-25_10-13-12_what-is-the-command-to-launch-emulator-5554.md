# what is the command to launch emulator-5554

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-25T01:13:12.087Z

## User

what is the command to launch emulator-5554

## Assistant

The Android emulator launch command depends on whether the emulator is already created or you want to start a specific AVD.

To launch the already-created AVD named after the emulator-5554 device:

```powershell
# List your existing AVDs
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -list-avds

# Launch one (replace <avd_name> with what list-avds prints, e.g. Pixel_XL_API_26)
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd <avd_name>
```

The first emulator that boots gets the serial `emulator-5554` automatically (subsequent ones get 5556, 5558, etc.) — there is no `-port 5554` needed unless you're running multiple at once.

To confirm it's up:

```powershell
adb devices
```

If `emulator` or `adb` isn't on `PATH`, the full paths are:
- `%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe`
- `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`

From the screenshots earlier in this session the AVD looked like `Pixel_XL_API_26`, so likely:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_XL_API_26
```

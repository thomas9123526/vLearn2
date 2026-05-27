# do i need to repack ? or I just recompile the project and run apk?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-25T23:14:12.804Z

## User

do i need to repack ? or I just recompile the project and run apk?

## Assistant

**Just recompile and reinstall — no repack needed.**

The change is entirely on the Flutter unpacker side. The `.dat` format, signed-prefix layout, and verification bytes are all identical — I only changed *how* the unpacker reads them (streamed in chunks vs. one big buffer). The streamed SHA-256 produces the exact same 32-byte digest over the exact same bytes the C++ packer signed.

So your existing `1.dat` / `2.dat` on the sdcard stay valid. Just:

```powershell
flutter build apk
# or, on the connected emulator/device:
flutter run
```

Drop the new APK on the device, hit Retry on the Speech-setup screen, and the same `2.dat` should now unpack without OOM.

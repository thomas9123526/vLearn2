# I want change "룡마/가상외국어회화/datapacks" to "룡마/가상외국어회화/data" in android sdcard

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T01:57:11.071Z

## User

I want change "룡마/가상외국어회화/datapacks" to "룡마/가상외국어회화/data" in android sdcard

## Assistant

`datapacks` appears in 3 functional spots — two Android, one Windows. You asked for the Android sdcard path, so changing lines 52 + 56 (and the header comment). Let me read the exact context.

## Assistant

Committed `91815f8`. **Android sdcard folder renamed `datapacks` → `data`.**

## What changed

The app now scans:
```
/storage/emulated/0/룡마/가상외국어회화/data/        ← public (permission granted)
<app-scoped external>/룡마/가상외국어회화/data/      ← fallback
```

Both Android paths in `_resolveAndroid()` updated, plus the header comment.

## Left as-is

The **Windows** desktop path (`<exeDir>/datapacks`) is unchanged — you scoped this to "android sdcard". If you want Windows unified to `data` too, say the word.

## Before testing

Move your `.dat` files to the renamed folder on the device:

```powershell
adb shell mkdir -p "/sdcard/룡마/가상외국어회화/data"
adb shell mv "/sdcard/룡마/가상외국어회화/datapacks/*" "/sdcard/룡마/가상외국어회화/data/"
# or just push fresh:
adb push mybundle.dat "/sdcard/룡마/가상외국어회화/data/"
```

Then full-restart the app. The `[datapack] paths:` log line will now show `.../가상외국어회화/data` as the `.dat` folder.

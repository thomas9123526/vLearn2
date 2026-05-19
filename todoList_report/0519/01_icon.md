# Task Report — 01_icon (Android launcher icon)

**Date:** 2026-05-19
**Branch:** `dev`

## Requirement

> I want put app launcher icon from
> `E:\dataToExport\vtran\VFLS Icon\png-android\selected`.

## Source assets

```
E:\dataToExport\vtran\VFLS Icon\png-android\selected
├── F-dialogue__48.png    (48 ×  48)
├── F-dialogue__72.png    (72 ×  72)
├── F-dialogue__96.png    (96 ×  96)
├── F-dialogue__192.png  (192 × 192)
└── F-dialogue__512.png  (512 × 512)
```

The 48 / 72 / 96 / 192 PNGs map directly to Android's `mdpi` / `hdpi` /
`xhdpi` / `xxxhdpi` density buckets. The `xxhdpi` bucket needs a 144×144
asset, which isn't in the source set — generated from the 512 master via
Pillow's LANCZOS downscale.

## What changed

Replaced each density bucket's `ic_launcher.png`:

| Bucket | Required size | Source | Method |
|---|---|---|---|
| `mipmap-mdpi`    |  48×48  | `F-dialogue__48.png`   | copy |
| `mipmap-hdpi`    |  72×72  | `F-dialogue__72.png`   | copy |
| `mipmap-xhdpi`   |  96×96  | `F-dialogue__96.png`   | copy |
| `mipmap-xxhdpi`  | 144×144 | `F-dialogue__512.png`  | downscale (Pillow, `Image.LANCZOS`) |
| `mipmap-xxxhdpi` | 192×192 | `F-dialogue__192.png`  | copy |

The `AndroidManifest.xml` already references `@mipmap/ic_launcher` for
`android:icon`, so no manifest edit is required. There is no `roundIcon`
declared and no `mipmap-anydpi-v26/ic_launcher.xml` (adaptive icon), so
this single PNG-per-bucket replacement is all that's needed for the
launcher icon to update on next install.

## Verification

Each file's actual dimensions, after replacement:

| Bucket | Size on disk | Image dimensions |
|---|---|---|
| `mdpi`    |  1,215 B | 48 × 48 RGBA |
| `hdpi`    |  1,857 B | 72 × 72 RGBA |
| `xhdpi`   |  2,445 B | 96 × 96 RGBA |
| `xxhdpi`  |  6,308 B | 144 × 144 RGBA |
| `xxxhdpi` |  5,181 B | 192 × 192 RGBA |

All five match Android's density-bucket requirements. The next
`flutter run` (or `flutter build apk` + reinstall) will use the new
F-dialogue icon on the home screen.

## Note on adaptive icons

This project does **not** use Android 8.0+ adaptive launcher icons
(separate foreground + background drawables). If you later want the
icon to render correctly inside circle / squircle / rounded-square OS
masks, you'd add:

- `mipmap-anydpi-v26/ic_launcher.xml` referencing
  `@drawable/ic_launcher_foreground` and `@color/ic_launcher_background`
- A foreground asset sized 432×432 (safe zone ≈ 264×264 in the center)
- A background color in `res/values/colors.xml`

For now the supplied PNGs work fine on Android ≤ 7 and as fallback on
Android 8+; on 8+ the OS will treat the PNG as a legacy icon and
auto-shrink it inside whatever mask the launcher uses.

## Files touched

```
flutter_app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png
flutter_app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png
flutter_app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
flutter_app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
flutter_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

No source-code or manifest changes.

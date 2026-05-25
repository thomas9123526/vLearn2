# Splash — second pass: timing + native bridge

## What this added on top of `260521_140000_splash_anim_perf.md`

The widget-level fixes (cache SVGs, drop saveLayer Opacity, RepaintBoundary)
addressed the per-frame cost of the bob. This pass addresses two more
contributors to the perceived "slow splash" on Android:

1. **Timing.** The entrance was tuned for the design's full 1.5s runway,
   and the auto-nav waited an extra 500ms beyond that. Returning users
   were staring at a finished animation for ~600ms before navigation.
2. **The native → Flutter splash gap on dark mode.** Both
   `LaunchTheme` styles pointed at a single hardcoded white
   `drawable/launch_background.xml`. Dark-mode users saw a white flash
   on cold start, then a transition to the dark Flutter splash.

Impeller is already enabled by default on Android in Flutter 3.41.9, so
no flag needed for that.

## Timing cut

`splash_screen.dart`:

- `_entrance` controller duration: 1500ms → **900ms**. All per-element
  `Interval`s are normalised to 0..1 of this duration so the
  choreography scales proportionally — visual sequence identical, just
  played at ~1.67×.
- `_autoNavDelay`: 2000ms → **1100ms**. Still enough headroom for the
  wordmark to register; just no more dead time after.

Net wait for returning users: **3500ms → 2000ms**. Same animation, no
visual regression.

## `flutter_native_splash` integration

Added `flutter_native_splash: ^2.4.4` to dev_dependencies. Configured in
`pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#FFFFFF"         # matches light scheme.surface
  color_dark: "#1E1C2E"    # matches midnight theme surface
  android_12:
    color: "#FFFFFF"
    color_dark: "#1E1C2E"
  android: true
  ios: true
  web: false
```

Ran `dart run flutter_native_splash:create`. The generator:

- Updated `drawable/launch_background.xml` and `drawable-v21/`.
- **Created `drawable-night/` and `drawable-night-v21/`** — the dark
  variants that were previously missing, which is what caused the
  white flash on dark mode.
- **Created `values-v31/styles.xml` and `values-night-v31/styles.xml`**
  — adds `android:windowSplashScreenBackground` for the Android 12+
  SplashScreen API. Without this, Android 12+ users saw the launcher
  icon on the default OS background (no theme inheritance).
- Updated `values/styles.xml` and `values-night/styles.xml`.

Color-only for now. No image — the wordmark + monogram still come from
the Flutter splash. The win is that the engine-boot handoff happens
**over a colored background that matches the Flutter splash**, instead
of a white-or-system-default background that visibly flashes before the
Flutter UI mounts.

If we want a centered monogram on the native splash later, export the
badge as a 384×384 PNG and add `image:` / `image_dark:` / `android_12.image`
to the config, then re-run the generator.

## Files changed

- `flutter_app/lib/features/splash/splash_screen.dart` — timing.
- `flutter_app/pubspec.yaml` — `flutter_native_splash` dep + config.
- `flutter_app/pubspec.lock` — pin.
- `flutter_app/android/app/src/main/res/drawable/launch_background.xml`
- `flutter_app/android/app/src/main/res/drawable-v21/launch_background.xml`
- `flutter_app/android/app/src/main/res/values/styles.xml`
- `flutter_app/android/app/src/main/res/values-night/styles.xml`
- **(new)** `drawable-night/launch_background.xml`
- **(new)** `drawable-night-v21/launch_background.xml`
- **(new)** `values-v31/styles.xml`
- **(new)** `values-night-v31/styles.xml`
- **(new)** `drawable/background.png`, `drawable-v21/background.png`
  — placeholder background bitmaps the generator emits even for
  color-only configs.

## Verification

- `flutter pub get` → clean.
- `dart run flutter_native_splash:create` → success.
- `flutter analyze lib/features/splash/splash_screen.dart` → clean.

## What's deferred

Of the remaining "more approaches":

- **Pre-rasterize SVGs to PNG.** Skipped — Impeller mitigates the
  vector-playback cost a lot, and bake-out of 9 icons is its own task.
- **Prefetch `_resolveReturning` in main.dart.** Skipped — saves ~50ms
  for the very first frame; small win, fiddly across Riverpod providers.
- **Drop mobile glyphs.** Skipped — design change, not perf change. The
  per-frame cost of the bob is already drastically lower after pass 1.

## User prompts (verbatim, this pass)

> is there more approach? it seems still slow for splash on android
>
> ok

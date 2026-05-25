# is there more approach? it seems still slow for splash on android

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T02:45:17.613Z

## User

is there more approach? it seems still slow for splash on android

## Assistant

Yes — the widget-level fixes were one half. The other half is everything happening **before** your Flutter splash renders, plus rendering-pipeline issues that don't show up in widget code. Ordered by likely impact:

## 1. Are you testing in `--release` mode?

This is the most common misdiagnosis. **Debug mode is 5–10× slower** on Android because of JIT, assertion checks, and unoptimized Dart. The splash you're judging may be running at 6 fps in debug and 60 fps in release.

```powershell
cd flutter_app
flutter run --release    # or: flutter run --profile
```

If release feels instant, the widget code is fine and the rest of this list is moot.

## 2. The native → Flutter splash gap (`flutter_native_splash`)

When the user taps your app icon, Android shows `android/app/src/main/res/drawable*/launch_background.xml` while the Flutter engine boots (~400–900ms on mid-range Android). Then it goes **black for a frame or two**, then your Flutter splash starts its 1.5s entrance. The user perceives **engine boot + black + entrance** as "the splash is slow."

Fix: use [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash) to render the **same monogram and background color** as your Flutter splash, with the wordmark already in place. The handoff becomes invisible — the engine-boot delay becomes branded waiting instead of a generic splash.

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.4.4

flutter_native_splash:
  color: "#FAF7F2"            # match scheme.surface light
  color_dark: "#0F1117"       # match scheme.surface dark
  image: assets/splash/monogram_F.png   # 512×512 export of the badge
  android_12:
    image: assets/splash/monogram_F.png
    color: "#FAF7F2"
```

Then `dart run flutter_native_splash:create`. This is the **single biggest perceived-speed win** if cold-start dominates.

## 3. Shader compilation jank — enable Impeller

Flutter on Android (Skia path) compiles shaders **on first use**. Your splash has a radial gradient + 9 SVGs + 5 BoxShadows + RichText — each new shape/gradient triggers a shader compile that can spike a frame to 50–200ms. Classic "first run feels janky, second run feels smooth" symptom.

Fix: enable Impeller (no runtime shader compilation):

```kotlin
// flutter_app/android/app/src/main/AndroidManifest.xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="true" />
```

On Flutter ≥3.27 Impeller is default on Android — check with `flutter --version`. If you're on an older version where it isn't default, flip the flag.

Alternative (Skia path): warm shaders with `flutter run --profile --cache-sksl` then `flutter build apk --bundle-sksl-path=flutter_01.sksl.json`. More work, less robust.

## 4. The entrance is just too long

1.5s entrance + 2.0s auto-nav = **3.5 seconds** before a returning user lands on sign-in. Even at 60 fps, that's a perceptible wait. Easy cut:

```dart
duration: const Duration(milliseconds: 1500),  // → 900
static const _autoNavDelay = Duration(milliseconds: 2000);  // → 1100
```

900ms entrance + 200ms breathing = 1100ms total. The wordmark still registers and the user is on signin in a third of the time.

## 5. Pre-rasterize the SVGs

Even with caching, `SvgPicture` plays back a recorded `Picture` every frame — vector composite cost. For 9 small icons on a splash, pre-rendering each to a PNG asset and using `Image.asset` is meaningfully cheaper, and `precacheImage(...)` in `initState` removes the first-frame decode hop.

Rough recipe:
1. Export each `_glyphSvg(...)` to a 128×128 PNG at design time.
2. Add to `pubspec.yaml` assets.
3. Replace `SvgPicture.string(...)` with `Image.asset('assets/splash/bubble.png', cacheWidth: spec.size.toInt() * 2)`.
4. In `_SplashScreenState.initState`, `precacheImage(AssetImage(...), context)` for each.

This also removes `flutter_svg` from the splash's hot path entirely.

## 6. Prefetch `_resolveReturning` in `main.dart`

Right now `_returning` is `null` for ~50ms while `SharedPreferences` opens, causing a `setState` re-layout on the splash. Read it before `runApp`:

```dart
// main.dart
final hasEverSignedIn = await SharedPreferences.getInstance()
  .then((p) => p.getBool('auth.hasEverSignedIn') ?? false);
runApp(ProviderScope(
  overrides: [authHistorySeedProvider.overrideWithValue(hasEverSignedIn)],
  child: const App(),
));
```

Then the splash mounts with `_returning` already known, no re-layout.

## 7. Reduce work in `main.dart` before `runApp`

Anything sync between Flutter binding init and `runApp` extends the black-frame gap. Audit `main.dart`: defer non-critical setup (analytics init, deep-link handlers, etc.) to after first frame with `WidgetsBinding.instance.addPostFrameCallback`.

## 8. Drop a couple of mobile glyphs

The mobile layout has 8 glyphs bobbing forever. On low-end Android, 8 `RepaintBoundary` + transform pipelines is real cost. Cut to 5 — design impact is small, ~40% less per-frame transform work.

---

## My ranked recommendation

1. **Verify you're testing in release mode** — 60-second sanity check, biggest revelation if you weren't.
2. **`flutter_native_splash`** — kills the perceived cold-start gap entirely (~500ms savings in perception).
3. **Confirm Impeller is on** — kills first-paint shader jank.
4. **Shorten entrance to 900ms / auto-nav to 1100ms** — 2.4s less wait for returning users.
5. Then 5, 6, 7, 8 as polish.

#1–#4 are where the next perceptible jump lives. Want me to apply #4 now (one-line cut, safe) and walk you through #2 (needs an exported PNG asset from you for the monogram, otherwise I'll generate a placeholder)?

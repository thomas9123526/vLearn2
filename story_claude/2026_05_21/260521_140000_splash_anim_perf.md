# Splash screen — animation performance fixes (Android)

## Why

The Android splash felt heavy because the build loop did far more work
per frame than it needed to:

1. **SVGs were re-parsed every frame.** `SvgPicture.string(...)` was
   called inside the `AnimatedBuilder.builder` of `_FloatingGlyph` —
   meaning flutter_svg parsed the same XML string ~60×/sec per glyph,
   times 8 glyphs. This was the dominant cost.
2. **Inline `Opacity` widget on every animated element** — `Opacity`
   with a value <1 forces `saveLayer`, which is expensive on Android
   GPUs. Five widgets (monogram, wordmark, slogan, tap-to-begin, every
   glyph) were paying this cost every entrance frame.
3. **No `RepaintBoundary`** — each glyph's bob dirtied the
   centerpiece's layer, so wordmark + monogram + slogan kept
   repainting alongside the glyphs.
4. **Infinite `_bob` controller kept running** during the navigation
   handoff for returning users — competing with the route transition
   for the frame budget.

## What changed

All in `flutter_app/lib/features/splash/splash_screen.dart`. No design
or behavior change — same choreography, same SVGs, same timings.

### `_FloatingGlyph` → `StatefulWidget`

- `SvgPicture.string(...)` moved into a `late final Widget _svg` field,
  parsed **once** for the lifetime of the glyph.
- The parsed SVG is passed as `child:` to `AnimatedBuilder` so it isn't
  rebuilt per tick; only `Transform.translate` / `rotate` / `scale`
  wrappers are reconstructed.
- Entrance fade replaced with `FadeTransition` (render-level opacity,
  no `saveLayer`).
- Each glyph wrapped in `RepaintBoundary` — its paint stays local.
- Bob `dy` moved into `Transform.translate` instead of mutating
  `Positioned.top`, so the parent layout doesn't get re-walked.

### `_MonogramBadge`

- `Opacity` widget → `FadeTransition`.
- Inline scale → `ScaleTransition`.
- Static badge body (Container + 'F' text) built **once** and reused
  via `ScaleTransition.child`.
- Blinking dot extracted to `_BlinkingDot` widget with its own
  `RepaintBoundary`. The dot uses `Visibility` (no `saveLayer`) instead
  of `Opacity(0|1)`.

### `_Wordmark`, `_Slogan`, `_TapToBeginButton`

Same recipe:
- `FadeTransition` for opacity (no `saveLayer`).
- `AnimatedBuilder` scoped to the translate, with the static content
  (RichText / Text / Material pill body) passed as `child:`.

### `_SplashScreenState._autoNavTimer`

- Calls `_bob.stop()` immediately before `context.go(...)` so the
  route transition gets a clean frame budget instead of competing with
  8 glyphs being re-transformed per frame.

## Why not Rive

The bottleneck was widget wiring, not vector rendering. Rive would
have added native-build fragility (the rive_common CMake build is
already flaky on Windows), 2.5 MB of native deps, an async asset load
that defeats "feel instant", and forced a Rive-rendered overlay +
Flutter overlay split (because the wordmark font, date band, conditional
CTA must stay in Dart). The 4 fixes above are local, ~80 lines of
edits, and don't change any asset pipeline.

## Verification

- `flutter analyze lib/features/splash/splash_screen.dart` → clean.

## Expected impact

On a mid-range Android, each frame of the infinite bob previously did:

- 8× SVG XML parse
- 8× `Opacity` saveLayer + composite
- Full subtree rebuild of all 8 glyphs

Now each frame of the bob does:

- 8× `Transform.translate/rotate/scale` (cheap, no rebuild of children)
- No `saveLayer`
- No SVG parsing
- Each glyph repaints into its own layer, isolated from the
  centerpiece

The entrance phase additionally avoids 5 `saveLayer`s on the
centerpiece elements.

## User prompt (verbatim)

> in android application , I think splash screen is heavy to load,
> it seems there spends some time so the user feels boring. I think
> this is because there's many animations on this splash. So how can
> i improve it? recommend the methods
>
> before this apply, Can i improve the animation by using Rive?
>
> yes

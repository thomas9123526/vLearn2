# in android application , I think splash screen is heavy to load, it seems there 

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T01:53:37.762Z

## User

in android application , I think splash screen is heavy to load, it seems there spends some time so the user feels boring.
I think this is because there's many animations on this splash. So how can i improve it?
recommend the methods

## Assistant

Here's what's actually expensive in [splash_screen.dart](flutter_app/lib/features/splash/splash_screen.dart), ranked by impact:

## The big one: SVGs re-parsed every frame

[`SvgPicture.string(...)` at line 503-507](flutter_app/lib/features/splash/splash_screen.dart#L503-L507) sits **inside `AnimatedBuilder.builder`** ([line 469](flutter_app/lib/features/splash/splash_screen.dart#L469)). That builder runs on **every frame of `_bob`** (infinite, 60fps) for **8–9 glyphs**. Each call re-parses the SVG XML from scratch. This alone is likely 60–80% of your jank.

**Fix:** parse once in `initState`, pass as `child:` to AnimatedBuilder so it isn't rebuilt:

```dart
// In _FloatingGlyph: pre-build the SvgPicture once
late final Widget _svg = SvgPicture.string(
  _glyphSvg(widget.spec.kind, widget.spec.color),
  width: widget.spec.size, height: widget.spec.size,
);

AnimatedBuilder(
  animation: ...,
  child: _svg,                          // ← static subtree, not rebuilt
  builder: (context, child) => Positioned(
    ...,
    child: Opacity(opacity: opacity, child: Transform.rotate(angle: rotation,
      child: Transform.scale(scale: scale, child: child))),  // ← reuse
  ),
)
```

## #2: `bob` runs forever, rebuilding 8 widgets at 60fps

Even after the entrance is done, every frame rebuilds 8 glyphs + recomputes sin/cos + Opacity + 2× Transform. On a mid-range Android, that's a steady ~5–8ms/frame of pure splash cost.

**Fixes (pick one):**
- Wrap each glyph in `RepaintBoundary` so they don't dirty the centerpiece.
- Stop the `_bob` controller after `_autoNavDelay` fires (returning users) — there's no point bobbing while we're navigating away.
- Reduce `_bob` fps: use a `Timer.periodic(33ms)` instead of vsync, or just drop to fewer glyphs on mobile.

## #3: `Opacity` is expensive when value < 1

[Lines 496, 606, 651, 699, 754, 824](flutter_app/lib/features/splash/splash_screen.dart#L496) all use `Opacity` widget. Each one with value ∈ (0,1) forces a `saveLayer` — costly on Android GPU.

**Fix:** swap to `FadeTransition` (uses `RenderOpacity`, no saveLayer) and gate it: `if (t >= 1.0) child else FadeTransition(...)`. Better yet, drive entrance with a single `FadeTransition` + `SlideTransition` per element instead of `AnimatedBuilder`.

## #4: SharedPreferences read blocks the CTA

[`_resolveReturning`](flutter_app/lib/features/splash/splash_screen.dart#L79-L88) is fine, but you could prefetch the `authHistoryProvider` synchronously in `main.dart` before `runApp` so the splash never needs `setState` for `_returning`. Removes one re-layout.

## #5: Android native splash → black → Flutter splash

Right now the user sees the Android `launch_background` drawable, then a brief black frame, **then** your Flutter splash starts its 1.5s entrance. Use [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash) to render the same monogram as the native drawable so the handoff is invisible — the user feels things start "instantly".

## #6: Cheap wins

- Move `MediaQuery.sizeOf(context)` ([line 454](flutter_app/lib/features/splash/splash_screen.dart#L454)) **out of** the per-frame builder. Read it once at the top of `_FloatingGlyph.build`.
- Drop `mouth` glyph on Android (it's desktop-only — already true, just confirming).
- Pre-warm by setting `_entrance.duration` to `1200ms` instead of `1500ms`; cut `_bob` to 4 glyphs on Android.

## Priority order if you want me to implement

1. **(biggest win, smallest change)** Cache SVGs as `child:` of `AnimatedBuilder` — see snippet above.
2. Stop `_bob` after 3s on returning users.
3. Add `RepaintBoundary` to each `_FloatingGlyph`.
4. Replace inline `Opacity` with `FadeTransition` for entrance pieces.
5. Add `flutter_native_splash` for the boot-time bridge.

Items 1–4 are local to this file and roughly 30 lines of edits total. Item 5 needs `pubspec` + a small asset + one CLI command.

Want me to apply 1–4 now?

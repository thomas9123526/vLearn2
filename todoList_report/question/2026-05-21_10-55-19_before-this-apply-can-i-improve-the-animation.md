# before this apply, Can i improve the animation by using Rive?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T01:55:19.813Z

## User

before this apply, Can i improve the animation by using Rive?

## Assistant

Short answer: **Rive can help, but it's the wrong tool for *this* splash and won't solve your perceived slowness**. The slowness here is wiring, not rendering. Here's the honest breakdown:

## Where Rive would actually help

Rive replaces vector animations rendered by Flutter widgets with a **compiled animation played by a C++ runtime**. The win is biggest when:

- You have **complex shape morphing** (path interpolation, bones, IK) — Flutter can't do these efficiently at all.
- You want **designer-owned motion** with state machines (idle → hover → press).
- You're animating **many shapes simultaneously** with paths that change.

Your splash is none of those. It's 8 static SVGs with `Transform.rotate` + `Transform.scale` + `Opacity` + a sine bob. Flutter does this **fine** — you're just rebuilding the SVG widget tree every frame, which is the real bug.

## Where Rive will hurt

1. **APK bloat.** rive_common adds ~2.5 MB native code (harfbuzz, miniaudio, yoga, SheenBidi) — the same package that just **broke your Android build** ([the rive_text CMake error](pubspec.yaml) you hit). You're already paying that cost as a transitive dep; using it more doesn't add size, but the build fragility stays.
2. **First-frame is slower, not faster.** `.riv` file must be loaded from assets, decoded, mounted. That's an async hop that defeats "feels instant" — the exact perception problem you're trying to fix.
3. **You can't put the whole splash in Rive.** Wordmark is a font, date band reads `DateTime.now()`, CTA is conditional on `_returning`, slogan is a localized string. Those stay in Dart. You'd end up with **Rive-rendered glyphs + Flutter overlay** — more moving parts, not fewer.
4. **Design re-work.** Current splash mirrors `splash.jsx` exactly. To use Rive you author the glyphs + bob in the Rive editor — a separate skill and toolchain.
5. **No `kIsWeb` Rive on Windows desktop without quirks** — and your project ships to Windows.

## What gives you 90% of the speedup for 5% of the cost

The optimizations I listed (cache SVG in `child:`, RepaintBoundary, stop `_bob`, FadeTransition over Opacity) are local, ~30 lines, no asset pipeline, no native deps. They turn the splash from "rebuild 9 SVG widgets at 60 fps" into "transform 9 cached layers at 60 fps" — which Flutter is genuinely fast at.

## When to revisit Rive

- After applying #1–#4, if you still want **richer motion** (e.g., the glyphs morph, squash, talk to each other) — Rive is the right tool for *that*, not for "play 8 transforms faster."
- If you're going to add **Lottie or Rive elsewhere anyway** (onboarding illustrations, mascot reactions) — then amortizing the runtime cost across multiple surfaces makes sense.

## Verdict

Don't introduce Rive to fix this. Apply 1–4, profile, then decide if you want Rive for **motion expression** rather than **performance**. Want me to go ahead with 1–4?

# Report — 07_animation

**Spec:** [todoList/0516/07_animation.md](../../todoList/0516/07_animation.md)
**Date:** 2026-05-16
**Status:** ✅ Rive integration ready + code-driven fallback (no .riv files authored — those need design assets)

## What was done

- **[features/conversation/widgets/persona_avatar.dart](../../flutter_app/lib/features/conversation/widgets/persona_avatar.dart)** — Wraps `rive.RiveAnimation.asset()` when `riveAsset` is non-null; falls back to a gradient circle with the first letter of the persona name. `isSpeaking: true` triggers an `AnimatedScale` (1.0 → 1.05, 250ms ease-out) + a soft glow `BoxShadow`. No layout flicker.
- **`rive` package** is in pubspec.yaml (from §01 and §04). When `.riv` files arrive in `assets/animations/persona_*.riv`, the avatar will animate them automatically.
- The streak/XP gradient banner on Home and the score ring in Session Report use Flutter's built-in `LinearProgressIndicator` and `CircularProgressIndicator` — that's plenty smooth without Rive.

## Honest call-outs

1. **No .riv assets authored.** I can't create Rive animations from scratch — those need a designer in the Rive editor. The integration is in place: drop `persona_maya.riv` etc. into `flutter_app/assets/animations/` and they'll render. Until then, the gradient-letter fallback works.

2. **Confetti / page-transition animations** mentioned in the spec are not implemented. Implicit Flutter animations + go_router's default page transitions cover the basics; `confetti` package + custom hero transitions would be polish for v1.5.

3. **No Lottie fallback.** If you prefer Lottie over Rive for some assets, add `lottie` to pubspec and create a parallel `LottieAvatar` — they're cheap to add.

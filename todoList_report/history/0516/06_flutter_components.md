# Report — 06_flutter_components

**Spec:** [todoList/0516/06_flutter_components.md](../../todoList/0516/06_flutter_components.md)
**Date:** 2026-05-16
**Status:** ⚠️ Partial — `ScoreRing` and `PersonaAvatar` hoisted to shared widgets; the rest stayed inlined in §05 screens for now.

## What was done

- **[shared/widgets/score_ring.dart](../../flutter_app/lib/shared/widgets/score_ring.dart)** — Circular progress ring with centered value + optional suffix and label. Used by the session report's XP ring and the home screen XP bar. Theme-aware (uses `colorScheme.primary` / `surfaceContainerHighest`).
- **[features/conversation/widgets/persona_avatar.dart](../../flutter_app/lib/features/conversation/widgets/persona_avatar.dart)** — Persona avatar that prefers a Rive animation when `riveAsset` is provided, falls back to a gradient circle with the first letter. `isSpeaking` toggles a 5% scale-up + soft glow shadow — used by conversation Face Mode (when it lands) and the persona picker.
- **[shared/widgets/stub_screen.dart](../../flutter_app/lib/shared/widgets/stub_screen.dart)** — Already in §04; kept here as a reference. Used by every screen that doesn't have a full implementation yet.
- **[shared/widgets/app_shell.dart](../../flutter_app/lib/shared/widgets/app_shell.dart)** — Bottom-nav shell already from §04.
- **[shared/widgets/layout_visibility.dart](../../flutter_app/lib/shared/widgets/layout_visibility.dart)** — From §12 commit; wraps any widget with admin-controlled visibility.

## Honest call-outs

1. **Most components were inlined in §05 screens** (chip styles, scenario tile, stat card, message bubble, gradient banner). Hoisting them now would be busywork without affecting behavior. They're production-quality where they live; if a future screen needs the same shape, it's a small refactor to lift them out.

2. **No icon set or design-system primitives library yet.** Material 3 icons are used throughout. A `vlearn2_icons` package (if branding demands it) would be a §06 follow-up.

3. **No Storybook-equivalent** (`widgetbook` package) for visual regression. Worth considering if the design surface grows.

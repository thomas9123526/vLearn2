# Components — Reusable Widget Catalog

Each component below is referenced in `screens.md`. Implement them as Flutter widgets under `lib/widgets/`. Variants noted where relevant.

---

## Avatar
Round monogram chip. Used in nav, chat headers, persona pickers.

- **Props**: `personaId` (maya/leo/sofia/theo), `size` (28/32/36/40/48/56), `pulse` (bool), `ring` (bool), `ringColor`.
- **Visual**: circle with `persona.gradient` background (135deg), white initial in italic serif, sized to ~0.5× container. Inner shadow + highlight + slowly orbiting conic-gradient glow.
- **Pulse**: when `pulse=true`, two animated rings expand outward + fade (1.8s loop, 0.6s stagger).

## PersonaChip (chat header variant)
Small (28–42 dp) round chip with `tutorBlue` solid bg + persona initials + green online dot at bottom-right corner. Used in the conversation transcript.

## TalkingAvatar
Animated stylized SVG face. The hero element on the conversation screen.

- **Props**: `personaId`, `mode` ('idle' | 'listening' | 'thinking' | 'speaking'), `size`, `theme`.
- **Looks** per persona — see `reference/ui.jsx` lines 90–130 for exact path data (Maya/Leo/Sofia/Theo have distinct hair, skin, accessory). Reuse `flutter_svg` with template strings or rebuild as `CustomPainter`.
- **Animations**:
  - `speaking` → head bob (1.1s ease-in-out loop) + mouth `scaleY` 0.4→1.2→0.7 (420ms loop) + inner mouth ellipse opens.
  - `listening` → head tilt rotate ±2° (3s loop) + eyebrow lift (2.4s loop).
  - `thinking` → mouth horizontal squeeze (1.8s loop).
  - Always-on: eyes blink (~5s natural interval, 0.1s closed).
- **Outer rings**: when speaking or listening, 2 pulsing accent rings expand outward.

## ScoreRing
Circular progress with center number.

- **Props**: `value` (0–100), `size`, `stroke`, `color`, `track`, `ink`, `sub`.
- Two concentric `CircleAvatar`-style arcs; foreground sweeps from 0 to (value/100)·360° over 1500ms ease-out.
- Center text: count-up number (`display`) + optional small overline sub.
- **AnimatedScoreRing** variant (used on Report): adds 8 orbiting sparkles (each on a 2.4s sparkle animation, staggered 150ms) + radial burst behind (1.2s on mount).

## AnimatedBar
Linear progress that grows 0 → target value.

- **Props**: `value` (0–100), `color`, `track`, `height` (default 6), `label`, `delay`, `duration` (default 900ms).
- Grows on mount with `easeOutCubic`. Optional shimmer sweep on top while animating.

## AnimatedNumber
Count-up text. Takes `value`, `duration`, `decimals`, `delay`. Tween `int`/`double` and render as text. Restarts when `value` or `key` changes.

## Card
- Background: theme `surface`, border-radius 18, 1-dp border at `border` color.
- Shadow: `card` token (inset highlight + soft drop).
- Optional `hoverable` flag for the lift-on-hover variant (translateY -2 + larger shadow).

## Button
Four variants: `primary` (filled accent + glow), `soft` (accentSoft bg + accentInk text), `outline` (surface + border), `ghost` (transparent).

- **Sizes**: sm/md/lg with their own padding/radius/font-size.
- **Press**: scale 0.97 while pressed (140ms).
- **Icons**: leading or trailing.

## Chip
Pill button (radius 999). Used for categories + quick replies.

- `active` flag swaps to accent bg + white text.
- Optional leading icon.

## SectionHead
Above-section title group: small `overline` kicker (uppercase, letter-spaced) + display H2 below. Optional trailing action button (e.g. "All scenarios →").

## Bubble (chat)
Tutor or user message bubble. See `screens.md` §6.

## VoiceBubble
Inset card with play button + 22 fixed-height bars (sinusoidal heights) + duration mono.

## TipCard
warn-tinted card with bulb icon, "Tip from {persona}" header, correction body.

## DoubleCheck (icon)
Two overlapping checkmark strokes. Used after user message timestamps.

## ConfettiBurst
Mount-on-screen 24–36 colored pieces falling from top with randomized dx, rotation, duration (2400–4000ms ease-in-out), shape (rect/circle/diamond).

## Waveform
N bars (12–28), each randomly seeded height + delay, scaleY 0.3↔1 loop. Used inside the active mic button.

## Tabs / Sidebar
- **Mobile bottom tabs**: 4 items, icon + 10-dp label, accent for active.
- **Desktop sidebar**: 220 dp wide, logo + 5 items + filled "Quick talk" CTA + profile footer.

---

## Composition examples

**A primary CTA with mic icon, like Home hero:**
```dart
PrimaryButton(
  size: ButtonSize.md,
  icon: Icon(Icons.mic, size: 16),
  label: l10n.startTalking,
  onPressed: () => Navigator.pushNamed(context, '/brief'),
)
```

**A score ring with sub-label that animates on mount, like Report:**
```dart
AnimatedScoreRing(
  value: overallScore,          // 76
  size: isDesktop ? 160 : 130,
  stroke: 12,
  color: theme.accent,
  track: theme.accentSoft,
  ink: theme.ink,
  sub: l10n.overall,
)
```

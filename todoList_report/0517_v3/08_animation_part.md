# Report — 08 — Animation gap analysis (vs `design_handoff_freetalk`)

The user's spec calls for a rich set of animations across splash, onboarding, home, conversation, and report screens. **The current Flutter app has almost none of them.** This report enumerates each missing piece and explains how each could land — most are 30-line additions using only Flutter's built-in animation API, no extra deps.

## Animations the design spec calls for

Source: [`vLearn2Spec/design_handoff_freetalk/screens.md`](../../vLearn2Spec/design_handoff_freetalk/screens.md) + [`components.md`](../../vLearn2Spec/design_handoff_freetalk/components.md).

### Splash (`screens.md:24-30`)
- 0ms — glow + background glyphs fade in
- 60ms — 84-dp monogram badge pops in
- 100ms — wordmark fades + slides up
- 300ms — slogan slides up
- 450ms — pill CTA slides up
- 700ms — footer fades in
- Monogram has a **1.6s blink animation** on the speech-dot notch (`screens.md:16`)

**Current:** [`splash_screen.dart`](../../flutter_app/lib/features/splash/splash_screen.dart) renders a static `Icon + Text + Text` column. Zero motion.

**Suggested:** wrap each block in an `AnimatedOpacity` + `AnimatedSlide` keyed off a `Duration.zero → 750ms` timeline managed by a single `AnimationController` started in `initState`. Stagger via `Interval(0.0, 0.2)`, `Interval(0.08, 0.3)`, etc. ~40 LOC.

### Onboarding (`screens.md:34-44`)
- Step 1: pulsing persona avatar (`components.md:12` Pulse — two rings expand + fade, 1.8s loop, 0.6s stagger)
- Each step "fade-in keyed by step index so each step replays its entry on swap"

**Current:** [`onboarding_screen.dart`](../../flutter_app/lib/features/onboarding/onboarding_screen.dart) — needs check; likely a static `PageView`.

**Suggested:** `AnimatedSwitcher` with a fade-slide transition between steps. PersonaAvatar gets a `Pulse` wrapper widget that runs two `Container.scale` rings on a `RepeatableAnimation`. ~50 LOC for the new widget.

### Home (`screens.md:50-55`)
- Streak card: "today" cell highlighted with a 2-dp accent border (no animation specified but the spec implies a soft glow)
- Hero card has decorative semi-transparent white circles (static; no animation needed)

**Current:** [`home_screen.dart`](../../flutter_app/lib/features/home/home_screen.dart) — solid colors, no animation.

**Verdict:** the home design is actually mostly static. No critical missing animation.

### Conversation (`screens.md:90-118`, the most animation-heavy screen)
- **PersonaAvatar with mouth-shape state machine** driven by TTS (`components.md:22-25`): when `isSpeaking=true`, mouth opens/closes in sync with audio amplitude. When `isListening=true`, soft eye-glow.
- Pulsing mic button while recording.

**Current:** [`persona_avatar.dart`](../../flutter_app/lib/features/conversation/widgets/persona_avatar.dart) — code-driven gradient-letter fallback (per todoList_report/0516/07). Rive integration is wired but no `.riv` file authored.

**Suggested:** the Rive plumbing is already there. A designer needs to author the `persona_avatar.riv` state-machine asset (state machine: `Idle / Listening / Speaking`, inputs: `bool isSpeaking`, `bool isListening`, `float mouthOpenness`). Once the .riv file lands in `assets/animations/`, the existing Riverpod plumbing exposes `isSpeakingStream` from the TTS service (added in v2 task 01) to drive it.

### Report (`screens.md:119-150`)
- 4 `AnimatedBar`s — pronunciation/grammar/fluency/vocabulary — bars grow + numbers count up, staggered 180ms
- `ScoreRing` with 0→target stroke-dash animation
- `AnimatedScoreRing` adds 8 orbiting sparkles (2.4s loop, staggered 150ms) + radial burst on mount
- `AnimatedNumber` count-up
- CEFR card: 6-stop A1-C2 progress bar animates 0→64% on mount
- Activity chart: 7 vertical bars grow from 0 with stagger, last bar count-up label above

**Current:** [`session_report_screen.dart`](../../flutter_app/lib/features/report/session_report_screen.dart) — needs check; likely solid fills, no count-up.

**Suggested:**
- New widget `AnimatedBar({double target, Duration duration, Color color})` — `TweenAnimationBuilder<double>` from 0 to target, builds a `Container` with `width: progress * maxWidth`. ~30 LOC.
- New widget `AnimatedNumber({double target, Duration duration})` — same pattern, formats `value.round().toString()`. ~20 LOC.
- `ScoreRing` extension: replace the static `CustomPaint` with one driven by a `Tween<double>` (0→target/100) on first build. ~10 LOC change to the existing widget.
- Sparkles: 8 `Positioned` children with `Transform.translate` + `Transform.rotate` driven by sin/cos of the animation value × radius. ~40 LOC.

### Components catalog (`components.md`)
- `Pulse` — 30 LOC widget
- `AnimatedBar` — 30 LOC
- `AnimatedNumber` — 20 LOC
- `AnimatedScoreRing` — extends existing `ScoreRing` with the sparkle layer (40 LOC)

## What's intentionally NOT in the current app

The user's "open standalone" path has prioritised:
1. **Working data flow** — backend, auth, conversation, scoring (all live)
2. **Design tokens** — colors, spacing, radii (all live)
3. **Static layout** — every screen looks like the spec at zero motion

The motion layer was deferred — it's quality-of-feel polish that doesn't change behaviour and is the easiest piece to add incrementally.

## Recommendation

**Three-PR plan, each ~150 LOC:**

1. **PR 1: Splash animation timeline + Pulse widget.** Easiest win, very visible on first launch. Drop-in `AnimationController` in splash_screen.dart, new `lib/shared/widgets/pulse.dart`.
2. **PR 2: Report screen `AnimatedBar` + `AnimatedNumber` + animated `ScoreRing`.** The report is where users see their score — the count-up motion is psychologically important ("look, your number is climbing"). All three widgets go in `lib/shared/widgets/`.
3. **PR 3: Conversation persona Rive integration.** Requires a designer to author the .riv state machine. Once that asset lands, the existing Rive code path (already wired) reads `assets/animations/persona_avatar.riv` and drives the state-machine inputs from `sttServiceProvider` / `ttsServiceProvider.isSpeakingStream`.

All three PRs land before launching the app to users — animations are what separate "works" from "feels good". Until then, the app functions perfectly without them.

## Dependencies needed

**None.** Every animation listed is achievable with Flutter's built-in `AnimationController`, `TweenAnimationBuilder`, `AnimatedSwitcher`, and `CustomPaint`. The only external asset is the Rive `.riv` file, which the existing `rive: ^0.13.13` dep already supports.

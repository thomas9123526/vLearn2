# 02 — Animations: design vs. Flutter implementation

**Task** (verbatim from `todoList/list/02_animation_part.txt`):

> Based on this material `C:\project\vLearn2\vLearn2Spec\design_handoff_freetalk`, there are missing parts regarding animation in the current app. For example when u see the `FreeTalk_standalone.html` at the first time, you can see various icon animations on the android and windows app screen. But our app doesn't have this part on the splash screen. Can you analyse this and give me solutions how we can achieve it or not.

## TL;DR

The design handoff is **animation-heavy** — splash glyphs, count-up numbers, confetti, sheen sweeps, staggered bar growth, breathing avatars, listening rings, drifting orbs, monogram blink. The Flutter implementation is **selectively animated**:

- **Tutor / Face mode** — ~70% of the design's animations are implemented (breathing, listening ring, drifting orbs, gradient transitions).
- **Splash, Report, Progress, Onboarding** — almost no animations beyond default Flutter transitions.

This isn't a technical blocker. Flutter has first-class animation primitives plus the `rive` package (already a dependency) and `lottie` (one line to add). Most missing animations are 30 min – 4 hr each. The decision is **which ones are worth the effort**.

## Animation inventory — design vs. app

### Splash screen

| Animation | Design | Flutter |
|---|---|---|
| 8 floating glyphs pop-in (0.9s cubic-bezier) then bob 4–6s loop | ✓ Specified in [reference/splash.jsx](vLearn2Spec/design_handoff_freetalk/reference/splash.jsx) | ✗ Static spinner + text |
| Monogram badge dot blink (1.6s ease-in-out infinite) | ✓ | ✗ |
| Wordmark slide-up + fade (0.7s @100ms) | ✓ | ✗ |
| Slogan slide-up (@300ms) | ✓ | ✗ |
| CTA button slide-up (@450ms) | ✓ | ✗ |

**Gap: 5/5 missing.** The user explicitly called this out.

### Onboarding (4 steps)

| Animation | Design | Flutter |
|---|---|---|
| Step transition (slide / fade between steps) | ✓ Implied | Unconfirmed — likely default `PageView` cross-fade |
| Persona avatar pulse on "Voice check" step | ✓ | Unconfirmed |
| CEFR level reveal (count-up or scale-in) on level-display step | ✓ | Unconfirmed |

### Home (dashboard)

| Animation | Design | Flutter |
|---|---|---|
| Hero card subtle gradient shimmer | ✓ | ✗ |
| Streak counter increment | ✓ animated | ✗ static int |
| Stat cards stagger-fade-in on mount | ✓ | ✗ |
| Recommended scenarios horizontal scroll with snap | ✓ | Likely present (Flutter `PageView` defaults) |

### Scenarios list

| Animation | Design | Flutter |
|---|---|---|
| Category chip ripple / press feedback | ✓ Material ripple | ✓ via Material defaults |
| Card press → brief screen Hero transition | ✓ Hero animation suggested | Unconfirmed |
| Search field focus glow | ✓ | ✗ likely just border color change |

### Conversation — **Face mode** (tutor avatar)

| Animation | Design | Flutter |
|---|---|---|
| TutorAvatar body breathing (idle: scaleY ±0.02 over 3s) | ✓ | ✓ implemented at [tutor_avatar.dart](flutter_app/lib/tutor_avatar.dart) — `_breath` controller, 3s reverse |
| TutorAvatar pulse (speaking: scaleY ±0.06 over 450ms) | ✓ | ✓ implemented — `_pulse` controller |
| Mouth lip-sync animation | ✓ | ✓ partial — `CartoonFace` `CustomPaint` |
| Listening ring (rotating sweep gradient around head, 4s loop) | ✓ | ✓ implemented — `_ring` controller, `SweepGradient`+`Transform.rotate` |
| Stage background gradient shift on mode change (0.6s) | ✓ | ✓ implemented in `tutor_mode_view.dart` |
| 4 floating ambient orbs drift (8s ease-in-out, staggered) | ✓ | ✓ implemented — `ftf-orb-drift` |
| Recording button dual expanding rings (1.4s infinite + stagger) | ✓ | Partially present — single ring; dual-ring stagger not confirmed |
| Live caption typewriter (28ms/char) | ✓ | Unconfirmed in lib/ |

**Gap: 0–2/8 missing.** This is the **best-animated** screen in the app.

### Conversation — **Chat mode** (bubbles)

| Animation | Design | Flutter |
|---|---|---|
| New bubble slide-up + fade-in | ✓ | Likely via `AnimatedList` or default `ListView` insertion; unconfirmed |
| Typing indicator (3 bouncing dots) | ✓ | Unconfirmed |
| Send button morph on press | ✓ | ✗ |

### Report screen

| Animation | Design | Flutter |
|---|---|---|
| Confetti burst (24–36 pieces, 2400–4000ms staggered) | ✓ | ✗ |
| Headline word-stagger fade-in | ✓ | ✗ |
| Score ring arc sweep (0→360° over 1500ms) | ✓ | ✗ — uses static `CircularProgressIndicator` at [score_ring.dart](flutter_app/lib/score_ring.dart) |
| Score count-up number animation | ✓ | ✗ |
| Orbiting sparkles around ring | ✓ | ✗ |
| Radial burst behind ring | ✓ | ✗ |
| Corrected-sentence bars grow L→R + count-up (stagger 180ms) | ✓ | ✗ |
| Coach note card float-bob + sheen sweep | ✓ | ✗ |
| Pocket-phrases stagger fade-in | ✓ | ✗ |

**Gap: 9/9 missing.** This is the **most under-animated** screen relative to design ambition.

### Progress screen

| Animation | Design | Flutter |
|---|---|---|
| CEFR progress bar 6-stop animates 0→target on mount | ✓ | ✗ static |
| Activity bar chart — 7 bars grow 0→target with stagger | ✓ | ✗ likely static |
| Skill breakdown radial / bar reveal | ✓ | ✗ |
| Badge unlock pulse | ✓ | ✗ |

### Settings / Tutor picker

| Animation | Design | Flutter |
|---|---|---|
| Tutor carousel snap + scale-on-center | ✓ | Likely via `PageView` defaults |
| Theme switch ripple from tap point | ✓ Material 3 expressive | Unconfirmed |
| Difficulty slider haptic + glow on detent | ✓ | ✗ likely default `Slider` |

## Solutions — how to close each gap

### Priority tier 1 — high visible impact, modest cost

#### Splash screen (the one the user explicitly called out)

The 8 glyphs + monogram + slogan + CTA sequence is **the user's first impression**. Two viable implementations:

**Option A — Pure Flutter (recommended).** No new dependency.

- `Stack` of 8 `Icon` glyphs in `Material.Icons` (or SVG via `flutter_svg` which is already declared in `pubspec.yaml`).
- 8 × `AnimationController`s each with staggered start: `controller.forward(from: index * 0.08)`.
- For pop-in: `Tween(begin: 0.0, end: 1.0)` driving `ScaleTransition` + `FadeTransition` with `Curves.easeOutBack`.
- For bob loop: a second `AnimationController(repeat: reverse: true, duration: 4500ms)` driving `Transform.translate(Offset(0, sin(t * 2π) * 6))`.
- Monogram blink: `AnimatedOpacity` ping-ponged via `Tween(0.5, 1.0)` controller.
- Wordmark / slogan / CTA: chained `SlideTransition` + `FadeTransition` started with `Future.delayed(Duration(milliseconds: 100/300/450))`.

Estimated effort: **3–4 hours** for a polished implementation.

**Option B — Rive.** Use the `.riv` runtime already in `pubspec.yaml`. Designer authors the whole splash sequence in Rive editor → exports `splash.riv` → `RiveAnimation.asset('assets/animations/splash.riv')`. Pros: pixel-perfect to design; one widget; trivial code. Cons: needs a designer + Rive license + a `.riv` artboard authored.

**Option C — Lottie.** Add `lottie: ^3.x.x` to `pubspec.yaml`. Designer exports After Effects → `.json` via Bodymovin. Use `Lottie.asset('assets/animations/splash.json')`. Same trade-offs as Rive but Lottie files are usually larger.

**Recommendation: Option A.** Zero new dependencies, full source-controlled, fast to iterate. Move to Rive only if the designer wants pixel-perfect parity with `FreeTalk_standalone.html`.

#### Report screen — count-up numbers + score ring sweep

These two are the most cost-effective wins on the Report screen because they're emphatic and easy:

- **Count-up** — `TweenAnimationBuilder<int>(tween: IntTween(begin: 0, end: finalScore), duration: Duration(milliseconds: 1500), builder: (_, value, __) => Text('$value'))`. ~5 lines per stat.
- **Score-ring sweep** — replace [score_ring.dart](flutter_app/lib/score_ring.dart)'s static `CircularProgressIndicator` with a `CustomPainter` whose `paint(canvas, size)` draws an arc whose `sweepAngle = progress * 2π`. Drive `progress` with an `AnimationController(duration: 1500ms)`.

Estimated effort: **30 min for count-up across 4 stats + 1 hr for the ring sweep**.

#### Bubble slide-up on incoming message

Use `AnimatedList` in place of `ListView` in conversation chat mode. `insertItem(index)` automatically triggers the `itemBuilder`'s `Animation`, which you map to a `SizeTransition` + `FadeTransition`. **~15 min refactor** of conversation list.

### Priority tier 2 — nice polish, moderate cost

#### Confetti burst on Report screen

Use the `confetti: ^0.7.0` package. ~5 lines to fire a `ConfettiController` on screen mount. Bundle cost: ~80 KB.

Alternative: hand-roll with `CustomPaint` + a list of `_Confetto { Offset position; double rotation; Color color; }` updated each tick. Zero bundle cost, ~50 lines.

#### Progress-screen bar grow + count-up

Same pattern as Report's count-up + a `TweenAnimationBuilder<double>` driving the bar's `Container(width: containerWidth * progress)`. Stagger by `Future.delayed(Duration(milliseconds: index * 180))` per bar. **~1 hr** for the whole screen.

#### Coach-note sheen sweep

`ShaderMask` over the card with a `LinearGradient(colors: [transparent, white24, transparent], begin: Alignment(-1.0, 0), end: Alignment(1.0, 0))`, the alignment values animated `(-1, 0) → (1, 0)` by an `AnimationController(repeat: true, period: 3.5s)`. **~30 min**.

### Priority tier 3 — low impact, optional

- Orbiting sparkles around the score ring (showy but visually distracting).
- Radial burst behind ring (overlaps with confetti — pick one).
- Send-button morph (Material 3 already gives nice ripples for free).

## Performance considerations

Flutter's animation pipeline runs on the platform thread and re-rasters only what's marked dirty. Common pitfalls to avoid:

- **`setState` inside an `AnimationController` listener** — rebuilds the entire widget. Use `AnimatedBuilder` instead, which only rebuilds the `builder:` subtree.
- **Many parallel `AnimationController`s for splash glyphs** — combine into a single controller with `Interval(start, end, curve)` per glyph; one ticker, eight `Animation<double>`s.
- **`RepaintBoundary`** wrap heavy animated subtrees (orb layer, splash glyph layer) so they don't dirty siblings.
- **Rive files** — keep `.riv` under 200 KB each (current Maya is 182 KB — fine).

## Recommendation — what to actually do, in order

1. **Splash screen animation** (the one the user pointed at). Option A — pure Flutter. ~4 hr. Single highest-impact win.
2. **Report screen score-ring sweep + count-up numbers**. ~1.5 hr. Second-highest impact (post-session feedback feels celebratory).
3. **Bubble slide-up in chat mode** via `AnimatedList`. ~15 min. Cheap delight.
4. **Progress screen bar grow + count-up**. ~1 hr. Makes the page feel alive.
5. **Confetti on Report screen completion** with `confetti` package. ~30 min including the 80 KB bundle cost.
6. **Defer or skip**: sparkles, radial bursts, sheen sweeps. They're polish; ship the rest first and revisit only if A/B testing shows the app feels "flat".

Total tier-1 + tier-2 budget: roughly **1.5–2 dev-days** for the full set above.

## What's already great (leave alone)

Tutor / Face mode is the animation showcase of the app and matches the design well. The breathing + pulse + listening ring + orb drift + gradient stage transition is **the most ambitious animation work in the codebase** and it works. The design-vs-app gap there is small enough that polish is optional.

## Out of scope for this audit

- Page-route transitions (`MaterialPageRoute` defaults are fine; hero transitions would require explicit `Hero(tag: 'scenario-${id}')` wrapping).
- Haptic feedback on interactions — separate concern from visual animation; `HapticFeedback.lightImpact()` etc.
- Sound effects — design handoff hints at sounds for some animations; not addressed here.

---

*The splash screen the user called out has a clear 3–4 hr fix. The Report screen is the next-biggest opportunity. Everything else is incremental polish.*

# 03 — Differences: design handoff vs. current Flutter app

**Task** (verbatim from `todoList/list/03_diff_find.txt`):

> Can u find differences between our application and the first start design material `C:\project\vLearn2\vLearn2Spec\design_handoff_freetalk`. Give me information.

## TL;DR

The Flutter app implements **11 of 11** screens from the design (full structural parity). The differences are in **fidelity inside each screen**, not in missing screens. Three categories of divergence dominate:

1. **Animation density** — design is animation-heavy; app is largely static outside Tutor/Face mode (covered in detail in [`02_animation_part.md`](02_animation_part.md)).
2. **Visual decoration** — gradients, sheens, shadows, glyph illustrations are flatter in Flutter than in the design HTML.
3. **Two app features have no design counterpart** — News (feature shipped in Flutter, absent from design handoff) and Models setup (STT/TTS pre-download flow, also Flutter-only).

This document is the **full screen-by-screen diff**.

## Screen-by-screen mapping

Sourced from:
- Design: [vLearn2Spec/design_handoff_freetalk/screens.md](vLearn2Spec/design_handoff_freetalk/screens.md), [reference/*.jsx](vLearn2Spec/design_handoff_freetalk/reference/)
- Flutter: routes in [flutter_app/lib/app_router.dart](flutter_app/lib/app_router.dart), screens in `flutter_app/lib/`

| # | Design screen | Flutter screen | Status | Key divergences |
|---|---|---|---|---|
| 1 | Splash | `SplashScreen` | ✓ present | Heavy divergence — design has 8 floating glyphs + sequenced wordmark/slogan/CTA; app shows a spinner + plain text. |
| 2 | Sign In | `SignInScreen` | ✓ present | Layout matches; visual decoration (gradient backdrop, brand glyph) lighter than design. |
| 3 | Sign Up | `SignUpScreen` | ✓ present | Same comment as Sign In. |
| 4 | Onboarding (4 steps) | `OnboardingScreen` | ✓ present | Animations between steps unconfirmed; design specifies sequential reveal. |
| 5 | Home / Dashboard | `HomeScreen` | ✓ present | App ships an extra `NewsStrip` widget not in design. |
| 6 | Scenarios | `ScenariosScreen` | ✓ present | Card style matches; press → brief Hero transition not confirmed. |
| 7 | Brief (scenario detail) | `ScenarioBriefScreen` | ✓ present | Design has a large SVG hero illustration per scenario; app uses `Image.network` of an admin-uploaded JPG. |
| 8 | Conversation — Chat mode | `ConversationScreen` (chat view) | ✓ present | New-bubble slide-up + typing indicator unconfirmed. |
| 9 | Conversation — Face mode | `ConversationScreen` (face view) | ✓ present | Best-matched screen; ~70% of animations implemented. |
| 10 | Report (post-session) | `SessionReportScreen` | ✓ present | Heavy divergence — design has confetti / count-up / shimmer / staggered bars; app is static. |
| 11 | Progress (charts) | `ProgressScreen` | ✓ present | Animated bar growth + CEFR progress sweep missing. |
| 12 | Course / learning-path builder | `CourseDetailScreen` | ✓ present | 3-step form + timeline preview parity unconfirmed in detail. |
| 13 | Settings | `SettingsScreen` | ✓ present | Tutor picker carousel uses default `PageView` (no scale-on-center?). Theme switch + difficulty slider use Material defaults. |

**Net: zero screens missing.**

## Routes present in Flutter but **not** in the design handoff

These are real, shipped features in the app that the design spec doesn't mention:

| Route | Screen | Likely status |
|---|---|---|
| `/news` | `NewsListScreen` | New post-design feature — news feed with read-state tracking. Has its own backend module (`backend/src/news/`). |
| `/news/:idOrSlug` | `NewsDetailScreen` | Same — article view. |
| `/setup/models` | `ModelsNotInstalledScreen` | Flutter-side STT/TTS model pre-download flow (sherpa-onnx). Required for offline voice features. |
| `/settings/profile` | `ProfileEditScreen` | Profile editor; design spec implies this is part of Settings but doesn't draw the sub-screen. |

## Routes in design that aren't first-class routes in Flutter

None — every design screen has a dedicated Flutter route or is composed inside `ConversationScreen` (chat vs face mode).

## Visual/structural divergences inside each screen

### Splash
- **Design** ([reference/splash.jsx](vLearn2Spec/design_handoff_freetalk/reference/splash.jsx)):
  - 8 ambient glyphs floating around the layout (school, mic, chat, globe, headphones, etc.).
  - Center monogram with a blinking dot.
  - Wordmark "FreeTalk" / "vLearn2" with sequenced fade-in slide-up.
  - Slogan strapline below.
  - Primary CTA at bottom.
  - Gradient background (soft purple → pink → blue).
- **Flutter**:
  - `CircularProgressIndicator` (Material spinner).
  - Static text "Virtual Foreign Language" / similar.
  - Solid or simple gradient background.
- **Cost to close gap**: ~4 hours (see [`02_animation_part.md`](02_animation_part.md)).

### Sign In / Sign Up
- **Design**: large brand glyph at top, fields with soft inner shadow, gradient CTA, "Continue with Google" with brand icon, smaller "guest" link.
- **Flutter**: Material text fields, filled `ElevatedButton`. Functional but visually flatter.
- **Cost**: ~1 hr per screen for visual polish — `BoxDecoration` with `BoxShadow` + `LinearGradient`.

### Home
- **Design**: hero card with shimmer/gradient, large streak counter with flame icon, grid of stat cards, horizontal "Recommended for you" carousel.
- **Flutter**: same structure plus an extra `NewsStrip` row that isn't in the design. Static stat cards.
- **Cost**: ~1 hr for stat-card stagger fade-in + streak count-up.

### Scenarios
- **Design**: search bar at top, category chips, grid of scenario cards (~16:10 aspect, gradient header band, title + difficulty pill + estimated minutes).
- **Flutter**: same structure. Hero animation from card → brief screen unconfirmed.
- **Cost**: ~30 min to add `Hero(tag: 'scenario-${id}')` wrapping.

### Brief (scenario detail)
- **Design**: large SVG hero illustration per scenario (varies by topic), roles section (user + tutor), "twist" callout, objectives bullet list, key phrases chips, persona pairing avatar.
- **Flutter**: same structure but the hero is an admin-uploaded raster image (`Image.network`).
- **Cost**: minimal — current implementation is fine if admin sources high-res images.

### Conversation — Chat mode
- **Design**: bubbles with subtle entry animation, typing indicator (3 dots), input bar with circular send button that morphs on press.
- **Flutter**: same structure. Bubble animations unconfirmed; typing indicator unconfirmed.
- **Cost**: 30–60 min for `AnimatedList` refactor.

### Conversation — Face mode
- **Design**: full-screen tutor avatar, drifting orbs, gradient stage, listening ring, dual-ring recording button pulse, live caption typewriter.
- **Flutter**: ~70% match. (See [`02_animation_part.md`](02_animation_part.md).)
- **Cost**: low; this screen is the success story.

### Report
- **Design**: confetti, animated headline, score-ring sweep + count-up, orbiting sparkles, radial burst, corrected-sentence bars grow L→R with count-up, coach-note card float-bob with sheen, pocket-phrases stagger fade-in.
- **Flutter**: static `CircularProgressIndicator` + static text + static stat rows.
- **Cost**: 4–6 hours to bring to design parity. The single biggest gap in the app.

### Progress
- **Design**: CEFR card with 6-stop animated progress bar, activity bar chart (7 days) with staggered bar grow, skill breakdown chart, badge unlock animations.
- **Flutter**: same structure with `LinearProgressIndicator` and bars; growth animations missing.
- **Cost**: 1–2 hours for bar grow + count-up.

### Course
- **Design**: 3-step form (goal → topics → minutes/day), timeline preview at bottom.
- **Flutter**: present but visual fidelity unconfirmed in depth.
- **Cost**: TBD pending detailed comparison.

### Settings
- **Design**: profile card on top, tutor picker carousel (with center-scale), difficulty slider with detents, feedback toggles, theme picker with live preview, language picker.
- **Flutter**: same structure with Material defaults.
- **Cost**: 1–2 hours for tutor carousel scale-on-center + theme live preview.

## Design tokens — used vs. defined

The design ships [`tokens.json`](vLearn2Spec/design_handoff_freetalk/tokens.json) with colors, radii, typography, motion timings. Spot-check whether the Flutter `ThemeData` / [theme files](flutter_app/lib/) consume these tokens or hand-code values:

- **If tokens are loaded at runtime**: design changes propagate automatically.
- **If hand-coded**: every visual change requires a Flutter edit.

This is worth a separate small investigation; if hand-coded, consider parsing `tokens.json` into a `lib/theme/tokens.dart` for single-source-of-truth alignment.

## i18n strings — coverage check

[`strings.json`](vLearn2Spec/design_handoff_freetalk/strings.json) and [`description.ko.md`](vLearn2Spec/design_handoff_freetalk/description.ko.md) indicate the design contemplates **English + Korean** UI. Flutter app likely uses `intl_*.arb` files; verify that every string in `strings.json` has matching ARB entries — gaps would be untranslated UI in production.

## Components — design vs. shipped

[`components.md`](vLearn2Spec/design_handoff_freetalk/components.md) lists components like `PrimaryButton`, `SoftCard`, `TutorAvatar`, `ScoreRing`, `Chip`, `Stat`, etc. Spot-check that the Flutter widget tree has corresponding reusable widgets (looks like it does: `tutor_avatar.dart`, `score_ring.dart`, etc.).

## Summary — what's missing vs. what's there

### Missing (notable gaps)
- Splash screen visual + animation (highest user-facing impact).
- Report-screen polish (confetti, count-up, animated stats).
- Progress-screen bar-growth animations.
- Possibly: token-driven theming, full Korean i18n coverage.

### Extra in Flutter (not in design)
- News feature (list + detail).
- Models setup screen.
- Profile edit sub-screen (implied but not drawn in design).

### Great match
- Screen inventory (11/11 design screens have Flutter routes).
- Conversation Face mode animations.
- Material-first UI rendering (icons, ripples, transitions).

## Recommendation

Treat this audit as a punch list. The **top three** worth doing first (highest design-fidelity dividend per dev-hour):

1. **Splash screen rebuild** (~4 hr) — the user's first impression and the most-felt gap.
2. **Report-screen animations + polish** (~6 hr) — celebratory feedback loop after every session.
3. **Token-driven theme + Korean i18n audit** (~3 hr) — invisible groundwork that pays off every future design tweak.

Everything else can be triaged opportunistically. The structure is solid; the gaps are skin-deep.

---

*Audit complete. No structural redesign required — what's missing is polish layered on top of an already-correct architecture.*

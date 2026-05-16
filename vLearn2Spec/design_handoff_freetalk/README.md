# Handoff: FreeTalk — English Speaking App

> **Status:** Hi-fi design system + interactive HTML prototype, ready for Flutter implementation.
> **Targets:** Android (mobile) + Windows desktop. Same codebase, responsive layouts.

---

## About the Design Files

The HTML files in `reference/` are **design references** — interactive prototypes built in HTML/React showing intended look, layout, animation, and behavior. They are **not production code to copy directly**. Your task is to **recreate these designs in Flutter** using `material` (or `cupertino`) widgets, `ThemeData`, and idiomatic Dart patterns — using `tokens.json` and `strings.json` as the source of truth for values.

The HTML prototype is meant to be opened in a browser to *see and feel* the intended behavior — including animations, transitions, hover states, and the four color themes. Open `reference/FreeTalk (standalone).html` to view it offline.

## Fidelity

**High-fidelity (hi-fi).** Exact colors, typography, spacing, animation timing, and copy are all specified in `tokens.json`, `strings.json`, and `screens.md`. Implement pixel-perfect against these. If you find an ambiguity, the HTML prototype is the tie-breaker.

---

## What's in this package

| File | What it is |
|---|---|
| `README.md` | This file. Implementation overview + flutter conventions. |
| `tokens.json` | **Authoritative** design tokens — 4 color themes, type scale, spacing, radii, shadows, motion. Parse this into `ThemeData`. |
| `strings.json` | **Authoritative** i18n table — EN/ZH/KO. Keys are English source strings. Feed into `flutter_localizations` or `easy_localization`. |
| `screens.md` | Per-screen specs — layout, components, behavior, animations. |
| `components.md` | Reusable widget catalog — Avatar, ScoreRing, AnimatedBar, TalkingAvatar, etc. |
| `screenshots/` | PNG references for each screen (mobile + desktop). |
| `reference/` | The full HTML/React prototype source. Open `FreeTalk (standalone).html` to interact. |

---

## App overview

FreeTalk is an English-speaking practice app for teen/young-adult learners. The user picks a topic, has a voice conversation with an AI tutor character (Maya, Leo, Sofia, or Theo), and receives a scored report after the session. Three core differentiators:

1. **Live conversation** with a virtual tutor that lip-syncs while speaking (animated SVG face).
2. **Diverse scenarios** — Travel, Business, Daily life, Academic, Roleplay, Free chat — with a "Brief" intermediate screen that sets the scene before each conversation.
3. **Post-session report** — pronunciation / grammar / fluency / vocabulary scores, inline corrections, and "pocket phrases" to save.

Plus: **customizable learning course** (focus areas, conversation style, daily minutes, week-by-week plan), **progress tracking** (weekly minutes chart, skill breakdown, badges), **placement onboarding** (4-step), and **multilingual UI** (EN / 中文 / 한국어).

## Screen map / navigation graph

```
splash  ──tap──▶  home  ──┬──▶ scenarios  ──tap card──▶  brief  ──Start──▶ convo  ──End──▶ report
                          │                                                                  │
                          ├──▶ progress                                                       │
                          ├──▶ course                                                         │
                          └──▶ settings ◀──────────────────────────────────────────────────────┘
                                                  (Practice again → convo)
onboard (first-run, 4 steps) ──finish──▶ home
```

## Platforms

| Platform | Frame | Width | Notes |
|---|---|---|---|
| Android phone | portrait, status + nav bars visible | 412 dp design width | Tab bar at bottom (Home / Topics / Progress / You); hidden on convo + brief |
| Windows desktop | window 1120×720 logical | resizable | Left sidebar (220 dp) with Home / Scenarios / My course / Progress / Settings + "Quick talk" CTA |

Use Flutter's `LayoutBuilder` or `MediaQuery` to switch between mobile and desktop shells; the screen content widgets should accept an `isDesktop` flag (or use a `Layout.of(context)` inherited widget).

---

## Recommended Flutter architecture

```
lib/
├── main.dart                  # MaterialApp + theme switcher + router
├── theme/
│   ├── tokens.dart            # Loads tokens.json → typed constants
│   ├── app_theme.dart         # Builds ThemeData for each of 4 palettes
│   └── personas.dart          # Persona accent colors + names
├── l10n/
│   ├── app_en.arb
│   ├── app_zh.arb
│   └── app_ko.arb
├── state/
│   ├── settings_provider.dart # theme, persona, lang, difficulty, feedback (use Riverpod or Provider)
│   └── session_provider.dart  # current scenario, conversation turns, mode
├── widgets/
│   ├── avatar.dart            # Persona monogram
│   ├── talking_avatar.dart    # Animated SVG face (use flutter_svg or CustomPaint)
│   ├── score_ring.dart        # Circular progress + count-up
│   ├── animated_bar.dart      # 0→target bar
│   ├── primary_button.dart
│   ├── card.dart
│   ├── chip.dart
│   └── section_head.dart
└── screens/
    ├── splash.dart
    ├── onboard.dart
    ├── home.dart
    ├── scenarios.dart
    ├── scenario_brief.dart
    ├── conversation.dart
    ├── report.dart
    ├── progress.dart
    ├── course.dart
    └── settings.dart
```

### State management
- Recommended: **Riverpod** (or Provider). Settings (theme, persona, lang, difficulty, feedback) sit in a single provider. Session state (active scenario, current turn, mic mode) in another.
- The 4 color themes ship as 4 `ThemeData` instances; the chosen theme is the active `MaterialApp.theme`.

### Animations
All animations specified with duration + curve in `tokens.json` under `motion`. Use Flutter's `TweenAnimationBuilder`, `AnimationController`, or `flutter_animate` package. Key patterns:
- **Count-up numbers** → `TweenAnimationBuilder<int>` with `easeOutCubic` over 1200ms.
- **Bars growing** → animate `width` factor 0→1 with `easeOutCubic` over 1200ms.
- **Score ring** → `CustomPaint` with `AnimationController` driving a `tween` on the sweep arc, 1500ms.
- **Confetti on Report mount** → spawn 24–36 `Positioned` children with staggered translateY + rotate; use `flutter_confetti` package or roll your own with `Stack`.
- **Talking avatar lip-sync** → drive mouth scaleY with a 420ms looping curve while `mode == speaking`.

### i18n
- Convert `strings.json` to standard `.arb` files (one per language).
- Use `flutter gen-l10n` or `easy_localization`.
- Trigger CJK font fallback via `TextTheme` swap when language changes: load Noto Sans/Serif SC/KR via `google_fonts` package.

---

## Critical components (see `components.md` for full specs)

- **Avatar** — round monogram chip with persona gradient. Sizes 28/32/36/40/48/56.
- **TalkingAvatar** — large stylized SVG face that lip-syncs. Use `flutter_svg` to render path data from `reference/ui.jsx` (lines 77–280) or rewrite as `CustomPainter`.
- **ScoreRing** — circular progress with count-up center number + orbiting sparkles.
- **AnimatedBar** — linear progress that grows 0→target on mount.
- **Card** — `surface` background, 18-radius, subtle inset highlight + drop shadow.
- **Button** (primary / soft / outline / ghost) with accent glow on primary.
- **Chip** — pill, used for category filters + quick replies.

---

## Behavior notes

- **Splash** auto-shows on cold start; tap to advance to home. Show **once per session** (not on every nav).
- **Conversation screen** consumes microphone permission. Tap mic → record → on-device or backend STT → display user bubble → backend LLM reply → TTS playback → tutor bubble. Lip-sync only during TTS playback.
- **Report** mounts after `nav('report')`. Replay all entrance animations every visit.
- **Tweaks panel** is HTML-prototype-only (live design knobs); don't ship it.
- **Language change** must update **every visible string immediately** — no relaunch.

---

## Open questions for product

1. Real backend or mock-data MVP first?
2. STT/TTS provider? (Azure Cognitive, Google Cloud, OpenAI Whisper + ElevenLabs?)
3. Authentication: email/password, Google/Apple sign-in, or anonymous play?
4. Offline mode requirements?
5. Should the standalone Windows app run "windowed" only (1120×720 like the mock) or full-screen / resizable freely?

---

## Reference files

Open these to interact with the design before/while implementing:

- `reference/FreeTalk (standalone).html` — single-file working prototype, works offline.
- `reference/FreeTalk.html` — multi-file source (links to the .jsx files in the same folder).

The `.jsx` files contain the React source; useful for cross-referencing exact pixel values, but **do not transcribe React idioms into Flutter**. Use them as a spec, not as code.

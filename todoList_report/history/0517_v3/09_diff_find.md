# Report — 09 — App vs design_handoff_freetalk diff

Comparison between [`vLearn2Spec/design_handoff_freetalk`](../../vLearn2Spec/design_handoff_freetalk) (the source design) and the shipped Flutter app under [`flutter_app/lib/features/`](../../flutter_app/lib/features). Organised by screen, focused on *behavioural* and *structural* differences (animation gaps live in [08_animation_part.md](08_animation_part.md), not duplicated here).

## Splash (`screens.md §1`)

| Spec | App | Diff |
|------|-----|------|
| Date band "MONDAY · 13 MAY 2026" with hairline rules | absent | **Missing** |
| 84-dp monogram badge "F" italic, speech-dot blink | replaced with `Icons.school_rounded` | **Missing** |
| Wordmark "Free*Talk*" two-part italic | "vLearn2" until task 10, now "Virtual Foreign Language" | **Different wordmark** (intentional; brand renamed) |
| Slogan italic "Open your mouth. Find your voice." | absent | **Missing** |
| Pill CTA "Tap to begin →" | auto-navigates after auth resolves | **Different flow** — current app skips the user-tap step |
| Footer mono caption `v 1.0 · WIN · ANDROID · MADE FOR SPEAKERS-TO-BE` | absent | **Missing** |
| Full mount-time animation choreography | none | **Missing** (see [08_animation_part.md](08_animation_part.md)) |

## Onboarding (`screens.md §2`)

| Spec | App | Diff |
|------|-----|------|
| 4-step flow with progress dots top | exists but unclear if dot indicator matches | **Partial** |
| Step 1 "Hi! I'm FreeTalk" with pulsing avatar | static persona avatar | **Missing pulse** |
| Step 3 "Quick voice check" — display-face quote card + large pulsing mic, tap to record | not yet wired — STT models not installed by default | **Missing voice flow** (task 01 of v2 — Mode B; will light up when admin places sherpa models) |
| Step 4 placement result with ScoreRing 64 + 4 stat pills | computed placeholder values shown | **Partial** — needs real audio scoring |

## Home (`screens.md §3`)

| Spec | App | Diff |
|------|-----|------|
| Greeting row H1 "Hey Jamie. Talk to me?" italic accent | "Good morning, {displayName}" + sub | **Different wording** (current is simpler/i18n-aware) |
| Bell button | added in v2 task 03 (`BellIcon`) | ✅ |
| 40-dp avatar in AppBar | absent | **Missing** |
| Hero card gradient with primary CTA "Start talking" + ghost "Pick a topic" | not present — current home shows streak/XP instead | **Missing** — hero CTA is a key surface |
| Streak card with 7-day grid (4 filled, today border) | streak count + XP bar, no 7-day grid | **Partial** |
| "This week" card with 3 stat rows | "QuickStats" with sessions/minutes/topics | **Different layout** (mostly equivalent) |
| Recommended scenarios grid | `_ScenarioStrip` horizontal scroll | **Different shape** — horizontal vs 2/3-col grid |
| News strip on home | added in v2 task 03 (`NewsStrip`) | ✅ — not in original spec, user-requested addition |

## Scenarios (`screens.md §4`)

| Spec | App | Diff |
|------|-----|------|
| Search bar + category filter chips | search hint exists | **Partial** |
| 2-col / 3-col card grid with image, title, difficulty stars, est. time | likely a vertical list | **Different layout** |
| Difficulty as "★★★ · 5 min" stars + dot | not verified | — |

## Scenario detail (`screens.md §5`)

| Spec | App | Diff |
|------|-----|------|
| Hero image full-bleed | not implemented in shipped code | **Missing** |
| Scene description in display face | text body | **Partial** |
| Objectives checklist + key phrases | embedded in scenario model but display unverified | **Partial** |
| "Start" filled CTA | exists | ✅ |

## Conversation (`screens.md §6`)

| Spec | App | Diff |
|------|-----|------|
| `TalkingAvatar` hero element with mouth/eye state machine | code-driven placeholder; no Rive asset authored | **Missing** (Rive plumbing live; need `.riv` file) |
| Mic button with pulse while recording | mic button hidden when speech-not-ready; no pulse | **Partial** |
| Keyboard input fallback | works ✅ | ✅ |
| 5 bubble styles + picker | added in v2 task 04 — exceeds the spec | ✅ (extra) |
| Live transcription overlay during STT | not yet | **Missing** (gated on sherpa models) |
| "End" CTA → report | works ✅ | ✅ |

## Report (`screens.md §7`)

| Spec | App | Diff |
|------|-----|------|
| Confetti on mount | absent | **Missing** |
| Headline with italic gradient-shimmer | static text | **Missing** |
| Count-up stats line | static numbers | **Missing** (see [08_animation_part.md](08_animation_part.md)) |
| ScoreRing + 8 orbiting sparkles + radial burst | static ScoreRing | **Missing sparkle layer** |
| Floating CEFR stamp with rotate-and-wiggle | absent | **Missing** |
| Coach-note card with float-bob + sheen-sweep | absent | **Missing** |
| Corrections cards (4) with stagger + left accent bar growing | absent | **Missing** |
| Pocket phrases cards with hover-tilt | absent | **Missing** |
| Floating background shapes drifting throughout | absent | **Missing** |

## Progress (`screens.md §8`)

| Spec | App | Diff |
|------|-----|------|
| CEFR card with 6-stop progress bar | stub screen | **Missing** (per todoList_report/0516 — stub only) |
| Activity chart 7-bar `AnimatedNumber` | stub | **Missing** |
| 4 skill breakdown cards with `AnimatedBar` | stub | **Missing** |
| 6 circular badges (4 unlocked + 2 locked) | stub | **Missing** |

## Course (`screens.md §9`)

| Spec | App | Diff |
|------|-----|------|
| 3-step builder + plan preview | stub screen | **Missing entirely** |

## Settings (`screens.md §10`)

| Spec | App | Diff |
|------|-----|------|
| Language list at top with 36-dp monogram + native names | a bottom-sheet picker triggered from a "Language" tile | **Different placement** (works; less prominent) |
| Profile card with avatar + Edit button | shown | ✅ |
| Tutor carousel (`TalkingAvatar` with arrows + dots) | absent | **Missing** |
| Difficulty 3 segment cards | absent | **Missing** |
| Feedback 3 segment cards | absent | **Missing** |
| Theme 4 swatch buttons | a list-of-strings bottom-sheet | **Different presentation** |
| 4 preferences rows + sign-out red | exists, less polished | **Partial** |
| Font picker | added in v2 task 05 — exceeds the spec | ✅ (extra) |
| Bubble style picker | added in v2 task 04 — exceeds the spec | ✅ (extra) |
| Storage section (model bundle status) | added in v2 task 01 — exceeds the spec | ✅ (extra) |

## Overall

| Bucket | Count |
|--------|-------|
| Behavior matches spec | conversation, sign-in, settings basics, scenarios list+detail (data-flow level), report (data-flow level) |
| Visual/animation gap, no code change needed yet | splash, home hero, report sparkles/confetti, progress charts, course builder |
| Whole screens missing | course builder, progress screen detail |
| Exceeds spec | bubble styles, font groups, news, storage/speech-setup |

## Recommendation (priority order)

1. **Splash visual rework** — biggest first-impression delta. Implement per `screens.md §1` choreography (~150 LOC, no new deps).
2. **Home hero card** — design's primary CTA is missing today. ~50 LOC.
3. **Report sparkle + count-up layer** — psychological impact of seeing a score climb. Covered in [08_animation_part.md](08_animation_part.md).
4. **Course screen** — currently a stub. Real builder is ~300 LOC + persistence.
5. **Progress screen detail** — currently a stub. ~250 LOC.
6. **Tutor carousel + theme swatch settings** — design polish; current shortcuts work functionally.

None of these are blocking the app's behaviour. They're the difference between "works" and "feels like the design".

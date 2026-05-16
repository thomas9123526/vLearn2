# FreeTalk — Design Description

> A new-developer's tour of every screen and every control in the FreeTalk
> English-speaking app. Read this top-to-bottom and you'll know what each pixel
> does and roughly how it's built.

---

## 1. What is FreeTalk?

FreeTalk is an app that helps young-adult learners practice **spoken English**
by having short voice conversations with a virtual AI tutor. After each
session it scores their speech and gives corrections.

**Core ideas**

| Idea | How the design expresses it |
|---|---|
| Conversation, not flashcards | The product is a chat with a real-feeling character. No drills. |
| Pick a scene, then speak | Users choose a scenario (interview, café, first date…) so practice feels real. |
| Encouragement first | Confetti, count-ups, a coach's voice. Even mistakes are framed kindly. |
| One product, two devices | Same design renders responsively on Android phone and a Windows desktop window. |
| Multilingual UI | App chrome translates to EN / 中文 / 한국어. The *target* language is always English. |
| Tweakable identity | Theme (4 palettes) and tutor persona (4 characters) are live-switchable. |

**Visual DNA**

- Display type: **Instrument Serif** (italic for emphasis spans).
- UI type: **Plus Jakarta Sans** (with Noto Sans SC/KR for CJK).
- Mono (numbers, timestamps): **JetBrains Mono**.
- Color palettes named after natural-world warmth: **Apricot**, **Sage**,
  **Iris**, **Obsidian** (dark).
- Heavy use of soft radial glows, layered cards, and subtle animation —
  warmth + motion are part of the brand.

---

## 2. Navigation map

```
splash ─tap─▶ home ─┬─▶ scenarios ─tap card─▶ brief ─Start─▶ convo ─End─▶ report
                    ├─▶ progress                                            │
                    ├─▶ course                                              │
                    └─▶ settings ◀───────────────────────────────────────────┘
                                  (Practice again → convo)

onboard (4-step, first run) ─finish─▶ home
```

Mobile shell uses a **bottom tab bar** (Home / Topics / Progress / You);
hidden on convo, brief, splash, onboard.
Desktop shell uses a **220-dp left sidebar** with the same nav + a big "Quick
talk" CTA; hidden on convo, brief, splash, onboard.

---

## 3. Screen-by-screen tour

Below, every screen lists its controls in reading order. Each control has:

- **What it is** — purpose & visual.
- **How it behaves** — taps, hover, animation.
- **HTML sketch** — a representative React/HTML snippet. (The real project is
  React + inline styles; the snippets here are simplified for clarity.)

---

### 3.1 Splash — first screen

A celebratory landing slate that introduces the brand and lets the user begin.

**Background**
- Theme `bg` color filled full-bleed.
- Soft radial `glow` overlay (two radial gradients top-right + bottom-left).
- Accent-color wash centered on the wordmark.

**Floating glyphs** (8 of them: speech bubble, mic, mouth, globe, italic A,
star, wink, heart, cloud) — distributed around the edges. Each pops in
(`popIn`), then loops a 4–6s float bob. Colors pulled randomly from the four
persona accents.

```html
<div class="splash-glyph" style="left:10%;top:14%;width:64px;height:64px;
     animation: ft-splash-in .9s .0s forwards, ft-splash-bob 4s 1s infinite;">
  <svg viewBox="0 0 64 64">
    <path d="..." fill="#d97757" /> <!-- bubble -->
  </svg>
</div>
```

**Date band** — current date in `MONDAY · 14 MAY 2026` style, mono, with two
24-px hairline rules at each end.

**Monogram badge** — 84-dp accent square (radius 24), big italic "F" in serif,
with a small white "speech dot" notch at top-right that blinks every 1.6s.

```html
<div class="monogram">
  <span style="font-family:'Instrument Serif';font-style:italic;font-size:56px">F</span>
  <span class="blink-dot"></span>
</div>
```

**Wordmark** — `display1` size (108px on desktop, 72px on mobile). "Free" in
`ink`, *"Talk"* in italic accent. Fades + slides up on mount.

```html
<h1 class="wordmark">Free<em>Talk</em></h1>
```

**Slogan** — italic display, "Open your mouth. Find your voice."

**CTA button** — pill shape, `ink` bg, `bg`-color text. Trailing accent chip
holds the arrow. Hover lifts -1 px.

```html
<button class="splash-cta">
  Tap to begin
  <span class="arrow-chip">→</span>
</button>
```

**Footer caption** — bottom of screen, faint mono: `v 1.0 · WIN · ANDROID ·
MADE FOR SPEAKERS-TO-BE`.

---

### 3.2 Onboarding — placement test (first-run only)

A 4-step funnel that gauges the new user's level. Progress dots top-center
(active step is a 28-px pill; others are 14-px). Each step has a title,
sub-text, body, and Back / primary CTA at the bottom.

**Step 1 — "Hi! I'm FreeTalk."**
- Large pulsing persona Avatar (140 dp desktop, 110 mobile).
- Below: four persona names floating gently (3s float, .3s stagger).
- CTA: "Continue".

**Step 2 — "Why are you here?"**
- Four goal cards (Travel, Business, Academic, Just for fun). Each is a row
  with an icon-tile, title, sub. Tapping advances automatically.

```html
<button class="goal-card">
  <div class="icon-tile"><svg class="icon plane"/></div>
  <div>
    <div class="title">Travel &amp; make friends abroad</div>
    <div class="sub">Café orders, small talk, directions.</div>
  </div>
  <svg class="chevron"/>
</button>
```

**Step 3 — "Quick voice check"**
- A display-face quote card to read aloud.
- 88-dp pulsing mic button. Tap "records" (mock).

```html
<button class="big-mic">
  <span class="pulse-ring"></span>
  <svg class="icon mic" />
</button>
```

**Step 4 — "You're at B1 · Intermediate"**
- Animated `ScoreRing` (overall 64, sub "CEFR B1").
- Four stat pills: Fluency 72, Grammar 58, Vocabulary 66, Pronunciation 60.
- CTA: "Build my course" → goes to home.

**Footer nav** — Back / primary CTA, sticky at bottom.

---

### 3.3 Home — daily dashboard

Where users land every time after splash.

**Greeting row**
- Kicker date `Tuesday · evening` in caption color.
- H1 title in display face: *"Hey Jamie. Talk to me?"* — italic accent on
  the second half. (Translated in `t()` for ZH/KO.)
- Trailing bell icon button + 40-dp avatar.

```html
<div class="greeting">
  <div>
    <div class="kicker">Tuesday · evening</div>
    <h1>Hey Jamie. <em>Talk to me?</em></h1>
  </div>
  <button class="icon-button"><svg/></button>
  <img class="avatar" />
</div>
```

**Hero card — Today's session**
- Full-width accent-gradient card. Two semi-transparent white circles as
  decoration.
- Kicker: `TODAY'S SESSION · B1·B2`.
- Display H1: today's prompt — "Walk me through your morning routine."
- Sub-line: "~7 min · with {persona}".
- Two buttons:
  - **Start talking** — white-on-accent (`soft` variant), leading mic icon. Goes to brief.
  - **Pick a topic** — ghost outline white border. Goes to scenarios.
- On desktop, a 96-dp pulsing avatar of the active persona on the right.

```html
<div class="hero-card">
  <div class="kicker">Today's session · B1·B2</div>
  <div class="title">Walk me through your morning routine.</div>
  <div class="sub">~7 min · with Maya</div>
  <button class="btn-soft"><svg class="mic"/> Start talking</button>
  <button class="btn-ghost">Pick a topic</button>
</div>
```

**Streak card** (left, 1.4fr on desktop)
- Kicker: "STREAK".
- Big serif "12 days in a row", flame icon.
- 7-day grid (M/T/W/T/F/S/S). Filled days have a check, today has a 2-px
  accent border.

**This-week stats card** (right)
- 3 rows: Speak time `1h 42m`, Words spoken `4,238`, New phrases `+27`.
- Numbers in mono.

**Recommended section**
- Section header: kicker `RECOMMENDED`, display H2 "Pick where you left off",
  trailing ghost button "All scenarios →".
- Grid (2-col mobile, 3-col desktop) of 4–6 scenario cards. Each card has an
  icon-tile, title, blurb, footer with `~{mins} min`.

```html
<button class="scenario-card">
  <div class="row">
    <div class="icon-tile"><svg class="airplane"/></div>
    <div class="tag">A2</div>
  </div>
  <div class="title">Airport check-in</div>
  <div class="blurb">Find your gate, handle a flight delay.</div>
  <div class="time">~7 min</div>
</button>
```

---

### 3.4 Scenarios — topic picker

A searchable, filterable library of scenarios.

**Title row** — H1 *"What do you want to **practice**?"* + sub "Pick a
scenario or just start talking — your tutor will improvise."

**Search input** — 12-radius pill, leading search icon.

```html
<div class="search">
  <svg class="search-icon"/>
  <input placeholder="Search scenarios…" />
</div>
```

**Category chips** — horizontal scroll row of 7 pill chips (All / Travel /
Business / Daily life / Academic / Roleplay / Free chat). Active chip is
accent-filled. Filter is purely client-side.

```html
<div class="chip-row">
  <button class="chip is-active"><svg/> All</button>
  <button class="chip"><svg/> Travel</button>
  …
</div>
```

**Scenario grid** — same scenario card as Home but laid out 1-col (mobile) or
3-col (desktop). Staggered fade-in (40 ms apart).

---

### 3.5 Brief — scenario detail

An intermediate page between picking a topic and starting the conversation,
to set the scene. (This page is one of the user's favorite changes.)

**Header**
- Back arrow.
- Breadcrumb chip: `BRIEF · {category name}` in mono.

**Hero card** (split: illustration on left, headline on right on desktop)
- Illustration: category-specific SVG composition (e.g. Travel = plane +
  suitcase + clouds).
- Top-left floating chips: CEFR tag (`A2`) + duration (`~7 min`).
- Kicker `SCENE`, large title, scene description (e.g. "Terminal 3 · 06:42 ·
  long line at Skyhigh Airways").
- Difficulty line: colored pill (`B1+ · Stretching`) + "vibe: *polite urgency*".

```html
<div class="hero">
  <div class="illustration">
    <svg viewBox="0 0 320 180">...</svg>
  </div>
  <div class="body">
    <div class="kicker">Scene</div>
    <h1>Airport check-in</h1>
    <p class="scene">Terminal 3 · 06:42 · long line at Skyhigh Airways.</p>
    <div class="meta-pill"><span class="dot"/>Stretching · vibe: <i>polite urgency</i></div>
  </div>
</div>
```

**Roles row** — two cards side-by-side:
- "You play" — describes your character.
- "{Persona} plays" — describes their character.

**Twist banner** — dashed accent border, "?!" badge, one-line surprise
complication.

```html
<div class="twist">
  <div class="badge">?!</div>
  <div>
    <div class="kicker">The twist</div>
    <div>Your bag is 2.4 kg over and your gate just changed.</div>
  </div>
</div>
```

**Objectives & Phrases** (2-col on desktop)
- **What to aim for** — 3 numbered objectives.
- **Phrases worth stealing** — 3 italic pull-quote cards.

**Persona pairing card** — small avatar + name + role + "Change" link → goes
to Settings.

**Sticky bottom dock**
- "Back to topics" outline button.
- "Start speaking" filled CTA with leading mic + `{mins}m` mono suffix.

```html
<div class="dock">
  <button class="btn-outline">Back to topics</button>
  <button class="btn-primary"><svg class="mic"/>Start speaking <span class="mono">7m</span></button>
</div>
```

---

### 3.6 Conversation — live chat

The heart of the app. Designed to feel like a friendly messaging app.

**Header** (sticky top)
- Back button (← icon).
- 42-dp PersonaChip — round colored chip with persona initials + a green
  online-dot at the bottom-right.
- Persona name (bold) + "✦ AI Tutor · Online" sub-line.
- Right side: voice-call icon button + ⋯ menu button (which navigates to the
  report).

```html
<header class="convo-header">
  <button class="back"><svg/></button>
  <div class="persona-chip"><span>EM</span><span class="online-dot"/></div>
  <div>
    <div class="name">Emma</div>
    <div class="sub"><svg class="star"/> AI Tutor · Online</div>
  </div>
  <button class="icon"><svg class="phone"/></button>
  <button class="icon"><svg class="kebab"/></button>
</header>
```

**Transcript** (scrollable middle)

- **Date pill** centered (`Today, 10:24 AM`) — surfaceAlt pill.
- **Tutor message** — white surface bubble, 22-radius, hairline border.
  Underneath the bubble: 28-dp PersonaChip + timestamp.
- **User message** — solid accent-color bubble (white text), 22-radius, right-aligned.
  Underneath: timestamp + double-check icon (read receipt).
- **Voice message** — an inset card with a play button + 22-bar waveform +
  duration in mono.

```html
<!-- tutor bubble -->
<div class="msg-tutor">
  <div class="bubble">That sounds wonderful! Where did you go hiking?</div>
  <div class="meta">
    <span class="persona-chip-sm">EM</span>
    <span class="time">10:25 AM</span>
  </div>
</div>

<!-- voice message -->
<div class="msg-tutor">
  <div class="voice-bubble">
    <button class="play"><svg/></button>
    <div class="wave">
      <i style="height:8px"/><i style="height:14px"/>…
    </div>
    <span class="dur">0:08</span>
  </div>
</div>

<!-- user bubble -->
<div class="msg-me">
  <div class="bubble">We went to Mount Tamalpais. The view was amazing!</div>
  <div class="meta">
    <span class="time">10:26 AM</span>
    <svg class="double-check"/>
  </div>
</div>
```

- **Tip card** — appears under a user bubble that has a correction. Cream/
  warn-tinted background with a bulb icon, "Tip from {Persona}", and the
  suggestion. *Example*: "Try: 'The view was breathtaking!' — more natural."

```html
<div class="tip">
  <div class="head"><svg class="bulb"/> Tip from Emma</div>
  <div class="body">Try: <em>"The view was breathtaking!"</em> — more natural</div>
</div>
```

- **Typing indicator** — 28-dp chip + 3 bouncing dots in a small bubble.

**Quick-reply chips** (row above input, horizontal scroll) — surface pills
the user can tap to send canned replies. First chip has a sparkle icon and
says "✨ Suggest reply"; others are scenario-aware ("It was sunny", "About
3 hours").

**Input bar** (sticky bottom)
- Round attach button (`+` icon).
- Pill input field "Type a message..." with a trailing emoji icon.
- Round filled accent mic button (with accent-glow shadow).

```html
<div class="input-bar">
  <button class="circle"><svg class="plus"/></button>
  <div class="text-pill">
    <input placeholder="Type a message..." />
    <button class="emoji"><svg/></button>
  </div>
  <button class="circle accent"><svg class="mic"/></button>
</div>
```

**Behavior** — tapping the mic advances the mock turn pipeline:
`idle → thinking (1.4s) → idle` with the next message inserted. After all
turns, mic acts as End → goes to Report.

---

### 3.7 Report — post-conversation evaluation

The most animation-heavy screen. Everything counts up / pops in on mount.

**Mount choreography** (in order, ms from open)

| t (ms) | What |
|---|---|
| 0    | Confetti burst (24–36 pieces falling from top) |
| 0    | Floating decorative shapes drift in (4 of them, abstract) |
| 0    | Header fades in |
| 100  | Headline ("Nice talk. *You're getting there.*") fades in; italic span has continuous gradient-shimmer |
| 200  | Stats sub-line: "7 min · {142 ↺} words · {20 ↺} wpm · with Maya" begins counting up |
| 300  | Score-hero card mounts |
| 200  | Score ring begins filling (1.5 s tween) + count-up to 76 |
| 400+ | 4 score bars grow + count up, 180 ms staggered |
| 900  | CEFR stamp springs in top-right of hero, then wiggles every 4 s |
| 1600 | "+6 this week" pill stamps in below ring |
| 2100 | Hand-drawn checkmark stroke draws inside the pill |
| 2400 | Coach note card slides up, sheen sweeps |
| 2600 | Correction cards stagger in with growing left accent bar |
| 3200 | Pocket-phrase cards stagger in |
| 3800 | CTAs slide up |

**Header**
- Back arrow (→ home).
- Kicker `SESSION REPORT`.
- Share pill button (outline).

**Headline + meta**
```html
<h1 class="report-h1">
  Nice talk. <em class="shimmer">You're getting there.</em>
</h1>
<p class="meta">
  7 min · <span class="mono">142</span> words · <span class="mono">20</span> wpm · with Maya
</p>
```

**Score hero card**
- Floating CEFR rank stamp (e.g. `B1+`), tilted -8°, springs in then wiggles.
- Animated score ring on left, 8 orbiting sparkles, radial burst behind.
- "+6 this week" badge stamps in below ring with a checkmark.
- Four animated score bars on right: Pronunciation 78 / Grammar 71 / Fluency 84 / Vocabulary 69.

```html
<div class="score-hero">
  <div class="cefr-stamp">CEFR<br/>B1+</div>
  <div class="ring-wrap">
    <svg class="ring"> ... </svg>
    <div class="value">76</div>
    <div class="delta">✓ +6 this week</div>
  </div>
  <div class="bars">
    <Bar label="pronunciation" value="78"/>
    <Bar label="grammar"       value="71"/>
    <Bar label="fluency"       value="84"/>
    <Bar label="vocabulary"    value="69"/>
  </div>
</div>
```

**Coach note** — surfaceAlt card with the persona's avatar, a speech-bubble
tail, a moving sheen, and an italic display quote. Header has a pulsing
"live" dot.

**Corrections list** — 4 cards. Each has:
- A growing left accent bar (warn for grammar, bad for pronunciation).
- A small icon tile.
- The wrong sentence (struck through) → wiggling arrow → the right sentence
  in accent color.
- A note explaining why.
- A small play-it button on the right.

```html
<div class="correction-card">
  <div class="left-bar warn"></div>
  <div class="icon"><svg/></div>
  <div class="body">
    <div>
      <s>I go to hiking on weekends.</s>
      <svg class="arrow wiggle"/>
      <strong>I go hiking on weekends.</strong>
    </div>
    <div class="note">No "to" after "go" + activity-ing.</div>
  </div>
  <button class="play-mini"><svg/></button>
</div>
```

**New phrases** — 3 cards in a row (desktop) or column (mobile). Each card
has an italic display "phrase", an example sentence in italic, and a `+`
button that rotates 90° on hover (saves to vocabulary).

**Bottom CTAs**
- Outline "Done" — goes home.
- Filled "Practice again" — slowly floats; goes to a new convo.

---

### 3.8 Progress — charts + badges

Long-term stats and motivation page. All numbers/bars animate from 0 → target
on mount.

**Header** — H1 *"Your **progress**"* + sub "7 weeks in. Up and to the right."

**CEFR card**
- 64-dp accent square with serif "B1" white.
- Kicker `CURRENT LEVEL`.
- Display sub "Intermediate · climbing toward B2".
- 6-stop A1–C2 horizontal bar fills 0 → 64 % on mount.

**Weekly activity chart**
- Kicker `MINUTES SPOKEN`, display H1 with `AnimatedNumber 316 min` + `· last
  7 weeks`. Delta `+28%` in green.
- 7 vertical bars (W1–W7), each grows from 0 to its target with 80 ms
  stagger. Last bar is the accent color; others are accentSoft. Above the
  last bar: count-up label.

```html
<div class="chart">
  <div class="bar" style="height:0%; animation: ft-bar-grow 1.2s ease-out forwards"></div>
  …
</div>
```

**Skill breakdown** — 2-col on desktop. Four cards (Fluency / Grammar /
Vocabulary / Pronunciation). Each has the score count-up + animated bar +
weekly delta in green.

**Badges**
- Section heading + 6-col grid (3 on mobile) of round badges.
- Unlocked badges are filled accent; locked are surfaceAlt at 45 % opacity
  with a "Locked" caption.

```html
<div class="badge unlocked">
  <div class="icon"><svg class="flame"/></div>
  <div class="label">7-day Streak</div>
</div>
<div class="badge locked">
  <div class="icon"><svg class="grad"/></div>
  <div class="label">Debate Champ</div>
  <div class="sub">Locked</div>
</div>
```

---

### 3.9 Course — learning path builder

A 3-step setup wizard with a preview at the bottom.

**Header** — H1 *"Build your **course**"* + sub "Tell us how you live and
we'll script lessons around it."

**Section 01 — "What should we drill?"**
6 category tiles, multi-select. Tapping toggles inclusion (accent border +
accentSoft fill when active).

```html
<button class="course-tile is-active">
  <div class="icon-circle"><svg class="plane"/></div>
  <div class="label">Travel</div>
</button>
```

**Section 02 — "What kind of conversations?"**
3 single-select cards: Realistic / Clean / Playful. Right side has a radio
indicator that fills accent when active.

**Section 03 — "How much time per day?"**
- Big serif count "15 min" + sub "~1.8 hrs / week" (recomputed live).
- Native range slider, 5 → 45 step 5, themed via `accentColor`.

```html
<input type="range" min="5" max="45" step="5" value="15"
       style="accent-color:#d4633a"/>
```

**Your plan / Next 4 weeks** — vertical timeline.
- 1-dp vertical guide line, 4 circular numbered badges on the left.
- Each row is a card: week kicker + title + "5 sessions" in mono.

**Footer CTA** — large filled "Save my course" with trailing arrow.

---

### 3.10 Settings

The most varied page. Combines profile + identity + preferences.

**Language list (very first thing on the page)**
- Kicker `APP LANGUAGE`.
- Vertical list card with 3 rows: EN, 中文, 한국어. Each row has a 36-dp accent
  monogram, the native script in display face, the romanization in mono, and
  a circular radio indicator on the right. Active row is tinted accentSoft.

```html
<div class="lang-list">
  <button class="lang-row is-active">
    <div class="flag-chip">EN</div>
    <div>
      <div class="native">English</div>
      <div class="latin">English</div>
    </div>
    <div class="radio is-active"><svg class="check"/></div>
  </button>
  <!-- 中 row, 한 row -->
</div>
```

**Page H1** — "Settings".

**Profile card**
- 56-dp circular avatar (monogram).
- Name + sub line ("jamie@freetalk.app · B1 · Intermediate").
- "Edit" outline button on the right.

**Tutor / Choose your speaking partner — linear carousel**
The hero control of this page. Replaces the previous 4-up grid.

- 44-dp left arrow button (round, hairline border).
- Center stage: a 96-dp framed `TalkingAvatar` (the animated face), then on
  the right the name in display face, the role, and a small "✓ Selected"
  accent pill.
- 44-dp right arrow button.
- Below: dot indicator (4 dots; active expands to a 22-px pill).
- The arrows + dots cycle through Maya, Leo, Sofia, Theo.

```html
<div class="persona-carousel">
  <button class="arrow"><svg/></button>
  <div class="stage">
    <div class="face"><TalkingAvatar persona="leo" /></div>
    <div>
      <div class="name">Leo</div>
      <div class="role">Cool mentor</div>
      <div class="badge accent">✓ Selected</div>
    </div>
  </div>
  <button class="arrow flip"><svg/></button>
  <div class="dots">
    <button class="dot"/>
    <button class="dot is-active"/>
    <button class="dot"/>
    <button class="dot"/>
  </div>
</div>
```

**Difficulty** — 3 segment cards (Beginner / Intermediate / Advanced) with
CEFR sub.

**Feedback** — 3 segment cards (Gentle / Balanced / Strict) with tagline.

**Theme** — 4 swatch buttons; each shows the theme's bg fill + two
mini-swatches (accent + surfaceAlt) + name label.

```html
<button class="theme-swatch" style="background:#faf6ef">
  <div class="swatches">
    <i style="background:#d4633a"/>
    <i style="background:#f2eada"/>
  </div>
  <div class="name">Apricot</div>
</button>
```

**Preferences list card** — 4 rows: Daily reminder (`7:00 PM`), Voice
playback speed (`1.0×`), Microphone (`System default`), Sign out (in `bad`
color, no trailing arrow). Each row has a tiny icon-tile on the left, label,
mono value on the right, and a chevron.

---

## 4. Shared components catalog

Brief refresher on the reusable widgets you'll see across screens.

| Component | Purpose | Notes |
|---|---|---|
| **Avatar** | Persona monogram chip. | Sizes 28–56. Optional pulse + outer ring. |
| **TalkingAvatar** | Big animated SVG face. | Lip-syncs while speaking, blinks idly, tilts when listening. |
| **ScoreRing** | Circular progress. | Has an animated variant with sparkles + count-up. |
| **AnimatedBar / Bar** | Linear progress 0 → target. | Optional shimmer sweep. |
| **AnimatedNumber** | Count-up text. | Used in stats. |
| **Card** | Surface container. | 18-radius, hairline border, inset highlight + drop shadow. |
| **Button** | 4 variants: primary / soft / outline / ghost. | Press = scale .97. Primary has accent glow. |
| **Chip** | Pill button. | Active swaps to accent fill. |
| **SectionHead** | Section title group. | Small kicker + display H2 + trailing action. |
| **PersonaChip** | Solid-color round chip with online dot. | Used in chat header. |
| **VoiceBubble** | Voice-message bubble. | Play + 22-bar waveform + duration. |
| **TipCard** | Coach correction. | warn-tinted, bulb icon. |
| **DoubleCheck** | Read-receipt icon. | After user-message timestamps. |
| **ConfettiBurst** | Mount-on-screen confetti. | 24–36 pieces, randomized. |
| **Waveform** | N bars looping scaleY. | Inside the active mic button. |
| **Tabs / Sidebar** | Top-level nav. | Mobile bottom 4-tab; desktop 5-item sidebar. |

---

## 5. Theme system

Four palettes, all using the same token names — swapping theme just swaps the
palette object. See `tokens.json` in the handoff package for exact hex values.

| Theme | Mood | Best for |
|---|---|---|
| **Apricot** (default) | Mediterranean villa, golden hour. Warm parchment + terracotta. | Friendly default. |
| **Sage** | Eucalyptus + dusty rose. Quiet, editorial. | Calm focus. |
| **Iris** | Cool ivory + periwinkle + warm amber. Refined. | Academic / professional vibe. |
| **Obsidian** | Deep navy + electric teal + warm amber. | Dark mode. |

Each persona also has its own accent color that stays the same across themes
(so Leo is always blue, Sofia always violet), giving each tutor a stable
identity even when the app's chrome changes.

---

## 6. Motion system

All animations live in tokens (curves + durations) so they feel coherent.

| Pattern | Use | Duration |
|---|---|---|
| Fade-in / slide-up | Entering content | 420 ms |
| Pop-in (spring) | Important elements (badges, avatars) | 500 ms |
| Count-up | Numbers | 1200 ms ease-out |
| Bar grow | Progress bars | 900–1200 ms |
| Score-ring fill | Score ring | 1500 ms |
| Pulse (loop) | Mic + persona | 1800 ms |
| Confetti fall | Report mount | 2400–4000 ms |
| Shimmer | Headline italic + bar tops | 2400 ms loop |

---

## 7. i18n

All user-facing strings flow through `t('English source string')`. Missing
translations fall back to English so the UI never breaks. The active language
is reactive — switching language in Settings updates *every* visible string
instantly. CJK fonts auto-swap via `<html lang>` so type metrics stay
correct.

---

## 8. What to build first

If you're implementing this in Flutter (or anywhere), this is a good order:

1. **Theme** — set up the 4 palettes as ThemeData and wire the picker.
2. **Avatar + TalkingAvatar + ScoreRing + AnimatedBar** — these primitives
   appear everywhere.
3. **Home + Splash** — establishes the visual language.
4. **Conversation** — the product's killer screen.
5. **Report** — the second killer screen. Lots of animation choreography.
6. **Scenarios + Brief** — content-heavy but mostly layout.
7. **Progress + Course + Settings** — supporting screens.
8. **Onboarding** — last; needs hooks into placement scoring.

You're now oriented! See the handoff package's `screens.md` and
`components.md` for line-by-line specs, and the HTML prototype for the live
interactive reference.

# Screens — Detailed Specs

Each screen has the same shape: **mobile (412 dp portrait)** and **desktop (1120×720)**. The desktop layout adds a 220-dp sidebar; otherwise the screen content is identical, with looser padding and larger type at the `isDesktop` breakpoint.

All values reference tokens in `tokens.json`. When a number is given inline, it's a literal pixel/dp value.

---

## 1. Splash — first screen

**Layout**
- Full-bleed `bg`, soft radial `glow` overlay.
- 8 playful SVG glyphs floating around the edges (bubble, mic, mouth, globe, italic-A, star, wink, heart, cloud) — each pops in with `popIn` then loops a 4–6s `float` bob. Color is randomly one of the 4 persona accents.
- Centerpiece, vertically centered:
  - Date band (`overline` mono, `inkFaint`) — `MONDAY · 13 MAY 2026` style, with two 24-px hairline rules at the ends.
  - 84-dp rounded-square monogram badge — accent bg, italic "F" in display face, white. A small white "speech dot" notch top-right with a 1.6s blink animation.
  - Wordmark `display1`: **Free** in `ink`, *Talk* in italic accent (uses `ft-serif` class — auto-swaps to Noto Serif SC/KR for CJK).
  - Slogan `bodyLg` italic display: "Open your mouth. Find your voice."
  - Pill button (`ink` bg, `bg` text): "Tap to begin →" with right circular accent chip.
  - Footer mono caption: `v 1.0 · WIN · ANDROID · MADE FOR SPEAKERS-TO-BE`.

**Behavior** — Tap "Tap to begin" → navigate to `home`. Splash shows once per cold start; subsequent navigations skip it.

**Animation choreography** (on mount)
- 0ms: glow + glyphs fade in
- 60ms: monogram pops in
- 100ms: wordmark fades + slides up
- 300ms: slogan slides up
- 450ms: CTA slides up
- 700ms: footer fades in

---

## 2. Onboarding — placement test (first-run)

4-step flow with progress dots at top. Steps:

1. **Hi! I'm FreeTalk** — large pulsing persona avatar, persona names floating below.
2. **Why are you here?** — 4 goal cards (Travel, Business, Academic, Just for fun) with icon + title + sub. Auto-advances on selection.
3. **Quick voice check** — display-face quote card + large pulsing mic button. Tap to "record".
4. **You're at B1 · Intermediate** — `ScoreRing` shows 64 with sub `CEFR B1` + 4 mini stat pills (Fluency/Grammar/Vocabulary/Pronunciation with values).

Each step has: title (`display3`/`display4`), sub (`bodyLg`), body content, Back + primary CTA at bottom. Fade-in keyed by step index so each step replays its entry on swap.

---

## 3. Home — daily dashboard

- **Greeting row**: kicker date in `caption` + H1 *"Hey Jamie. Talk to me?"* (display, italic accent on "Talk to me?") + bell button + 40-dp avatar.
- **Hero card** (gradient accent → `accent`+cc): overline (CEFR), display H1 prompt, sub "~7 min · with {persona}", primary white CTA "Start talking" + ghost outline "Pick a topic". Decoration: two semi-transparent white circles.
- **Streak card** (1.4fr on desktop): "Streak" kicker, big serif "12 days in a row", flame icon, 7-day grid (4 filled, today highlighted with 2-dp accent border).
- **This week card**: 3 stat rows — Speak time `1h 42m`, Words spoken `4,238`, New phrases `+27`. All numbers in `mono`.
- **Recommended section**: 4 (mobile, 2-col) / 6 (desktop, 3-col) scenario cards.

---

## 4. Scenarios — topic picker

- H1 "What do you want to **practice**?" + sub.
- Search input with leading search icon, 12-radius surface.
- Horizontal scroll row of category chips: All / Travel / Business / Daily life / Academic / Roleplay / Free chat.
- Filtered grid (1-col mobile, 3-col desktop) of scenario cards:
  - 44-dp `accentSoft`-bg icon tile (left)
  - title (`body` weight 600) + tag (`mono`) on right
  - blurb (`bodySm` `inkSoft`)
  - footer: `~{mins} min` + → arrow

Tap card → `brief` screen (with the scenario in nav state).

---

## 5. Brief — scenario detail

Intermediate screen between picking a topic and starting the conversation. Sets the scene.

- **Header**: back arrow + breadcrumb `BRIEF · {category}` in mono.
- **Hero card** (split layout):
  - Left: category-specific SVG illustration (Travel = plane + suitcase, Biz = laptop + chart, Daily = cups + window, School = lectern + books, Roleplay = comedy/tragedy masks, Free = speech bubbles).
  - Right: kicker "SCENE", H1 title, scene description, CEFR pill + duration pill, "vibe: {tone}" line.
- **Roles** (2-col on desktop, stacked on mobile): "You play" + "{Persona} plays" cards.
- **Twist banner** — dashed accent border, "?!" badge, surprise complication.
- **Objectives** (numbered 1-2-3) + **Phrases worth stealing** (italic display in pull-quote cards) side by side.
- **Persona pairing** card with Change button → settings.
- **Sticky bottom dock**: outline "Back to topics" + filled "Start speaking ({mins}m)" CTA.

5 scenarios have hand-written briefs (Airport check-in, First date, Job interview, Order at café, Negotiate a raise); the rest use a generic template.

---

## 6. Conversation — live chat

**Header**
- Back arrow + 42-dp PersonaChip (round monogram + green online dot at -1, -1).
- {Persona name} (body 16 weight 700) + "AI Tutor · Online" sub with star icon.
- Voice-call icon button + ⋯ menu (goes to report).

**Transcript** (scrollable)
- Date pill `Today, 10:24 AM` centered in surfaceAlt pill.
- Each message:
  - **Tutor (left)**: white surface bubble, 22-radius, hairline border. Below: 28-dp PersonaChip + timestamp.
  - **Me (right)**: solid `accent`-bg bubble (white text), 22-radius. Below: timestamp + double-check icon.
  - **Voice bubble** (optional): inset card with play button + 22-bar SVG waveform + duration.
  - **Tip card** (optional): warn-tinted card with bulb icon, "Tip from {persona}", correction text.
- Typing indicator: 28-dp chip + 3 bouncing dots in a chat bubble.

**Quick-reply chips** (horizontal scroll, just above input): "✨ Suggest reply", "It was sunny", "About 3 hours" — chip pills, surface bg.

**Input bar** (sticky bottom)
- 38-dp + (attach) icon
- 44-dp pill input: "Type a message..." + emoji icon right
- 44-dp filled mic button (accent bg, white icon, accent glow shadow)

**Behavior** — Tap mic → "thinking" state (typing dots) → next turn appears. After 4 turns, mic → report.

---

## 7. Report — post-conversation evaluation

The most animation-heavy screen.

**On mount, in sequence:**
1. Confetti burst (24–36 pieces, falling) at top.
2. Header fades in.
3. Headline `display2`: "Nice talk. *You're getting there.*" — italic part has a continuous gradient-shimmer sweep.
4. Stats sub-line: "7 min · {count-up 142} words · {count-up 20} wpm · with {persona}".
5. Score hero card:
   - Floating CEFR stamp top-right (rotates 8°, springs in at 900ms, then wiggles every 4s).
   - `ScoreRing` (160 dp) — count-up + ring fill + 8 orbiting sparkles + radial burst behind.
   - Bottom-centered "+6 this week" pill (springs in at 1.6s with hand-drawn checkmark stroke at 2.1s).
   - 4 `AnimatedBar`s right side — pronunciation/grammar/fluency/vocabulary; bars grow + numbers count up, staggered 180ms.
6. **Coach note card** (`surfaceAlt` bg) — float-bobs gently, has speech-bubble tail, sheen sweeping across. Italic display quote.
7. **Corrections** — 4 cards stagger in with left accent bar (warn/bad) growing top→bottom, popping icon, wiggling arrow, fade-in fix text.
8. **Pocket phrases** — 3 cards (italic display name + example), tilt slightly + glow on hover. Plus button rotates 90° on hover.
9. **CTAs** — outline "Done" + filled "Practice again" (float-bobs gently).

Floating background shapes (4 of them, accent-tinted circles + diamonds + rounded squares) drift slowly throughout.

---

## 8. Progress — charts + badges

- **CEFR card**: 64-dp accent square with white "B1" serif, "Current level" overline, sub "Intermediate · climbing toward B2", 6-stop A1–C2 progress bar (animates 0→64% on mount).
- **Activity chart**: "Minutes spoken" kicker, H1 with `AnimatedNumber` 316, "+28%" delta in `good`. 7 vertical bars (W1–W7) grow from 0 with stagger, last bar in `accent` with count-up label above it.
- **Skill breakdown** (2-col on desktop, 1-col on mobile): 4 cards — Fluency 72 +8, Grammar 58 +3, Vocabulary 66 +5, Pronunciation 60 +6. Each has count-up number + `AnimatedBar`.
- **Badges**: 6 circular badges (3-col mobile, 6-col desktop). 4 unlocked at accent bg, 2 locked at surfaceAlt with `Locked` label.

---

## 9. Course — learning path builder

3-step builder (numbered kickers 01/02/03) + plan preview.

- **01 What should we drill?** — 6 category tiles (multi-select, toggle).
- **02 What kind of conversations?** — 3 single-select cards (Realistic / Clean / Playful) with radio checkbox right.
- **03 How much time per day?** — large serif `{minutes}min` + "~{hrs}/week" + native range slider 5→45 step 5. Tick labels below.
- **Your plan / Next 4 weeks** — vertical timeline with circular numbered badges + week cards (kicker, title, "5 sessions").
- "Save my course" lg CTA centered.

---

## 10. Settings

- **Language list** (very first thing, vertical):
  - 3 rows in a single card, each with: 36-dp accent monogram (EN / 中 / 한), native name in display face + romanization in `mono`, radio-circle right. Active row tinted `accentSoft`.
- **Page H1** "Settings".
- **Profile card**: avatar + name + email + Edit button.
- **Tutor / Choose your speaking partner** — **linear carousel**:
  - 44-dp left arrow button (round, surface, hairlines).
  - Center stage: 96-dp framed `TalkingAvatar` + name (display) + role + "✓ Selected" accent pill.
  - 44-dp right arrow button.
  - Dot indicator below (4 dots, active expands to 22-dp pill).
- **Difficulty** — 3 segment cards (Beginner/Intermediate/Advanced + CEFR sub).
- **Feedback** — 3 segment cards (Gentle/Balanced/Strict + tagline).
- **Theme** — 4 swatch buttons; each shows the theme's bg color + 2 swatches (accent + surfaceAlt) + name.
- **Preferences list** card — 4 rows (Daily reminder / Voice playback speed / Microphone / Sign out). Sign-out row in `bad` color.

---

## Responsive rules

- **Padding**: mobile `20 18 32`, desktop `32 48 48`.
- **Max-width**: desktop content capped at 760–940 dp depending on screen.
- **Grid columns**: scenarios 1 (mobile) / 3 (desktop). Skills 1 / 2. Course focus 2 / 3. Personas 4 (desktop) / 2 (mobile, except settings carousel which is single-card).
- **Type**: see `tokens.json` — display3 (desktop) vs display4 (mobile) for page titles.

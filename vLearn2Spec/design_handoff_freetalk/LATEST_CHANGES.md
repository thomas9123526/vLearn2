# Latest design changes (since initial handoff)

This file lists everything that's been added or changed in the design after
the initial `screens.md` and `components.md` were written. Treat these as
authoritative — when they conflict with the earlier docs, this wins.

The full live prototype reflects all of these — open
`reference/FreeTalk (standalone).html` to interact.

---

## 1. New screens

### Sign in (`signin`)
Login screen. Three fields:
- **User ID** — text, with **sync button** (32-dp icon-only round) on right
  that fetches the ID from a REST endpoint (currently mocked with a 900 ms
  delay returning `1029384756`). Loading state shows a spinning ring; success
  state shows a green check on a green-tinted pill.
- **Name** — text, also with sync button
- **Password** — with show/hide toggle
- "Remember me" checkbox + "Forgot password?" link
- Primary CTA: "Sign in"
- "OR" divider
- Link: "Create an account →" navigates to `signup`

Desktop has a 420-dp left brand panel with the wordmark, slogan, faded
breathing persona portrait, and platform footer. Mobile shows only the form
with a small logo at top.

### Sign up (`signup`)
Registration. Fields:
- **User ID** (login identifier) — with sync button
- **Name** (real name, e.g. "Jamie Chen")
- **User number (10 digits)** — numeric-only input, with sync button + live
  digit counter, validates `^\d{10}$`
- **Password** + **Confirm password** with a live 4-segment strength meter
  (Weak / Fair / Good / Strong / Excellent) colored from `bad` → `good`
- **Gender** — required, two-option segmented (**Female** / **Male**)
- **Terms** checkbox — required
- "Step 1 of 2" indicator + 2-segment progress bar

On submit, persists into navState and forwards to `onboard` starting at step
1 (skip the welcome step).

---

## 2. Splash screen additions

- Two corner ID hints, dashed-border mono pills with a slight backdrop blur:
  - Bottom-left: `ㄱ123456789`
  - Bottom-right: `ㄱ987654321`
- CTA now routes to `signup` (not `home`)

---

## 3. Home screen changes

- The bell icon at top-right now opens a **Notifications dialog** (modal):
  - List view of 4 news items, each with: badge (New / Update / Tip /
    Community), title, 2-line preview, time, chevron
  - Tap an item → detail view: large serif title, formatted body, "Back to
    news" button. Header has back arrow + "News" title + timestamp.
  - Backdrop tap / × closes
  - **Unread red dot** with pulsing ring sits on the bell icon
- A **Sign out** button (38-dp round, icon only) sits next to the bell. Hover
  tints red. Click navigates to `signin`.
- A **"Continue your course"** card sits below the hero card and above the
  Streak/stats grid:
  - Book icon tile (left, accent-tinted)
  - Course kicker + "Continue your course" label
  - Slim progress bar (currently at 42%)
  - "Week 2 · 3/7" position label in mono
  - Tap → navigates to `course`

---

## 4. Conversation screen — mode toggle

The conversation screen now has **two modes**, toggled via a segmented
control in the header (chat icon ⇄ face icon).

### Chat mode (existing)
Voice-recognition chat with bubble transcript, voice messages, tip cards,
quick-reply chips, input bar with attach/text/emoji/mic.
*Removed:* the phone-call icon previously in the header.

### Face-to-face mode (new) — `convoMode === 'face'`
Feels like a video call.
- **Top-left scene pill** with pulsing recording-style dot + scenario title
- **Top-right session timer** in mono (e.g. `02:14`)
- **Stage** — fills remaining space, never resizes. Persona-tinted radial
  gradient background that shifts color by mode (idle / listening /
  speaking). 4 drifting ambient orbs in background.
- **Large `TalkingAvatar`** (280–380 dp) centered. Breathes idle. Lip-syncs
  speaking. Head bobs gently while speaking, tilts while listening. Glow halo
  pulses during speech. A small **WaveHand** floats next to them when idle.
- **Mode badge ribbon** (bottom-left of stage) — changes color and label per
  state: "Live call" / "Listening…" / "{Persona} is speaking" / "Thinking…"
- **Recent transcript** — fixed-height area (132 dp), 2 fixed 56-dp slots:
  - Top slot: last tutor message (white bubble, left-aligned)
  - Bottom slot: last user message (accent bubble, right-aligned)
  - When a new turn arrives, the new bubble **slides up** into its slot via
    `ft-slide-up`. Long messages clamp to 2 lines.
- **Press-and-hold record button** (new component: `PressToRecord`):
  - 84-dp accent button when idle, 96-dp red while held
  - Hold: grows, concentric pulse rings, accent halo. Floating dark overlay
    panel appears above with: red REC dot · 18-bar live waveform · mm:ss.x
    timer
  - Release: animation disappears, next turn inserts (only commits if held
    ≥300 ms)
  - Status label: `HOLD TO SPEAK` → `RELEASE TO SEND`
  - Flanked by a small End-call (red phone-rotated) button and a Mute button

Both modes share the same conversation state — switching mid-session
preserves everything.

---

## 5. Settings screen — Edit Profile dialog (new)

Tapping the **Edit** button on the profile card opens a modal:
- Avatar preview (initial from Name, accent bg) + "Change photo" button
- **Name** input
- **Level** dropdown (A1–C2 with descriptors)
- Divider, then **Change password** section:
  - "Leave blank to keep your current password." helper text
  - **Current password**
  - **New password** (placeholder: "Min 6 characters")
  - **Confirm new password**
  - "Show passwords" checkbox toggles visibility on all three at once
- Footer: Cancel / Save changes
- Validation: password change is optional but if any field is filled, all
  three are required + new must be ≥6 chars + confirm must match
- *Removed*: the previous Email field

---

## 6. Settings screen — Tutor carousel & language list

- **Tutor carousel** — replaces the previous 4-up grid. Linear left-arrow ·
  large `TalkingAvatar` + name + role + "✓ Selected" pill · right-arrow,
  with a dot indicator below.
- **Language list** — vertical 3-row card at the very top of Settings
  (above the page H1). Each row has a 36-dp accent monogram (EN / 中 / 한),
  native name in display face, romanization in mono, circular radio on the
  right. Active row tinted `accentSoft`.

---

## 7. Progress screen — Skill radar chart

Replaces the 4-up skill bars grid. New component: **`SkillRadarCard`**.

- 5 axes: Fluency · Grammar · Vocabulary · Pronunciation · Listening
- Pentagon radar with 4 grid rings (25/50/75/100%), gray spokes, accent-
  tinted filled polygon, dots at each vertex, mono value labels per axis,
  gray center dot
- Right side: "ATTRIBUTES" panel with 5 skill rows (label · animated bar ·
  mono number)
- Bottom card: "Overall rating" (animated count) + active profile label +
  weekly deltas
- **Profile selector** at top — 5 pill buttons (Now / Last month / Goal /
  CEFR B1 avg / CEFR B2 goal). Tapping re-animates the radar polygon and
  bars in 700 ms ease-out tween between value sets.

---

## 8. Progress screen — Minutes spoken redesign

Major expansion:
- **Time-range toggle** in header (7w / 30d / All)
- **4 summary stat cards** above the chart:
  - Avg / day (6.4 min, +0.9)
  - Best day (14 min, Sat)
  - Sessions (42, +8)
  - Day streak (12d, 🔥)
  All count up on mount.
- **Goal dotted line** at 50 min across the chart with "Goal 50" label
- **Bar style change** — bars are now narrow vertical strokes (10 dp wide,
  fully rounded pill shape) in the theme's red `bad` color with an outer
  glow. Current week (W7) is fully opaque + larger glow; others use 85%
  opacity. Each bar has its minute count above it (count-up). Week dataset
  now also carries a `sess` (sessions count) field per week.
- **Time-of-day breakdown** — 4-segment proportional stacked bar:
  Morning 18% / Midday 22% / Evening 46% (highlighted accent) / Night 14%
  + "You speak most in the **evening**" insight line

---

## 9. Mobile bottom-tab nav

Confirmed at **4 tabs** (not 5): Home · Topics · Progress · You.
Course access is via the "Continue your course" card on Home (not the
mobile tab bar). The desktop sidebar still has 5 items including My course.

---

## 10. Tutor personas

Despite a request to reduce to 2, the system still ships **4 personas**
(Maya, Leo, Sofia, Theo) because they're referenced by the Settings
carousel + onboarding. If you want to ship with 2 in production, just gate
the persona list in `theme.jsx` (`PERSONAS`) to two and the carousel and
selector will adapt.

---

## File-level summary of new source

```
reference/
├── auth.jsx              — Sign in + Sign up screens
├── face-mode.jsx         — Face-to-face conversation mode + PressToRecord
├── splash.jsx            — Splash (now includes ID hints, routes to signup)
├── screens.jsx           — Home (notifications + sign-out + course card),
│                          Scenarios, Conversation (with mode toggle)
└── screens2.jsx          — Report, Progress (with radar + redesigned chart),
                            Course, Settings (with edit-profile dialog)
```

Read the source files for the canonical implementation; this changelog
provides the conceptual overview.

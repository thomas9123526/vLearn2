# 05 – Flutter Screens Implementation

All screens support mobile (412 dp) and desktop (1120×720) layouts.
Colors reference `tokens.json` palettes. Strings reference `strings.json` keys.

---

## Screen 01: Splash (`/splash`)

**File:** `lib/features/auth/screens/splash_screen.dart`

### Layout
- Full-screen gradient background (theme primary → secondary)
- Centered wordmark: "FreeTalk" (Instrument Serif, 48sp)
- Tagline: "Practice English. Feel the flow." (Plus Jakarta Sans, 16sp)
- Floating animated icons: 🎤 📚 💬 🌟 (slow float + gentle rotation)
- Bottom band: current date + language pill
- "Tap to begin" CTA fades in after 1.5s

### Behavior
- [ ] **05.1.1** Check auth state on init:
  - Has valid token → navigate to `/home`
  - No token → show splash, tap → `/signin`
  - First launch → show splash, tap → `/signup`
- [ ] **05.1.2** Floating icon animation: `AnimationController` loop, staggered offsets
- [ ] **05.1.3** Fade-in for CTA after 1.5s delay

---

## Screen 02: Sign In (`/signin`)

**File:** `lib/features/auth/screens/signin_screen.dart`

### Layout
- Top: Back arrow + "FreeTalk" logo
- Hero: Instrument Serif "Welcome back"
- Email + Password fields (Plus Jakarta Sans)
- "Sign In" primary button
- "Forgot password?" text link (placeholder)
- Divider + "Don't have an account? Sign up" link

### Behavior
- [ ] **05.2.1** Form validation: email format, password not empty
- [ ] **05.2.2** Show inline error messages below fields (red, smaller font)
- [ ] **05.2.3** Loading state on button during API call
- [ ] **05.2.4** On success: navigate to `/home` (or `/onboarding` if first time)
- [ ] **05.2.5** Shake animation on form if error returned

---

## Screen 03: Sign Up (`/signup`)

**File:** `lib/features/auth/screens/signup_screen.dart`

### Layout
- Top: Back arrow
- Hero: "Create your account"
- Display Name, Email, Password, Confirm Password fields
- Password strength meter (4 segments: weak → strong)
- "Sign Up" primary button
- "Already have an account? Sign in" link

### Behavior
- [ ] **05.3.1** Real-time password strength calculation (length + uppercase + digit + special)
- [ ] **05.3.2** Password match validation on confirm field blur
- [ ] **05.3.3** All fields validated before submit
- [ ] **05.3.4** On success: navigate to `/onboarding`

---

## Screen 04: Onboarding / Placement Test (`/onboarding`)

**File:** `lib/features/auth/screens/onboarding_screen.dart`

### Layout
- Step 1: Native language selection (horizontal scroll chips: 🇺🇸 English, 🇰🇷 Korean, 🇨🇳 Chinese, + others)
- Step 2: English level self-assessment (6 cards: A1 Beginner → C2 Master, with short description)
- Step 3: Goal selection (cards: Casual conversation, Business English, Travel, Academic)
- Step 4: Persona selection carousel (Maya, Leo, Sofia, Theo)
- Progress dots at top
- "Continue" / "Get Started" buttons

### Behavior
- [ ] **05.4.1** Stepper with animated slide transitions between steps
- [ ] **05.4.2** Persona cards: tappable, show name + specialty badges, accent color ring on selected
- [ ] **05.4.3** On complete: `PATCH /users/profile` + `onboarding_done = true`, navigate to `/home`
- [ ] **05.4.4** Skip button on step 1 (defaults to English)

---

## Screen 05: Home (`/home`)

**File:** `lib/features/home/screens/home_screen.dart`

### Layout (Mobile)
- Header: "Good morning, {name}" + avatar chip + notification bell icon
- Streak banner: "🔥 {n} day streak"
- XP progress bar (current level progress)
- **Continue your course** card (if enrolled):
  - Course name, completion %, "Continue" button
- **Quick stats row**: Sessions this week · Minutes spoken · Scenarios done
- **Recommended scenarios** horizontal scroll (3-4 cards)
- **Recent activity** list (last 3 sessions)

### Layout (Desktop)
- Left: sidebar nav
- Main: 2-column grid (stats left, recommended right)
- Wider cards

### Behavior
- [ ] **05.5.1** `homeDataProvider` fetches `/users/profile` on mount
- [ ] **05.5.2** Notification bell opens `NotificationDialog` (modal bottom sheet / dialog)
  - NotificationDialog shows: achievement earned, streak reminder, new scenarios
- [ ] **05.5.3** Avatar tap → navigate to `/settings`
- [ ] **05.5.4** "Start a conversation" FAB → navigate to `/scenarios`
- [ ] **05.5.5** Animated XP bar fill on first load
- [ ] **05.5.6** Pull-to-refresh on mobile
- [ ] **05.5.7** Sign out button (top-right menu or settings) → call `/auth/signout`, clear cache

---

## Screen 06: Scenarios Browser (`/scenarios`)

**File:** `lib/features/scenarios/screens/scenarios_screen.dart`

### Layout
- Search bar at top
- Category filter chips: All · Travel · Business · Social · Daily Life
- Difficulty filter: A1 A2 B1 B2 C1 C2 (compact toggle)
- Scenario cards grid (2-col mobile, 3-col desktop):
  - Scene emoji, title, difficulty badge, duration, XP reward
  - Completion checkmark if done, best score badge

### Behavior
- [ ] **05.6.1** Filter state managed locally with `StateProvider`
- [ ] **05.6.2** `scenariosProvider(category, difficulty)` fetches from API with filters
- [ ] **05.6.3** Loading: shimmer skeleton cards
- [ ] **05.6.4** Tap card → navigate to `/scenarios/:id/brief`
- [ ] **05.6.5** Search: local filter on cached scenario list

---

## Screen 07: Scenario Brief (`/scenarios/:id/brief`)

**File:** `lib/features/scenarios/screens/brief_screen.dart`

### Layout
- Hero image area: gradient + emoji scene (large)
- Scene title + description (Instrument Serif headline)
- **Your role** card (user_role)
- **Tutor's role** card (tutor_role)
- **Objectives** list (checkmark icons)
- **Key phrases** expandable section
- Bottom bar: "Start Conversation" button + XP badge + est. duration

### Behavior
- [ ] **05.7.1** Load scenario from `scenariosProvider(id)`
- [ ] **05.7.2** Localize all text content (title, description, roles, objectives)
- [ ] **05.7.3** "Start Conversation" → call `POST /conversations/sessions`, navigate to `/conversation/:sessionId`
- [ ] **05.7.4** Show active persona avatar in hero corner

---

## Screen 08: Conversation — Chat Mode (`/conversation/:sessionId`)

**File:** `lib/features/conversation/screens/conversation_screen.dart`

### Layout
- Header: persona name + PersonaChip + mode toggle (Chat ↔ Face icon) + ✕ close
- Message list: scrollable, auto-scrolls to bottom
  - User bubbles: right-aligned, theme primary color
  - Tutor bubbles: left-aligned, surface color + persona accent left border
  - Timestamp (optional, shown on tap)
- Bottom area:
  - Text input field + send button
  - Waveform/mic placeholder (disabled, future STT)
  - "Press to speak" placeholder button (disabled)

### Behavior
- [ ] **05.8.1** `ConversationNotifier` manages session state
- [ ] **05.8.2** Send message: disable input, show typing indicator (animated dots), enable on response
- [ ] **05.8.3** Typing indicator: 3 dots animation (scale + opacity loop)
- [ ] **05.8.4** Auto-scroll to latest message
- [ ] **05.8.5** Mode toggle → switch to Face-to-Face mode (keep session alive)
- [ ] **05.8.6** ✕ close: confirm dialog ("End conversation?") → `POST .../end` → navigate to `/report/:id`
- [ ] **05.8.7** Tutor avatar state: `idle` normally, `thinking` when waiting for response

---

## Screen 09: Conversation — Face-to-Face Mode

**File:** `lib/features/conversation/screens/face_mode_screen.dart`

### Layout
- Full-screen dark background
- **Stage area** (top 60%):
  - Rive animated tutor character (centered, large)
  - Subtle spotlight glow effect
  - Live caption subtitle at bottom of stage area
- **Controls area** (bottom 40%):
  - Waveform visualizer (placeholder)
  - Large circular "Press to Speak" button (themed color)
  - "Release to send" label when pressed
  - Small text input toggle (switch to text mode)
  - Mode toggle back to Chat

### Behavior
- [ ] **05.9.1** Rive animation state machine controls: `idle → listening → thinking → speaking`
- [ ] **05.9.2** Press-to-speak button: UI only (STT placeholder), on release send last typed text
- [ ] **05.9.3** TTS placeholder: simulate tutor speaking with Rive `speaking` state for 2s per response
- [ ] **05.9.4** Live caption: display tutor's last message as subtitle
- [ ] **05.9.5** Haptic feedback on button press/release
- [ ] **05.9.6** Transition animation from chat mode (slide up)

---

## Screen 10: Report (`/report/:sessionId`)

**File:** `lib/features/report/screens/report_screen.dart`

### Layout
- Header: "Great job!" / "Nice work!" (random encouragement) + ConfettiBurst animation on load
- **Score ring**: large circular, overall score (0-100)
- **Score breakdown** (4 animated bars):
  - Fluency · Vocabulary · Grammar · Engagement
  - Each shows icon + label + animated fill bar + number
- **XP earned** section: "+{n} XP" animated count-up
- **AI Feedback** paragraph (from Claude)
- **Strengths** list (green icons)
- **Areas to improve** list (amber icons)
- Bottom: "Try again" + "Back to Scenarios" buttons

### Behavior
- [ ] **05.10.1** Fetch report from `GET /conversations/sessions/:id/report`
- [ ] **05.10.2** ConfettiBurst on mount (if score > 60)
- [ ] **05.10.3** `ScoreRing` animates from 0 to final score
- [ ] **05.10.4** Each `AnimatedBar` fills from 0 with staggered 200ms delay
- [ ] **05.10.5** `AnimatedNumber` counts up XP earned
- [ ] **05.10.6** Share button (text summary to clipboard)

---

## Screen 11: Progress (`/progress`)

**File:** `lib/features/progress/screens/progress_screen.dart`

### Layout
- **Level badge** section: current level label (A1-C2), XP progress bar
- **Stats grid** (2×2):
  - Total sessions · Minutes spoken
  - Words spoken · Scenarios done
- **Streak section**: fire icon + "{n} days" large number + longest streak
- **Minutes Spoken** chart: weekly bar chart (last 8 weeks)
- **Skill Radar** chart: pentagon/hexagon spider chart
  - Axes: Pronunciation · Fluency · Vocabulary · Grammar · Listening
- **Achievements** section: horizontal scroll of earned badge chips

### Behavior
- [ ] **05.11.1** `progressProvider` fetches `GET /progress`
- [ ] **05.11.2** Skill radar: `fl_chart` RadarChart with animation
- [ ] **05.11.3** Weekly bar chart: `fl_chart` BarChart, last 8 weeks
- [ ] **05.11.4** Stats numbers: `AnimatedNumber` widget
- [ ] **05.11.5** Achievement chips: tap to show full description in bottom sheet

---

## Screen 12: Course (`/course`)

**File:** `lib/features/course/screens/course_screen.dart`

### Layout
- Course header: title + description + level badge + completion %
- Scenario list (ordered):
  - Scenario card with completion status (checkmark, current arrow, locked lock)
  - Score badge on completed scenarios
- "Continue Course" sticky bottom button

### Behavior
- [ ] **05.12.1** Fetch from `GET /courses/:id` (use first recommended course)
- [ ] **05.12.2** Locked scenarios: show lock icon (scenarios above user level)
- [ ] **05.12.3** Current scenario: highlighted with arrow icon
- [ ] **05.12.4** "Continue" → navigate to current scenario's brief

---

## Screen 13: Settings (`/settings`)

**File:** `lib/features/settings/screens/settings_screen.dart`

### Layout (sections)
1. **Profile** section: avatar chip + display name + email + "Edit profile" button
2. **Tutor** section: horizontal persona carousel (Maya, Leo, Sofia, Theo cards with name, accent color)
3. **App Language** section: language list (English, 한국어, 中文) with radio
4. **Theme** section: 4 color swatches (Apricot, Sage, Iris, Obsidian) with label
5. **Learning** section: Daily goal (5/10/15/20 min selector)
6. **About** section: version, terms, privacy links
7. **Sign Out** destructive button at bottom

### Behavior
- [ ] **05.13.1** "Edit profile" → `EditProfileDialog` (bottom sheet):
  - Edit display name + avatar emoji picker + native language
  - Save → `PATCH /users/profile`
- [ ] **05.13.2** Persona tap → update active persona (`PATCH /users/settings`), persona card highlights
- [ ] **05.13.3** Language change → update `localeProvider`, restart intl, save to SQLite + API
- [ ] **05.13.4** Theme change → update `themeProvider`, apply immediately, save to SQLite + API
- [ ] **05.13.5** Sign out: confirmation dialog → clear SQLite auth cache → navigate to `/signin`

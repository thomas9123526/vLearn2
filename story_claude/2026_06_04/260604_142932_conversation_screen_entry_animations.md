# Conversation - Conversation screen entry animations

| Field | Value |
|---|---|
| Saved | 2026-06-04 14:29:32 |
| Commit | Add entry animations to conversation screen: skeleton, bubble stagger, tutor fade |
| Project | C:\project\vLearn2 |

---

## User

animate all in the appropriate ways but user must feel that ui is not stuck by showing some animations so user is waiting or know some actions is going.

## Assistant

Added animations across the conversation screen so the UI always feels alive:

### 1. Session loading → pulsing skeleton (`_SkeletonLoading`)
Replaced the bare `CircularProgressIndicator` with a chat-bubble-shaped skeleton — 5 alternating left/right placeholder blocks that pulse opacity (0.35→0.85) on a 1.1s loop. Gives the user a preview of the layout while `getSession()` is fetching.

### 2. Loading → content: `AnimatedSwitcher` fade (350ms)
Wrapped `Scaffold.body` in `AnimatedSwitcher`. When the session data arrives, content fades in over 350ms rather than snapping in.

### 3. Chat bubbles: staggered slide-up + fade (`_AnimatedBubble`)
Each bubble wraps in `_AnimatedBubble` — a stateful widget with a one-shot 320ms `FadeTransition` + `SlideTransition` (offset 0→0.15 upward). On fresh session entry (Turn 0, 1 opening message), it slides in smoothly. For resumed sessions, all pre-existing messages are pre-marked as "seen" via `_seenCount` and appear instantly. New mid-conversation replies also animate in individually.

### 4. TutorModeView entry fade (450ms)
Added `_entryCtrl` / `_entryFade` to `_TutorModeViewState`. The entire tutor screen fades in on mount, hiding the avatar's jump from invisible to visible.

### 5. Status pill: `AnimatedContainer` + `AnimatedSwitcher`
- Pill background color transitions smoothly (250ms) using `AnimatedContainer`
- Label text and leading icon each wrapped in `AnimatedSwitcher` (200ms) so "Tap the mic" → "Speaking…" → "Listening…" transitions cross-fade rather than snap

---

## Prompt

animate all in the appropriate ways but user must feel that ui is not stuck by showing some animations so user is waiting or know some actions is going.

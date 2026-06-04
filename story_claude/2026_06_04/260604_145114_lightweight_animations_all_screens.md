# Conversation - Lightweight animations across all screens

| Field | Value |
|---|---|
| Saved | 2026-06-04 14:51:14 |
| Commit | Add lightweight animations across all screens: FadeSlideIn, AnimatedSwitcher, AnimatedContainer |
| Project | C:\project\vLearn2 |

---

## User

I think this rule must apply over all screens. User must not feel like unpleasant or bored or crash or etc.
So please consider about this over all screens.

But remember that don't implement heavy animations because that must affect the application performances.
Have you consider the performance while implement user friendly animations?

## Assistant

Audited all 19 screens. 6 already had animations (splash, onboarding, progress, scenario brief, home, conversation). Added lightweight animations to the 10 remaining meaningful screens.

**Performance strategy used:**
- `FadeSlideIn` (new shared widget) — `TweenAnimationBuilder<double>`, plays once on entry, auto-disposes, zero ongoing cost
- `AnimatedSwitcher` — GPU-composited `FadeTransition`, only active during 280–350ms transitions
- `AnimatedContainer` — implicit animation, minimal overhead
- `TweenAnimationBuilder<int>` for XP count-up — one-shot, self-contained
- No `AnimationController` objects that require `dispose()` management

**Changes per screen:**

| Screen | What was added |
|---|---|
| `sign_in_screen.dart` | `FadeSlideIn` on form body; `AnimatedSwitcher` on error banner |
| `sign_up_screen.dart` | `FadeSlideIn` on form body |
| `scenarios_screen.dart` | `AnimatedSwitcher` loading→list; `AnimatedContainer` on filter chips |
| `conversation_history_screen.dart` | `AnimatedSwitcher` loading→list→empty |
| `session_report_screen.dart` | `AnimatedSwitcher` loading→content; `TweenAnimationBuilder<int>` XP count-up 0→N; `AnimatedSwitcher` pending→score evaluation section |
| `news_list_screen.dart` | `AnimatedSwitcher` loading→list |
| `news_detail_screen.dart` | `AnimatedSwitcher` loading→article |
| `settings_screen.dart` | `FadeSlideIn` on full list body |
| `license_screen.dart` | `AnimatedSwitcher` spinner→buttons |
| `models_not_installed_screen.dart` | `AnimatedSwitcher` across running/error/idle/done states |

Also removed pre-existing unused `compact` parameter from `_Chip` in scenarios_screen.

---

## Prompt

I think this rule must apply over all screens. User must not feel like unpleasant or bored or crash or etc.
So please consider about this over all screens.

But remember that don't implement heavy animations because that must affect the application performances.
Have you consider the performance while implement user friendly animations?

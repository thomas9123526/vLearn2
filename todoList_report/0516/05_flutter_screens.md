# Report — 05_flutter_screens

**Spec:** [todoList/0516/05_flutter_screens.md](../../todoList/0516/05_flutter_screens.md)
**Date:** 2026-05-16
**Status:** ⚠️ Partial — core 4 screens complete (Home, Scenarios, Conversation, Session report). Progress/Course/Profile-edit remain as enhanced stubs.

## What was done — 4 real screens (the core user loop)

### Home — [features/home/home_screen.dart](../../flutter_app/lib/features/home/home_screen.dart)

- Pull-to-refresh that invalidates scenarios + progress + refreshes profile
- Time-of-day greeting with user's display name
- **Streak + XP banner** (gradient using current theme): fire emoji, day count, XP total, animated progress bar to next level
- **Quick stats row**: sessions / minutes / topics (from `GET /progress`)
- **Recommended scenarios** horizontal strip with category chips, title (i18n-aware via `forLocale`), minute estimate, XP reward — tapping any card routes to the scenarios screen
- Skeleton loader for the scenarios strip; error tile for failed loads

### Scenarios list — [features/scenarios/scenarios_screen.dart](../../flutter_app/lib/features/scenarios/scenarios_screen.dart)

- Search field that pipes a debounced `q` to the backend
- Two horizontal filter rows:
  - 5 category chips (All / Travel / Business / Social / Daily) — tap-to-toggle
  - 6 CEFR difficulty chips (A1–C2) — tap-to-toggle, compact size
- `FutureProvider.family<List<Scenario>, _Filters>` re-fetches on filter change
- Tile per scenario: level badge, title, description, minute + XP row
- **Start session flow**: resolves the user's `active_persona_id` (falls back to the first persona) → calls `POST /conversations/sessions` → navigates to `/conversation/:sessionId`
- Empty state + loading spinner + error message

### Conversation — [features/conversation/conversation_screen.dart](../../flutter_app/lib/features/conversation/conversation_screen.dart)

- Loads session + full message history via `GET /conversations/sessions/:id`
- Chat bubbles styled per role (primary-filled for user; surface-variant for assistant) with asymmetric corner radii
- `TextField` with send button (also enter-to-send via `TextInputAction.send`); button shows a spinner while in-flight
- Sends via `POST /conversations/sessions/:id/messages` then invalidates the provider; auto-scrolls to bottom in a post-frame callback
- AppBar shows current turn count
- "End" action calls `POST /conversations/sessions/:id/end` and pushes the report screen (using `pushReplacement` so back doesn't return to a dead session)
- Disabled state while sending/ending; snackbar on errors

### Session report — [features/report/session_report_screen.dart](../../flutter_app/lib/features/report/session_report_screen.dart)

- Loads via the same `GET /conversations/sessions/:id`
- Large gradient XP ring showing earned XP
- "Great work!" headline + summary line ("You spoke N words across M turns")
- **Skill-scores section** — currently displays "—" for each skill with a banner noting AI-driven scoring lands with §09
- Two CTAs: "Back to home" (replaces) and "Practice another scenario"
- Close-X in AppBar that returns to home

## Stubs that §05 leaves in place

| Stub | Reason for deferring |
|------|---------------------|
| **Progress dashboard** — radar chart + weekly bar chart + achievement strip + skill snapshots | Needs the §09 AI scoring outputs to mean anything; today's DB has zeros for non-engagement skills. fl_chart radar + bar charts arrive in a focused §05 follow-up |
| **Course detail** — ordered scenario list with completion state | Trivially wired but low-priority for v1; users can browse scenarios directly. Stub renders the course slug |
| **Profile edit** — display name / avatar / persona swap | The settings screen already covers theme + language + sign-out; the explicit "Edit profile" detail screen is post-MVP polish |
| **Face Mode** (conversation `mode='face'`) | Designed around STT/TTS which is still placeholder (§09). UX assumes mic input; building it before that lands would be premature |

These stay as `StubScreen` widgets so the router stays compilable and the planned URLs are reachable. The user-facing flow `signin → home → scenarios → conversation → report → home` is **fully working**.

## Honest call-outs

1. **No offline cache writes yet.** Scenarios fetched from the API aren't being mirrored to the Drift `ScenariosCache` table the §02 schema declared. The cache layer arrives when a screen actually needs offline support — for v1 the network requirement is fine since the app needs a backend connection for conversations anyway. The Drift table is in place, ready for a future repository layer.

2. **Refresh after `sendMessage` re-fetches the whole session.** Cheap enough for v1 (session messages cap at 50 turns), but a streaming/append pattern would be nicer at scale. Easy follow-up: `_sessionProvider` becomes a `StateNotifier` that mutates locally on send.

3. **No optimistic UI on send.** User message appears only after the round-trip completes. Snappy enough on localhost; could feel laggy on a slow connection. Future work: optimistic insert + reconcile.

4. **Time-of-day greeting uses local device clock.** No timezone awareness, no per-user "active hours" customization. Good enough.

5. **Scenario start always uses chat mode**, even though `StartSessionDto.mode` accepts `'face'`. Face Mode entry deferred until §09 lands STT/TTS.

6. **No analytics events**. The plan in §05 §5.x mentions sending analytics on key actions (session_start, message_sent, session_end) — no analytics SDK is wired. Add when a real provider is picked.

7. **Search debounce is implicit (TextField.onChanged + rebuild)**, not via a proper `Timer`. For 20 scenarios this is fine; if the list grows, add a 300 ms debounce.

## Verification

```bash
cd flutter_app && flutter analyze
# → No issues found!

# End-to-end smoke (requires backend running with seeds):
flutter run -d windows
# Sign-in → Home shows greeting + streak + recommended scenarios
# Tap a scenario card → Scenarios screen
# Filter to "Travel" → list narrows
# Tap a tile → Conversation screen opens with the tutor's greeting
# Type a message → assistant reply appears (placeholder until §09)
# Tap "End" → Session report shows earned XP
```

## What's next

§06 — shared widgets that the screens above lean on (chip styles, cards, score-ring component, badge component, persona avatar). Some of these were inlined into the screens for §05; they'll be hoisted into `shared/widgets/` in §06 with consistent styling.

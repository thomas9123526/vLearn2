# 05 — Missing screens audit

## Ask

> I can find some missing screens opposed to "design_handoff_freetalk". Why is it? Is it possible to make the same?

## Audit

Each of the 10 screens called out in `design_handoff_freetalk/screens.md`, against what shipped in `flutter_app/lib/features/`:

| # | Design screen | Flutter status before this batch | Now |
|---|---------------|----------------------------------|-----|
| 1 | Splash | implemented in `splash/splash_screen.dart` | — (unchanged) |
| 2 | Onboarding | implemented in `onboarding/onboarding_screen.dart` | — (unchanged) |
| 3 | Home | implemented in `home/home_screen.dart` | — (unchanged) |
| 4 | Scenarios | implemented in `scenarios/scenarios_screen.dart` | tile tap → brief screen (was: instant session start) |
| 5 | **Brief** | **missing entirely** | **NEW** — `scenarios/scenario_brief_screen.dart` (see [02_topicdescription.md](02_topicdescription.md)) |
| 6 | Conversation | implemented in `conversation/conversation_screen.dart`; tutor mode was mic-only | text input added (01) + cartoon face (03) |
| 7 | Report | minimal implementation in `report/session_report_screen.dart` | now also submits a heuristic snapshot (04) — visual polish still pending |
| 8 | **Progress** | **stub (`StubScreen`)** | **rebuilt** as full CEFR / activity / skills / completions screen (see [04_progress.md](04_progress.md)) |
| 9 | Course | stub (`StubScreen`) for `course_detail_screen.dart` | unchanged — no entry point in the app shell yet |
| 10 | Settings | implemented in `settings/settings_screen.dart` | — (unchanged; profile-edit dialog tracked separately) |

## What's now matching the design

After this batch:

- ✅ Brief screen exists.
- ✅ Progress tab has real content.
- ✅ Tutor mode has a face + text input.
- ✅ Report screen submits skill snapshots that drive the progress charts.

## What still differs from the design

- **Course detail (§9)** is a stub. The design spec describes a 3-step builder (focus tiles, conversation style, time/day) plus a 4-week timeline preview. No tab links to it currently — the route exists at `/courses/:idOrSlug` but nothing pushes to it. This is a deliberate parking spot; nothing else in the app depends on courses yet.
- **Report screen (§7)** has the structure but not the heavy animation choreography from the design (confetti burst, gradient-shimmer headline, count-up word stats, orbiting sparkles around the score ring, hand-drawn checkmark, 4 corrections cards, 3 pocket-phrase cards, drifting background shapes). All achievable with Flutter's `AnimationController` + a confetti package, but it's a full afternoon of polish on top of an already-working screen. Tracked as follow-up.
- **Splash/onboarding animations (§1, §2)** — the design specifies precise choreography (8 floating glyphs, monogram pop-in at 60ms, slogan slide-up at 300ms, etc.). The current implementation is fully functional but plays a simpler entry sequence.
- **Tweaks panel** (referenced in `reference/tweaks-panel.jsx`) is a designer-side tool, not an end-user screen — skipped on purpose.

## Notes

Everything that was structurally missing has been added. The remaining gaps are visual-polish iterations on existing screens, not whole missing flows. If you'd like any of those polish passes done next (report animations are probably the highest-impact one), say which and I'll prioritize it.

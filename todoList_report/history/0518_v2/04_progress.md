# 04 — Progress tab content + backend snapshot upload

## Ask

> Progress tab have no content, why is it? What do i have to do to make progress tab show the user english progress. If there's missing backend api for it, plz make it on backend api. I think some evaluation values should be provided from the application part. So implement this logic also on application part.

## Why it was empty

`progress_screen.dart` was literally a `StubScreen`. The data was there — backend exposed `GET /progress`, `/progress/snapshots`, `/progress/completions` already — but nothing rendered them.

There was also a write-side gap: only the server could create snapshot rows, but the server has no way to score the user's English yet (the AI orchestrator isn't wired to evaluation). So even if you rendered the data, every chart would be empty.

## What's there now

### Backend: app-side snapshot upload

New endpoint:
```
POST /progress/snapshots
{
  "pronunciation"?: 0–100,
  "fluency"?: 0–100,
  "vocabulary"?: 0–100,
  "grammar"?: 0–100,
  "listening"?: 0–100,
  "confidence"?: 0–100
}
```

Implementation in [backend/src/progress/progress.module.ts](../../backend/src/progress/progress.module.ts) `ProgressService.upsertSnapshot()`:

- One snapshot per `user_id` × `snapshot_date` (existing `@Unique` constraint enforces this).
- If a snapshot already exists for today, the new score is folded in with a running average (`0.7 × old + 0.3 × new`), so multiple sessions in one day refine instead of overwrite.
- Out-of-range values throw `400 BadRequest`.
- Each upload bumps `sessions_in_window` so the weekly bar chart has something to render.

### Flutter: scoring + UI

[session_report_screen.dart](../../flutter_app/lib/features/report/session_report_screen.dart) now fires a snapshot upload as a side-effect when the report opens, using cheap heuristics on the session's `turnCount` + `wordCount`:

| Skill | Heuristic | Why |
|-------|-----------|-----|
| fluency | `40 + (words / turns) × 1.5` clamped 40–95 | Words-per-turn ≈ how much the user said per opportunity |
| vocabulary | `45 + words / 8` clamped 45–95 | More words = more vocabulary exposure |
| grammar | `50 + turns` clamped 50–95 | Each turn is a sentence-construction reps |

Sessions shorter than 2 turns or 10 words don't submit anything. This is explicitly placeholder math — when the AI evaluator lands (todoList §09) it'll replace these heuristics with real scores from the model. The endpoint shape doesn't change.

[progress_screen.dart](../../flutter_app/lib/features/progress/progress_screen.dart) is rebuilt around `screens.md` §8:

1. **CEFR card** — accent square with `A1..C2` label, level name ("Intermediate"), "Climbing toward {next}" sub, animated 6-stop progress bar with tick labels.
2. **Activity card** — count-up minutes total + "+N this week" delta pill + 7-bar mini chart (last bar accent, growth-from-bottom stagger) + two mini-stats (Sessions / Total min).
3. **Skill breakdown** — four animated rows (Pronunciation / Fluency / Vocabulary / Grammar) reading from `latestSnapshot`. Each row has its own accent color so the chart palette stays readable when the bars overlap visually.
4. **Scenarios completed card** — list of the user's completed scenarios with completion counts.

All sections handle the empty case gracefully ("Practice a few sessions to see your trend here.") so a brand-new user doesn't see a wall of zeros.

## Files

| Path | Change |
|------|--------|
| [backend/src/progress/progress.module.ts](../../backend/src/progress/progress.module.ts) | New `upsertSnapshot()` + `POST /progress/snapshots` controller route |
| [flutter_app/lib/core/api/app_apis.dart](../../flutter_app/lib/core/api/app_apis.dart) | New `ProgressApi.submitSnapshot()` |
| [flutter_app/lib/features/progress/progress_screen.dart](../../flutter_app/lib/features/progress/progress_screen.dart) | Stub replaced with full CEFR / activity / skill-breakdown / completions implementation |
| [flutter_app/lib/features/report/session_report_screen.dart](../../flutter_app/lib/features/report/session_report_screen.dart) | Fires a heuristic snapshot upload when the report opens |

## Follow-up

- When the AI evaluator returns real per-skill scores, swap `_maybeSubmitSnapshot` in the report screen for the AI result. Endpoint shape is unchanged.
- Listening scores are nullable in the DB and the app never submits them yet — that's intentional. They'll come once we wire the conversation's STT confidence into the snapshot upload.

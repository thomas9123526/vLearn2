# 0518_v2 batch — Tutor text input, brief screen, cartoon face, progress tab

## What this task did

Processed all 5 files in `todoList/0518_v2/` (01_textfield, 02_topicdescription, 03_modify_tutor, 04_progress, 05_storage) per `job.txt`. Each task got a report in `todoList_report/0518_v2/`. Highlights:

1. **Tutor mode text input** — added a slim text field above the mic so users who can't talk out loud aren't locked out of Tutor mode.
2. **Scenario brief screen** — new intermediate screen between picking a scenario and starting the conversation, matching `design_handoff_freetalk/screens.md` §5 (hero card, roles, twist, objectives, phrases, persona pairing, sticky CTA). Session is only created when the user actually taps "Start speaking" — no orphaned sessions if they back out.
3. **Cartoon tutor face** — replaced the gradient-circle-with-an-initial fallback in Tutor mode with a `CustomPainter`-rendered face (skin, hair, brows, eyes with blink, mouth that animates with TTS, optional glasses, deterministic per-persona looks). Personas with a `riveAsset` still play the Rive file; this is the fallback.
4. **Progress tab** — was a `StubScreen`. Now a full implementation (CEFR card with animated 6-stop bar, activity card with count-up totals + 7-bar mini chart, skill breakdown with per-skill animated rows, completions list). Backend got a new `POST /progress/snapshots` endpoint that running-averages new scores into today's row, and the session report screen now fires a heuristic snapshot upload (fluency / vocabulary / grammar from turn + word counts) so the progress charts have data to show. Heuristics are deliberate placeholders for when the AI evaluator lands.
5. **Missing-screen audit** — walked all 10 design screens; documented what was missing (brief), what was stub (progress, course), what shipped already, and what's still gap (course detail, report-screen visual polish).

## Files

| Path | Change |
|------|--------|
| [flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart](../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart) | Typed-input controller + send button row above the mic |
| [flutter_app/lib/features/conversation/widgets/cartoon_face.dart](../flutter_app/lib/features/conversation/widgets/cartoon_face.dart) | NEW — `CustomPainter` cartoon face |
| [flutter_app/lib/features/conversation/widgets/tutor_avatar.dart](../flutter_app/lib/features/conversation/widgets/tutor_avatar.dart) | Initial-fallback → `CartoonFace` |
| [flutter_app/lib/features/scenarios/scenario_brief_screen.dart](../flutter_app/lib/features/scenarios/scenario_brief_screen.dart) | NEW — brief screen |
| [flutter_app/lib/features/scenarios/scenarios_screen.dart](../flutter_app/lib/features/scenarios/scenarios_screen.dart) | Tile tap → brief (was: inline session start) |
| [flutter_app/lib/core/router/app_router.dart](../flutter_app/lib/core/router/app_router.dart) | `AppRoute.scenarioBrief()` + `/scenarios/:idOrSlug/brief` route |
| [flutter_app/lib/features/progress/progress_screen.dart](../flutter_app/lib/features/progress/progress_screen.dart) | Stub → full implementation |
| [flutter_app/lib/features/report/session_report_screen.dart](../flutter_app/lib/features/report/session_report_screen.dart) | Heuristic snapshot upload on report open |
| [flutter_app/lib/core/api/app_apis.dart](../flutter_app/lib/core/api/app_apis.dart) | `ProgressApi.submitSnapshot()` |
| [backend/src/progress/progress.module.ts](../backend/src/progress/progress.module.ts) | `upsertSnapshot()` + `POST /progress/snapshots` |
| [todoList_report/0518_v2/](../todoList_report/0518_v2/) | 5 task reports |

## User prompt (verbatim)

> For every files inside todoList\0518_v2 folder, read it and do what they said.
> After you have done task, produce report what you have done and save as md format to "todoList_report\0518_v2" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
> You have many times. take it easy.
> Quality is important.

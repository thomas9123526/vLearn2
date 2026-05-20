# For from files xx-xx inside todoList\list folder, read it and do what they said.

Session: `859710bb-e71a-42d3-b4d0-af5e037a10f3`
Saved: 2026-05-20T12:22:24.237Z

## User

For from files xx-xx inside todoList\list folder, read it and do what they said.
After you have done task, produce report what you have done and save as md format to "todoList_report\list" folder.
md filename can be xxx.md where xxx means the current todo file name.
You are an expert fullstack developer
Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
You have many times. take it easy.
Quality is important.

## Assistant

Three of the seven files have content; four are empty. I'll deliver analysis reports for each, with substantive findings for the 3 real tasks and clearly-marked stubs for the 4 empty ones.

## Assistant

All 7 reports written to [todoList_report/list/](todoList_report/list/).

## Substantive reports (3)

- [01_designcheck.md](todoList_report/list/01_designcheck.md) — **Resolution-independence audit.** Bottom line: the app is already vector-first (zero raster UI assets, Material Icons + Rive + CustomPaint everywhere). Five small gaps with zero/negative bundle impact: adaptive vector launcher icon, remove unused `flutter_svg` (or commit to using it), responsive `?w=…` on news thumbnails, Rive avatars sized via `MediaQuery.shortestSide`, Android 12 splash verify.
- [02_animation_part.md](todoList_report/list/02_animation_part.md) — **Animations gap analysis** with screen-by-screen comparison. Splash (5/5 missing — what you called out) and Report (9/9 missing) are the biggest gaps. Tutor/Face mode is ~70% implemented. Priority-ordered solutions, mostly pure-Flutter (no new deps). Top three: splash rebuild (~4 hr), Report score-ring sweep + count-up (~1.5 hr), `AnimatedList` for chat bubbles (~15 min).
- [03_diff_find.md](todoList_report/list/03_diff_find.md) — **Overall design ↔ app diff.** All 11 design screens are present in Flutter (zero missing). Extra screens in Flutter not in design: News (list + detail), Models setup, Profile edit. Divergences are fidelity-inside-screen, not screen-missing.

## Stub reports (4 empty source files)

- [00_application_design.md](todoList_report/list/00_application_design.md)
- [24_openssl.md](todoList_report/list/24_openssl.md)
- [24_sign_backend.md](todoList_report/list/24_sign_backend.md)
- [24_sign_user.md](todoList_report/list/24_sign_user.md)

Each stub records that the source `todoList/list/<name>` is empty, suggests likely scopes given the filename, and asks for the description to be filled in so the task can be processed.

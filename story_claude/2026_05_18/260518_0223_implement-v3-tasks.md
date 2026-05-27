# Implement v3 tasks (config file, rename, admin pages, audits)

## What this task did

Processed all 9 files under [`todoList/0517_v3/`](../todoList/0517_v3/) — implementing the four implementable tasks and writing analytical reports for the five that were audits or analyses.

### Implementations

- **01_check_config** — On-disk JSON config (`baseurl`, `reqTout`, `tSync`, `dev`) at `<storage>/룡마/가상외국어회화/config/app_config.json` on Android, exe-relative on Windows. Auto-created with defaults if missing; corruption-tolerant; loaded before `runApp` so the Dio client picks up the resolved `backendBaseUrl` and `requestTimeout` on its first read.
- **10_rename** — App renamed to "Virtual Foreign Language" everywhere the user sees it: Android launcher label, Windows window title + VERSIONINFO, splash wordmark, MaterialApp title, and the `appTitle` ARB key (translated to "가상 외국어 회화" and "虚拟外语会话"). Internal identifiers (Dart package name, Android applicationId, exe binary name) intentionally kept to avoid breaking install identity.
- **12_admin** — Admin panel + backend:
  - 3 new backend controllers: scenarios CRUD with multipart image upload, users with suspend/restore, leaderboard with metric/language/top-N filters.
  - `GzipFlagCache` for live `system.gzip_enabled` toggle that the compression filter reads per-request (no server restart).
  - Static `useStaticAssets('/uploads/')` serving for uploaded hero images.
  - 6 admin-panel pages: full scenarios list, scenarios/new form with image upload, users with block/restore, leaderboard with filters, sub-admin management with permission grid, settings tab with gzip toggle. All gated by `usePermission()`.

### Audits / reports

- **02_design_check** — Audit confirming the app is already resolution-independent (Material icons + theme colors are vector; no raster icons shipped). Concrete next steps: swap `Image.network` for `CachedNetworkImage`, regenerate launcher icons from SVG via `flutter_launcher_icons`.
- **05_font_solution** — Duplicate of v2 task 05; references the existing report.
- **06_check_i18n** — Infrastructure is in place (delegates, 3 ARB files × ~85 keys, picker, generated code, `appTitle` translated per task 10). What's left is the mechanical refactor of screen-file English literals to `AppLocalizations.of(context)!.…` calls.
- **08_animation_part** — Catalogues every animation called for by [`design_handoff_freetalk/screens.md`](../vLearn2Spec/design_handoff_freetalk/screens.md) + [`components.md`](../vLearn2Spec/design_handoff_freetalk/components.md), maps each to a concrete Flutter widget approach (Pulse, AnimatedBar, AnimatedNumber, AnimatedScoreRing, splash choreography, persona Rive state-machine), and recommends a 3-PR plan to land them.
- **09_diff_find** — Screen-by-screen diff against the design handoff. Lists every spec element that's missing, present, or exceeded (e.g. font groups, bubble styles, news strip — none of those are in the original spec).
- **11_apksize** — Estimates the standalone APK at ~25 MB with current rules (sherpa-onnx models on sdcard, no bundled images, tree-shake-icons, split-per-ABI). Outlines the 8 rules that keep it that way and what to do if it ever creeps past 40 MB.

### Reports

All 9 under [`todoList_report/0517_v3/`](../todoList_report/0517_v3/), one per source file.

## User prompt (verbatim)

> For every files inside todoList\\0517_v3 folder, read it and do what they said.
> After you have done task, produce report what you have done and save as md format to "todoList_report\\0517_v3" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
> You have many times. take it easy.
> Quality is important.

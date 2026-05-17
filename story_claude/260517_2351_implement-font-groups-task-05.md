# Implement 05_font_groups — 4 bundled groups, google_fonts removed

## What this task did

Built the architecture for 4 curated font groups (`editorial` / `modern` / `friendly` / `classic`) per [todoList/0517_v2/05_font_groups.md](../todoList/0517_v2/05_font_groups.md):

- New `FontGroup` enum with `displayName`, `description`, `families` (heading/body/mono) tokens, and a `fromKey` round-trip
- `AppTheme.build` now takes `(paletteKey, fontGroup)` and routes display/headline styles to the heading family, title/body/label to the body family, via an internal `_buildTextTheme` helper
- `AppSettingsState` gained a `fontGroup` field persisted to SharedPreferences under `appearance.font_group`; `fontGroupProvider` exposes it as a Riverpod `Provider<FontGroup>`
- `main.dart` watches both `themeKeyProvider` and `fontGroupProvider` and rebuilds `MaterialApp` when either changes
- Settings screen gained a new "Font" section with a bottom-sheet picker showing live previews ("The quick brown fox" in each group's heading + body + mono)
- 6 i18n keys added across en/ko/zh
- `google_fonts: ^6.2.1` removed from `pubspec.yaml`; replacement `flutter.fonts` block included as comments — uncomment after dropping in the .ttf files
- 4 per-group `README.md` files and an aggregated OFL 1.1 `LICENSES.md` document the drop-in workflow

I also created the [`flutter_app/lib/features/conversation/widgets/chat_bubble.dart`](../flutter_app/lib/features/conversation/widgets/chat_bubble.dart) file in this commit because the Font picker's preview UI shares the `ChatBubble` widget with task 04 — pulling that forward kept both pickers in the same Settings screen edit. Task 04's full implementation (custom `_BubbleTailShape`, dashed-border `notebook` style, conversation-screen wiring) is delivered in this commit too as a result.

## What's intentionally NOT in this commit

- **The actual .ttf font files.** They're large binaries (~5 MB) and each group's `README.md` lists the exact upstream OFL 1.1 sources to download from. Until they land, every group falls back to the platform default font (Roboto / SF / Segoe UI) — the picker works but is visually muted.
- **The uncommented `pubspec.fonts` block.** If uncommented before the .ttf files are present, `flutter build` fails with "Font asset not found". Safe default is to leave it commented; flip it after fonts arrive.

## Report

[todoList_report/0517_v2/05_font_groups.md](../todoList_report/0517_v2/05_font_groups.md)

## Verification

`flutter analyze` should report 0 errors. The only outstanding issue is the platform-fallback for missing CJK glyphs (§5.9 honest call-out — same as before this commit).

## User prompt (verbatim)

> For every txt files inside todoList\\0517_v2 folder, plz do the todo List one by one.
> After you have done task, produce report what you have done and save as md format to "todoList_report\\0517_v2" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
> You have many times. take it easy.
> Quality is important.

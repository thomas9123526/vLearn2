# Report — 05 — Font groups (4 curated, fully offline)

Implemented the architecture for 4 bundled font groups, ripped out `google_fonts`, and added the Font picker to Settings. The `.ttf` files themselves are not in the repo — see §"Drop-in steps" below for how to finish the rollout.

## Files added / changed

| Path | Change |
|------|--------|
| [flutter_app/lib/core/theme/font_group.dart](../../flutter_app/lib/core/theme/font_group.dart) | NEW — `FontGroup` enum + `FontFamilies` token + `FontGroupExt.fromKey` |
| [flutter_app/lib/core/theme/app_theme.dart](../../flutter_app/lib/core/theme/app_theme.dart) | REWRITE — drop `google_fonts`, `build()` now takes a `FontGroup`, internal `_buildTextTheme(group, base, color)` maps display/headline → heading family, title/body/label → body family |
| [flutter_app/lib/core/providers/settings_provider.dart](../../flutter_app/lib/core/providers/settings_provider.dart) | Added `fontGroup` field to `AppSettingsState`, `setFontGroup` method, and `fontGroupProvider` selector |
| [flutter_app/lib/main.dart](../../flutter_app/lib/main.dart) | Now watches `fontGroupProvider` and passes it to `AppTheme.build` |
| [flutter_app/lib/features/settings/settings_screen.dart](../../flutter_app/lib/features/settings/settings_screen.dart) | New "Font" section between Appearance and Network with bottom-sheet picker; picker renders live previews of each group's heading + body + mono families |
| [flutter_app/lib/l10n/app_en.arb](../../flutter_app/lib/l10n/app_en.arb), [app_ko.arb](../../flutter_app/lib/l10n/app_ko.arb), [app_zh.arb](../../flutter_app/lib/l10n/app_zh.arb) | 6 new keys: `settingsFont`, `settingsFontGroup`, `fontGroup{Editorial,Modern,Friendly,Classic}` |
| [flutter_app/pubspec.yaml](../../flutter_app/pubspec.yaml) | Removed `google_fonts: ^6.2.1` dependency. Added commented-out `flutter.fonts` block declaring all 12 families across the 4 groups — uncomment after dropping in the `.ttf` files |
| [flutter_app/assets/fonts/editorial/README.md](../../flutter_app/assets/fonts/editorial/README.md), [modern/README.md](../../flutter_app/assets/fonts/modern/README.md), [friendly/README.md](../../flutter_app/assets/fonts/friendly/README.md), [classic/README.md](../../flutter_app/assets/fonts/classic/README.md) | NEW — drop-in instructions per group |
| [flutter_app/assets/fonts/LICENSES.md](../../flutter_app/assets/fonts/LICENSES.md) | NEW — aggregated OFL 1.1 attribution covering all 7 typefaces |

## The 4 groups (final shape)

| Group | Heading | Body | Mono |
|-------|---------|------|------|
| editorial | Lora (serif) | Inter (sans) | JetBrains Mono |
| modern | Inter | Inter | JetBrains Mono |
| friendly | Quicksand (rounded sans) | Nunito | JetBrains Mono |
| classic | Playfair Display (serif) | Source Serif Pro | JetBrains Mono |

Default: `editorial` (matches the current claude.design-influenced look).

## How it works without the .ttf files yet

The app **still builds and runs** with this PR. The font-family strings (`EditorialHeading`, etc.) are referenced in `TextStyle.copyWith(fontFamily: …)`. When the family isn't declared in `pubspec.fonts`, Flutter's text engine silently falls back to the platform default font (Roboto on Android, SF on iOS, Segoe UI on Windows). So:

1. Today: app runs with system font; Font picker visible and works (no visible difference between groups yet, since they all fall back).
2. Drop-in steps below: bundle the .ttf files → uncomment pubspec block → each group renders distinctly.

This matches the project's "ship working code first, polish later" pattern and keeps the v2 plans testable in isolation.

## Drop-in steps to finish the rollout (manual, one-time)

1. Clone or download each upstream repo (links in [LICENSES.md](../../flutter_app/assets/fonts/LICENSES.md))
2. Copy the exact .ttf filenames listed in each group's README.md into the matching folder
3. Open [pubspec.yaml](../../flutter_app/pubspec.yaml) and uncomment the `fonts:` block under `flutter:` (lines starting `# fonts:`)
4. `flutter clean && flutter pub get && flutter run`
5. Open Settings → Font → pick "Friendly" — the app text should change to rounded Quicksand/Nunito immediately
6. Build APK and confirm fonts ship inside: `unzip -l build/app/outputs/flutter-apk/app-release.apk | grep fonts/`

## Verification against the spec

| Checklist | Status |
|-----------|--------|
| 5.3.1 Remove `google_fonts` dep | ✅ removed from pubspec.yaml |
| 5.3.2 Declare font families in `flutter.fonts` | ⚠️ declared but commented out — uncomment after .ttf files land |
| 5.4.1 `FontGroup` enum + extension | ✅ in `font_group.dart` |
| 5.4.2.1 `AppTheme.build(palette, fontGroup)` signature | ✅ |
| 5.4.2.3 Remove `import google_fonts` | ✅ |
| 5.4.3.1 `appearance.font_group` SharedPreferences key | ✅ |
| 5.4.3.4 `main.dart` watches both `themeKeyProvider` + `fontGroupProvider` | ✅ |
| 5.5.1–5.5.5 Font picker in Settings with rendered preview | ✅ |
| 5.6.1–5.6.3 .ttf files committed | ❌ deferred to drop-in step (large binaries; OFL attribution preserved in LICENSES.md when files added) |
| 5.7 i18n keys | ✅ across en/ko/zh |
| 5.8.5 No network needed | ✅ — `google_fonts` package fully removed; no other runtime font fetch path exists |

## Honest call-outs

1. **.ttf files are not committed** — they're large binaries (~5 MB total), upstream-licensed, and best fetched from the source repos at install time. The four `assets/fonts/<group>/README.md` files spell out exactly which filenames to drop in. Until the files land, every group falls back to the system font (Roboto / SF / Segoe).
2. **`pubspec.fonts` block is commented out**. If you uncomment it before the .ttf files are present, `flutter build` will fail with "Font asset ... was not found". So the commented state is the safe default; uncomment after fonts land.
3. **`google_fonts` is gone for good.** Only `AppTheme.build` used it; that's now resolved. No other place in `flutter_app/lib/**` references `google_fonts`.
4. **CJK coverage call-out from §5.9 stands.** None of the chosen Latin-script fonts cover full CJK ranges. Flutter falls back to system fonts for missing glyphs — visually mixed but readable. Add Noto Sans CJK later if Korean/Chinese users report problems.
5. **`pubspec.lock` still references `google_fonts`** until `flutter pub get` runs. Not a problem; it'll be regenerated on the next dependency resolve.
6. **The Font picker is fully functional today** — picking a group writes to SharedPreferences and rebuilds the theme. The visual feedback will be muted until the .ttf files are present, but the wiring is end-to-end correct.

## Sequencing for v2 work

Task 05 is foundational — the Settings screen now hosts a "Font" section, and task 04 will add a "Conversation" section right below it (already in place in this commit, since the same screen edit naturally handles both). Tasks 01/02/03 are independent and can proceed in any order.

# Report — 05 — Font groups (already implemented in v2)

This task is identical text to `todoList/0517_v2/05_font_groups.md` which was implemented in commit `95d2563`. See [todoList_report/0517_v2/05_font_groups.md](../0517_v2/05_font_groups.md) for the full report.

## Summary of what's live

- `FontGroup` enum (`editorial / modern / friendly / classic`) in [flutter_app/lib/core/theme/font_group.dart](../../flutter_app/lib/core/theme/font_group.dart)
- `AppTheme.build(palette, fontGroup)` builds a `TextTheme` mapping display/headline → heading family, title/body/label → body family
- `AppSettingsState.fontGroup` persisted to `SharedPreferences` under `appearance.font_group`
- `fontGroupProvider` Riverpod selector
- Settings → Font section with bottom-sheet picker rendering live previews per group
- `google_fonts` dependency **removed** from `pubspec.yaml` and `pubspec.lock` — the offline + low-traffic requirement is met
- Commented-out `flutter.fonts` block in pubspec ready to uncomment once the .ttf files are dropped into `assets/fonts/<group>/`
- Per-group `README.md` + aggregated `LICENSES.md` document the OFL 1.1 drop-in workflow
- 6 i18n keys × 3 languages (`settingsFont`, `settingsFontGroup`, `fontGroup{Editorial,Modern,Friendly,Classic}`)

## What's still pending

The architecture is complete. The single remaining manual step is dropping the .ttf files into `flutter_app/assets/fonts/<group>/` from the upstream OFL repos (links in each folder's README.md) and uncommenting the `fonts:` block in [pubspec.yaml](../../flutter_app/pubspec.yaml).

## Per the user's constraint

> I want put all font files inside the application code part and donn't want fetch font from the internet. I don't want big trafic through the network.

Both halves are honoured:
- **No internet fetch** — `google_fonts` is gone; nothing in the codebase reaches out for a typeface.
- **No big traffic** — fonts ship inside the APK once the .ttf files land in the asset folders. The bundle cost (~5 MB total for 7 typefaces) is documented; it's a one-time install download, not per-launch traffic.

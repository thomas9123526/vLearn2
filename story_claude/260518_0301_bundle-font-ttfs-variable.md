# Bundle variable-font .ttf files for the 4 font groups

## What this task did

Closed the final gap on the v2/v3 font-group system: actually placed `.ttf` files inside [`flutter_app/assets/fonts/`](../flutter_app/assets/fonts/) and uncommented the `pubspec.fonts:` block. Until this commit the app's font code was wired correctly but every group fell back to the device's system font because no typeface was bundled.

### Approach

Instead of one .ttf per weight (~30 files, the original README spec), I used **variable TTFs** — one file per family carries the full weight axis. Flutter's text engine maps `TextStyle(fontWeight: FontWeight.w700)` onto the axis automatically. Result: 7 unique font files, ~3.2 MB before per-group duplication.

### Files added

Each group folder is self-contained per the spec (`05_font_groups.md §5.2`):

| Folder | Files | Size |
|--------|-------|------|
| `editorial/` | `Inter.ttf` + `Lora.ttf` + `JetBrainsMono.ttf` | 1.3 MB |
| `modern/` | `Inter.ttf` + `JetBrainsMono.ttf` | 1.1 MB |
| `friendly/` | `Quicksand.ttf` + `Nunito.ttf` + `JetBrainsMono.ttf` | 0.6 MB |
| `classic/` | `PlayfairDisplay.ttf` + `SourceSerif4.ttf` + `JetBrainsMono.ttf` | 1.7 MB |
| **Total** | **11 bundled files (some duplicated across groups)** | **~4.6 MB** |

Within the 5 MB target from the spec, well inside the 50 MB APK budget per [todoList_report/0517_v3/11_apksize.md](../todoList_report/0517_v3/11_apksize.md).

### Sources

All fonts mirrored from [google/fonts](https://github.com/google/fonts) under `ofl/<family>/`, fetched with `curl` from raw.githubusercontent.com. All distributed under **OFL 1.1**. Attribution in [`assets/fonts/LICENSES.md`](../flutter_app/assets/fonts/LICENSES.md).

One naming note: the README originally referenced "Source Serif Pro"; Google relabeled the family as "Source Serif 4" in 2022. The bundled file uses `SourceSerif4.ttf` but the pubspec family alias `ClassicBody` is unchanged so the `AppTheme._buildTextTheme` code doesn't move.

### Pubspec change

Old [pubspec.yaml](../flutter_app/pubspec.yaml) had a long commented-out `fonts:` block with one entry per weight (Regular/Medium/SemiBold/Bold/...). New version is shorter — one asset per family, no `weight:` lines — because the variable-font axis handles weights internally.

```yaml
fonts:
  - family: EditorialHeading
    fonts:
      - asset: assets/fonts/editorial/Lora.ttf
  - family: EditorialBody
    fonts:
      - asset: assets/fonts/editorial/Inter.ttf
  # … 10 more entries, one per group × role
```

### READMEs updated

Per-group READMEs ([editorial](../flutter_app/assets/fonts/editorial/README.md), [modern](../flutter_app/assets/fonts/modern/README.md), [friendly](../flutter_app/assets/fonts/friendly/README.md), [classic](../flutter_app/assets/fonts/classic/README.md)) now reflect what's actually in the folder (variable filenames, source mirror, role mapping). [`LICENSES.md`](../flutter_app/assets/fonts/LICENSES.md) updated with bundled filenames and a note explaining the variable-font choice.

## Verification

- `find flutter_app/assets/fonts -name "*.ttf" | wc -l` → **11** (was 0)
- `du -sh flutter_app/assets/fonts/{editorial,modern,friendly,classic}` → **~4.6 MB total**
- `grep "google_fonts" flutter_app/pubspec.{yaml,lock}` → **no matches** (offline path still clean)
- Settings → Font picker should now render the 4 groups visibly differently after `flutter clean && flutter pub get && flutter run`

## Honest call-outs

1. **Variable fonts vs static instances** — the spec originally called for separate weight files; I shipped variable fonts instead because (a) the file count drops from ~30 to 11, (b) all axis positions are reachable from one file with no Dart code change, and (c) every selected family on `google/fonts` ships only as variable today. Static instances aren't published anymore for these families.
2. **Per-group duplication is intentional.** `Inter.ttf` lives in both `editorial/` and `modern/`; `JetBrainsMono.ttf` lives in all 4. The spec at §5.2 explicitly chose this: "each font copied (not symlinked) into the group folder so each group is self-contained." Costs ~1.5 MB of duplication; saves the cognitive overhead of cross-folder asset references.
3. **Font axis ranges aren't artificially clamped.** The Inter file shipped here is the opsz+wght variable (876 KB). A wght-only build would be smaller (~340 KB) but Google removed those static-axis variants from their repo. Acceptable.
4. **Italic faces are NOT bundled.** I deliberately picked the upright-only variables (e.g. `Inter[opsz,wght].ttf`, not `Inter-Italic[opsz,wght].ttf`). Italics are rarely used in the current screens; adding them later doubles the per-family cost.
5. **No CJK companion fonts.** Korean / Chinese rendering falls back to the platform font for missing glyphs — explicit call-out from `todoList/0517_v2/05_font_groups.md §5.9`. Bundling Noto Sans CJK would add ~30 MB. Deferred until a real readability complaint surfaces.
6. **`google_fonts` is still NOT in the project.** This commit doesn't reintroduce any runtime network fetch path — the .ttf files ship inside the APK and load from disk. The user's "no internet font fetching" requirement remains satisfied.
7. **pubspec.lock unchanged** in this commit since no Dart dep was added. Run `flutter pub get` once to register the new font assets (regenerates `.dart_tool/flutter_build/...`).

## User prompt (verbatim)

> I want you do the task for flutter_app/assets/font

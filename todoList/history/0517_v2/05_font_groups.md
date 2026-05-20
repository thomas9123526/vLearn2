# 05 — Font groups (4 curated, fully offline, bundled .ttf)

Four named font groups (each a curated set of related typefaces). Files **bundled in the app**, **no runtime fetch from the internet** — `google_fonts` package is removed.

## 5.1 The four groups

Each group has 3 roles: **heading**, **body**, **mono**. Material 3 `TextTheme` maps each role to a set of text styles (display/headline → heading; titleLarge/bodyLarge/labelLarge → body; bodySmall + code blocks → mono).

| Group | Heading | Body | Mono | Vibe |
|-------|---------|------|------|------|
| `editorial` | **Lora** (serif) | **Inter** (sans) | **JetBrains Mono** | Magazine-style; serif headers + clean sans body — pairs well with the apricot theme |
| `modern` | **Inter** (sans) | **Inter** (sans) | **JetBrains Mono** | Geometric, neutral, business-y; works with sage / iris / obsidian |
| `friendly` | **Quicksand** (rounded sans) | **Nunito** (rounded sans) | **JetBrains Mono** | Soft, approachable; great for younger learners |
| `classic` | **Playfair Display** (serif) | **Source Serif Pro** (serif) | **JetBrains Mono** | Traditional book-style; full serif everywhere |

Default: `editorial` (matches the current claude.design-influenced look).

All 7 unique families above are under the **SIL Open Font License 1.1** or **Apache 2.0** — both allow bundling in a closed-source app.

## 5.2 File layout

```
flutter_app/assets/fonts/
├── editorial/
│   ├── Lora-Regular.ttf
│   ├── Lora-Bold.ttf
│   ├── Inter-Regular.ttf
│   ├── Inter-Medium.ttf
│   ├── Inter-SemiBold.ttf
│   ├── Inter-Bold.ttf
│   └── JetBrainsMono-Regular.ttf
├── modern/
│   ├── Inter-Regular.ttf
│   ├── Inter-Medium.ttf
│   ├── Inter-SemiBold.ttf
│   ├── Inter-Bold.ttf
│   └── JetBrainsMono-Regular.ttf
├── friendly/
│   ├── Quicksand-Regular.ttf
│   ├── Quicksand-Bold.ttf
│   ├── Nunito-Regular.ttf
│   ├── Nunito-Bold.ttf
│   └── JetBrainsMono-Regular.ttf
├── classic/
│   ├── PlayfairDisplay-Regular.ttf
│   ├── PlayfairDisplay-Bold.ttf
│   ├── SourceSerifPro-Regular.ttf
│   ├── SourceSerifPro-Bold.ttf
│   └── JetBrainsMono-Regular.ttf
└── LICENSES.md
```

Each font copied (not symlinked) into the group folder so each group is self-contained. Adds duplication but simplifies the pubspec declaration and CDN-replacement reasoning.

**Approximate weight**: 4 groups × 5–6 fonts × ~250 KB = ~5 MB total bundled into the APK. Acceptable.

## 5.3 pubspec.yaml — drop `google_fonts`, declare bundled fonts

- [ ] **5.3.1** Remove `google_fonts: ^6.2.1` from dependencies (the package is the only remaining runtime-fetch path)
- [ ] **5.3.2** Declare each font family in the `flutter.fonts` block:

```yaml
flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/fonts/editorial/
    - assets/fonts/modern/
    - assets/fonts/friendly/
    - assets/fonts/classic/
    - assets/config/
    - assets/guard/
    - assets/wordlists/
    - assets/images/
    - assets/animations/
    - assets/icons/
  fonts:
    # Editorial group
    - family: EditorialHeading
      fonts:
        - asset: assets/fonts/editorial/Lora-Regular.ttf
        - asset: assets/fonts/editorial/Lora-Bold.ttf
          weight: 700
    - family: EditorialBody
      fonts:
        - asset: assets/fonts/editorial/Inter-Regular.ttf
        - asset: assets/fonts/editorial/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/editorial/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/editorial/Inter-Bold.ttf
          weight: 700
    - family: EditorialMono
      fonts:
        - asset: assets/fonts/editorial/JetBrainsMono-Regular.ttf
    # … same shape for Modern, Friendly, Classic groups
```

(The full pubspec block is verbose but mechanical. ~50 lines.)

## 5.4 Code structure

### 5.4.1 FontGroup enum + token map

**File:** `flutter_app/lib/core/theme/font_group.dart`

```dart
enum FontGroup { editorial, modern, friendly, classic }

extension FontGroupLabel on FontGroup {
  String get displayName => switch (this) {
        FontGroup.editorial => 'Editorial',
        FontGroup.modern => 'Modern',
        FontGroup.friendly => 'Friendly',
        FontGroup.classic => 'Classic',
      };

  ({String heading, String body, String mono}) get families => switch (this) {
        FontGroup.editorial => (heading: 'EditorialHeading', body: 'EditorialBody', mono: 'EditorialMono'),
        FontGroup.modern => (heading: 'ModernHeading', body: 'ModernBody', mono: 'ModernMono'),
        FontGroup.friendly => (heading: 'FriendlyHeading', body: 'FriendlyBody', mono: 'FriendlyMono'),
        FontGroup.classic => (heading: 'ClassicHeading', body: 'ClassicBody', mono: 'ClassicMono'),
      };

  static FontGroup fromKey(String? k) =>
      FontGroup.values.firstWhere(
        (g) => g.name == k,
        orElse: () => FontGroup.editorial,
      );
}
```

### 5.4.2 TextTheme builder

**File:** `flutter_app/lib/core/theme/app_theme.dart` — replace the `GoogleFonts.interTextTheme(...)` call with a custom builder

```dart
TextTheme _buildTextTheme(FontGroup group, TextTheme base, Color color) {
  final f = group.families;
  return base.copyWith(
    // Display + headline → heading family
    displayLarge:  base.displayLarge?.copyWith(fontFamily: f.heading, color: color, fontWeight: FontWeight.w700),
    displayMedium: base.displayMedium?.copyWith(fontFamily: f.heading, color: color, fontWeight: FontWeight.w700),
    displaySmall:  base.displaySmall?.copyWith(fontFamily: f.heading, color: color, fontWeight: FontWeight.w700),
    headlineLarge: base.headlineLarge?.copyWith(fontFamily: f.heading, color: color, fontWeight: FontWeight.w700),
    headlineMedium:base.headlineMedium?.copyWith(fontFamily: f.heading, color: color, fontWeight: FontWeight.w700),
    headlineSmall: base.headlineSmall?.copyWith(fontFamily: f.heading, color: color, fontWeight: FontWeight.w600),
    // Title + body + label → body family
    titleLarge:    base.titleLarge?.copyWith(fontFamily: f.body, color: color, fontWeight: FontWeight.w600),
    titleMedium:   base.titleMedium?.copyWith(fontFamily: f.body, color: color, fontWeight: FontWeight.w600),
    titleSmall:    base.titleSmall?.copyWith(fontFamily: f.body, color: color, fontWeight: FontWeight.w500),
    bodyLarge:     base.bodyLarge?.copyWith(fontFamily: f.body, color: color),
    bodyMedium:    base.bodyMedium?.copyWith(fontFamily: f.body, color: color),
    bodySmall:     base.bodySmall?.copyWith(fontFamily: f.body, color: color),
    labelLarge:    base.labelLarge?.copyWith(fontFamily: f.body, color: color, fontWeight: FontWeight.w600),
    labelMedium:   base.labelMedium?.copyWith(fontFamily: f.body, color: color),
    labelSmall:    base.labelSmall?.copyWith(fontFamily: f.body, color: color),
  );
}
```

- [ ] **5.4.2.1** `AppTheme.build` signature becomes `build(String paletteKey, FontGroup fontGroup)` — wires the new text-theme builder
- [ ] **5.4.2.2** Mono family used in places that render code-ish text — currently nowhere, but the token's there for future use (e.g. session report diagnostic data)
- [ ] **5.4.2.3** Remove the `import 'package:google_fonts/google_fonts.dart';` line

### 5.4.3 Settings persistence

- [ ] **5.4.3.1** New key `appearance.font_group` in `AppSettingsState`; default `editorial`
- [ ] **5.4.3.2** `AppSettingsNotifier.setFontGroup(FontGroup)` writes to SharedPreferences
- [ ] **5.4.3.3** New `fontGroupProvider = Provider<FontGroup>((ref) => ...)` selector
- [ ] **5.4.3.4** `main.dart` consumes both `themeKeyProvider` AND `fontGroupProvider` to build the active `ThemeData`

## 5.5 Settings screen — Font section

Per task 04, the font picker sits **above** the bubble-style picker, both under the "Appearance" group.

- [ ] **5.5.1** New section header "Font" in `settings_screen.dart`
- [ ] **5.5.2** Tile: "Font group" with the current selection name as subtitle
- [ ] **5.5.3** Tap → bottom-sheet picker showing the 4 groups
- [ ] **5.5.4** Each picker entry shows a **rendered preview**:
  - Heading line in the group's heading family: "The quick brown fox"
  - Body line in the group's body family: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
  - Tiny mono caption in mono family: "v1.0.0"
- [ ] **5.5.5** Selected state via check icon

## 5.6 Acquiring the font files

These are **manual one-time downloads** (committed under `assets/fonts/`):

| Font | Source | License |
|------|--------|---------|
| Inter | https://github.com/rsms/inter | OFL 1.1 |
| Lora | https://github.com/cyrealtype/Lora-Cyrillic | OFL 1.1 |
| Quicksand | https://github.com/andrew-paglinawan/QuicksandFamily | OFL 1.1 |
| Nunito | https://github.com/googlefonts/nunito | OFL 1.1 |
| Playfair Display | https://github.com/clauseggers/Playfair | OFL 1.1 |
| Source Serif Pro | https://github.com/adobe-fonts/source-serif | OFL 1.1 |
| JetBrains Mono | https://github.com/JetBrains/JetBrainsMono | OFL 1.1 |

- [ ] **5.6.1** Download .ttf weights listed in §5.2 and place under `assets/fonts/<group>/`
- [ ] **5.6.2** Copy each font's `LICENSE` / `OFL.txt` into `assets/fonts/LICENSES.md` aggregated; this satisfies attribution requirements
- [ ] **5.6.3** Add `assets/fonts/LICENSES.md` to the in-app About → Licenses screen (Flutter's `showLicensePage` picks up bundled fonts automatically)

## 5.7 i18n

Add to `app_en.arb` / `app_ko.arb` / `app_zh.arb`:
- `settingsFont` (label "Font")
- `settingsFontGroup` ("Font group")
- `fontGroupEditorial`, `fontGroupModern`, `fontGroupFriendly`, `fontGroupClassic`

## 5.8 Verification

- [ ] **5.8.1** Pick each group → settings screen + home screen + conversation screen all update font immediately
- [ ] **5.8.2** Korean + Chinese: every font group's heading font must support CJK glyphs **OR** fall back gracefully. **Honest check:** Lora/Playfair/Source Serif don't ship full CJK; Flutter falls back to system fonts for missing glyphs. For pure Latin scripts this is fine; for CJK-heavy users the `modern` (Inter has Cyrillic+Greek but limited CJK) or `friendly` groups may also fall back. See §5.9
- [ ] **5.8.3** `flutter analyze` — no errors
- [ ] **5.8.4** Build APK → confirm the binary contains the fonts (`unzip app-release.apk | grep fonts/`)
- [ ] **5.8.5** Run with airplane mode on first launch → fonts render correctly (no network needed)

## 5.9 Honest call-outs

1. **The user's "no internet fetch" requirement is fully met** by removing `google_fonts` and bundling. Confirm with a network-disabled smoke test.
2. **CJK coverage is the biggest gotcha.** None of the chosen Latin-script fonts have full CJK ranges. Two options:
   - **Accept fallback** — Flutter's text engine picks up the system font for missing glyphs. Visually it'll be a mix, which is jarring at high zoom but acceptable for body text.
   - **Add a CJK companion font per group** — e.g. Noto Sans CJK as the body font for Korean/Chinese locales (~10 MB per script, ~30 MB extra; significant). Defer until a Korean/Chinese user reports actual readability problems.
3. **APK size grows by ~5 MB.** Within the standalone-APK budget.
4. **`google_fonts` removal is a hard cut.** Any other place in the app that references it (search the repo) needs to be replaced with the new builder. Today it's only used in `AppTheme.build`.
5. **Mono font** is unused today but declared because (a) it's a small cost and (b) future surfaces (settings → debug, session-report diagnostics, admin-panel-style developer tools) might want it. Drop if you want to slim the APK by ~1 MB.
6. **Font weight coverage** is intentionally lean (Regular + Bold for headings; Regular/Medium/SemiBold/Bold for body). Adding Light or ExtraBold doubles asset size with marginal benefit.
7. **License file aggregation** is required by OFL 1.1 attribution clauses. The aggregated `LICENSES.md` covers the legal requirement; the in-app About page surfaces it.

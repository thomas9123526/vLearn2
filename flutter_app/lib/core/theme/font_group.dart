/// The 4 curated font groups available in Settings → Appearance.
///
/// Each group resolves to three font-family names declared in
/// [`pubspec.yaml`](../../pubspec.yaml) under `flutter.fonts`:
///   - `heading` for display/headline text styles
///   - `body` for title/body/label text styles
///   - `mono` for diagnostic/code surfaces
///
/// If the .ttf files haven't been bundled yet, Flutter silently falls back
/// to the platform default font (Roboto on Android, SF on iOS, Segoe UI on
/// Windows) — the app still renders correctly.
enum FontGroup { editorial, modern, friendly, classic }

class FontFamilies {
  const FontFamilies({
    required this.heading,
    required this.body,
    required this.mono,
  });
  final String heading;
  final String body;
  final String mono;
}

extension FontGroupExt on FontGroup {
  String get displayName => switch (this) {
        FontGroup.editorial => 'Editorial',
        FontGroup.modern => 'Modern',
        FontGroup.friendly => 'Friendly',
        FontGroup.classic => 'Classic',
      };

  /// Short tagline shown under the group name in the picker preview.
  String get description => switch (this) {
        FontGroup.editorial => 'Serif headings + clean sans body',
        FontGroup.modern => 'Geometric sans throughout',
        FontGroup.friendly => 'Soft rounded sans',
        FontGroup.classic => 'Traditional book-style serif',
      };

  /// Resolved font-family names. Must match the `family:` entries in pubspec.
  FontFamilies get families => switch (this) {
        FontGroup.editorial => const FontFamilies(
              heading: 'EditorialHeading',
              body: 'EditorialBody',
              mono: 'EditorialMono',
            ),
        FontGroup.modern => const FontFamilies(
              heading: 'ModernHeading',
              body: 'ModernBody',
              mono: 'ModernMono',
            ),
        FontGroup.friendly => const FontFamilies(
              heading: 'FriendlyHeading',
              body: 'FriendlyBody',
              mono: 'FriendlyMono',
            ),
        FontGroup.classic => const FontFamilies(
              heading: 'ClassicHeading',
              body: 'ClassicBody',
              mono: 'ClassicMono',
            ),
      };

  static FontGroup fromKey(String? key) =>
      FontGroup.values.firstWhere(
        (g) => g.name == key,
        orElse: () => FontGroup.editorial,
      );
}

# 05_settings_theme — Theme picker color swatches

## Ask

> When the user change theme at the settings screen of application, app shows dialog to select theme. I want put some colors to notice the user how the theme will be like.

## Before

The theme picker was a plain `ModalBottomSheet` containing a `ListView` with four `ListTile`s showing only the text label ("apricot", "sage", etc.). Users had no way to tell what each theme looked like before tapping.

## After

The picker is rebuilt as a visual selector. Each theme option is rendered as a card that uses the theme's own actual colors — the card background, text color, and border all come from `AppPalette.byKey[themeKey]`. Three color dots in descending size show primary → accent → surface variant.

```
┌──────────────────────────────────────────────────┐
│  ●  ●  ·   Apricot                          ✓   │  ← primary #FF6B47, accent #FFB997
│  (cream card background)                         │
├──────────────────────────────────────────────────┤
│  ●  ●  ·   Sage                                  │  ← primary #5DBE9C, accent #A8E6CF
├──────────────────────────────────────────────────┤
│  ●  ●  ·   Iris                                  │  ← primary #7C6BE6, accent #C9B6FF
├──────────────────────────────────────────────────┤
│  ●  ●  ·   Obsidian                              │  ← dark surface, purple primary
└──────────────────────────────────────────────────┘
```

- **Border**: 2 px primary color if selected, 1 px outline color otherwise.
- **Check mark**: `Icons.check_circle_rounded` in the theme's primary color, shown only for the active theme.
- **Text**: uses `palette.onSurface` so it's always legible against the card's background.

## New components

### `_ThemeTile` (private, `settings_screen.dart`)

```dart
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.themeKey, required this.isSelected, required this.onTap});
  // ...
}
```

Reads `AppPalette.byKey[themeKey]` to get colors without depending on the current active theme. This means the Obsidian card looks dark even when the app is in Apricot mode.

### `_Dot` (private, `settings_screen.dart`)

Tiny helper that renders a single colored `BoxShape.circle` at a given size, optionally with a thin border (used for the light surface-variant dot).

## Files changed

| File | Change |
|------|--------|
| [flutter_app/lib/features/settings/settings_screen.dart](../../flutter_app/lib/features/settings/settings_screen.dart) | Added `app_tokens.dart` import; replaced plain `ListTile` loop with `_ThemeTile`+`_Dot` widgets; `_pickTheme` now reads current theme key and passes `isSelected` |

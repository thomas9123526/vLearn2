# Report — 02 — Resolution-independence audit

The user asked: *is every UI element sharp + lossless on all screens, and how do we improve that without growing the APK?* This is an audit, not an implementation.

## Today (what's actually shipped)

Surveying [`flutter_app/lib`](../../flutter_app/lib) and [`flutter_app/assets/`](../../flutter_app/assets):

| Source | Resolution behavior |
|--------|---------------------|
| Material 3 `Icons.*` (~all icon usage) | Glyphs from `MaterialIcons` font — vector, infinitely scalable, no resolution loss. **Already optimal.** |
| `Theme.of(context).colorScheme.*` filled cards/buttons | Solid colors via `BoxDecoration` — vector, no resolution loss. |
| News hero `Image.network(post.image_url, ...)` | Server-side bitmap. Rendering depends on what the admin uploaded. **Risk surface.** |
| Scenario hero (planned) | Same: admin-uploaded bitmap. |
| `assets/images/` and `assets/icons/` folders | Empty today — no raster icons or images shipped. |
| Splash logo | `Icon(Icons.school_rounded, size: 96)` — vector. |
| Animations (`assets/animations/`) | Empty — task 08 covers what's missing. |

**So the current app's vector path is fine.** The non-vector path is purely admin-uploaded scenario / news images.

## Recommendations (no APK growth)

### 1. Stay on `Icons.*` for every chrome icon — already done
Don't ever ship raster PNG icons (Android `ic_launcher` is the only exception). Using a `Material Symbols` extended set adds bytes only for the glyphs you reference and stays vector.

### 2. SVG for any custom illustration / logo
If a designer hands over branded shapes (mascot, hero illustration), use [`flutter_svg`](https://pub.dev/packages/flutter_svg) — already declared in `pubspec.yaml`. SVGs are typically 1–10 KB each, vs 50–200 KB for 3×-asset PNG sets.

### 3. Server-side image responsibility for hero photos
For news + scenario hero images, the bitmap lives on the backend, not in the APK. To keep them sharp:

- Backend resizes uploads on receive (the upload endpoint added in task 12 stores the raw upload — a follow-up adds `sharp`-based resize to 1024×576 @ 80% quality WebP).
- App requests with `?w=<device_width>` query so the backend can serve the right size (also a follow-up; needs a thin image proxy or `next/image`-style query handling).
- Use `cached_network_image` (already in `pubspec.yaml`) instead of `Image.network` — it caches resized variants per device pixel ratio and avoids re-downloading.

### 4. App icon — generate from a 1024×1024 SVG source
Today's `flutter_app/android/app/src/main/res/mipmap-*/ic_launcher.png` paths haven't been touched; they ship Flutter's default launcher icon. Use [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) once to regenerate from one SVG into all density buckets. That tool runs at build time only — no runtime cost; APK size stable (PNG bucket files are ~few KB each).

### 5. Adaptive icon (Android 12+) — vector layers
The `ic_launcher_foreground` and background can be vector drawables (`<vector>` XML). Smaller than raster, sharper on any DPI. The launcher-icons tool above writes them.

### 6. AAB for Play Store reach (later)
The user explicitly wants a standalone APK — AAB is out of scope. But if that ever flips, the Android App Bundle ships per-DPI raster assets per device. AAB doesn't apply here.

## Verdict

**The app is already resolution-independent.** Material icons are vector, theme colors are vector, no raster icons ship. The only resolution risk is server-uploaded hero images — and that's handled by the backend's image processing, not by anything in the APK.

**Zero APK-growth fixes available:**
- Replace the placeholder Flutter launcher icon with a properly-rendered vector + density-bucket set (one-time tool run; no runtime cost).
- Wire `cached_network_image` for hero photos to avoid re-decode on rebuild.
- Add `?w=` query param to news/scenario image requests once the backend supports it.

## Files to touch (when the user wants to act)

- [`flutter_app/lib/features/news/widgets/news_strip.dart:69`](../../flutter_app/lib/features/news/widgets/news_strip.dart#L69)
- [`flutter_app/lib/features/news/news_list_screen.dart:104`](../../flutter_app/lib/features/news/news_list_screen.dart#L104)
- [`flutter_app/lib/features/news/news_detail_screen.dart:38`](../../flutter_app/lib/features/news/news_detail_screen.dart#L38)
- All three: swap `Image.network(url, ...)` → `CachedNetworkImage(imageUrl: url, ...)`. Same cost in APK (the dep is already declared).

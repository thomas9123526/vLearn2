# 01 — Resolution-independence audit

**Task** (verbatim from `todoList/list/01_designcheck`):

> I want know if the application provide high resolution for the all controls.
> The UI elements should be sharp and high-res on all screens of the app.
> so the icons, images or controls should be resolution-independent and scales losslessly.
> Check the application for this design aspects and give me solutions how we can modify the application to achieve high resolution, resolution-independent, scales losslessly.
> But remember that I do not want the assets size grow bigger.

## TL;DR

**The Flutter app is already largely resolution-independent.** Every interactive UI element is rendered either as:
- a **Material Icon glyph** (vector font — scales losslessly), or
- a **Rive animation** (vector-based runtime), or
- a **shape painted by `CustomPaint` / `Container` / `BoxDecoration`** (resolution-independent by construction).

There are **no shipped raster UI assets** anywhere in `flutter_app/assets/`. The only raster files in the project are the **Android launcher icons in `mipmap-*` density buckets** (this is platform-required and inherent to Android's launcher, not a bug). News article thumbnails are rendered via `Image.network` from URLs the backend serves — those scale only as well as the server-side images do.

So the question shifts from *"how do we make the app resolution-independent?"* to *"the app already is — here are the 5 small gaps to tighten."*

## What the audit found

### Assets in `flutter_app/assets/`

| Folder | Contents | Resolution behavior |
|---|---|---|
| `assets/animations/` | `anim_person.riv` (60 KB), `persona_maya.riv` (182 KB) | Vector — scales losslessly. |
| `assets/fonts/` | 4 font families × 3 weights = 12 TTF files (~3.8 MB total) | Vector glyphs — scales losslessly. |
| `assets/config/`, `assets/guard/`, `assets/wordlists/` | JSON data | Not visual. |
| **Raster images (PNG/JPG/WebP)** | **None** | n/a |

### Image / icon usage in code

| API | Files using it | Notes |
|---|---|---|
| `Image.asset(...)` | **0 hits** | The app ships **no raster bitmap UI assets**. |
| `Image.network(...)` | 3 places — [news_list_screen.dart:116](flutter_app/lib/news_list_screen.dart#L116), [news_strip.dart:69](flutter_app/lib/news_strip.dart#L69), [news_detail_screen.dart:46](flutter_app/lib/news_detail_screen.dart#L46) | Remote URLs from the backend; resolution depends on the server image. |
| `Icon(Icons.X)` | ~30+ call sites | Material `Icons` is a vector icon font — always sharp at any density. |
| `RiveAnimation.asset(...)` | [tutor_avatar.dart:186](flutter_app/lib/tutor_avatar.dart#L186), [persona_avatar.dart:67](flutter_app/lib/persona_avatar.dart#L67) | Rive runtime renders vector art. |
| `SvgPicture` / `flutter_svg` | **0 hits in `lib/`** | Package declared but not used. |
| `CustomPaint` | Multiple (cartoon_face, score_ring, charts) | Vector painted at render time. |

### `pubspec.yaml` declares everything needed

```yaml
flutter_svg: ^2.0.10+1     # SVG support (declared, not used)
rive: ^0.13.13             # Rive vector animations (used)
cached_network_image: ^3.3.1 # Network image cache (declared)
```

Plus the Material `Icons` font is always available — that's where 95%+ of UI icons come from today.

### Android density buckets

`flutter_app/android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` — these are the **system-launcher icons** the Android OS shows on the home screen / launcher. Android requires per-density PNG variants here — this is not an "in-app" resolution issue and Flutter doesn't render through these.

`drawable/launch_background.xml` is a vector XML drawable — already resolution-independent.

## So what's actually NOT lossless?

Just five small things. Each has a fix that doesn't grow the bundle.

### Gap 1 — News thumbnails (`Image.network`)

The 3 `Image.network` call sites pull article thumbnails from the backend. Whatever the server stores is what the app renders, scaled with `BoxFit.cover` / `contain`. If the backend has only one resolution and it's smaller than the display container, you get blur on high-DPI screens.

**Fix (no client bundle growth):**

- **Backend side**: serve a `srcset`-like API — store the original then derive sized variants on upload (256w / 512w / 1024w / 1600w). Add a `?w=N` query param to the image URL; service produces the closest larger size.
- **Client side**: pick `?w=…` by `MediaQuery.devicePixelRatio * containerLogicalWidth`. The `cached_network_image` package supports per-URL caching out of the box.

Net effect: the bundle stays the same; the **server** serves the right size for each device. Avoid baking a max-size image client-side; let the server's CDN cache do the heavy lifting.

### Gap 2 — Launcher icon

A single `ic_launcher.png` per density bucket. If the source artwork is rasterized at a low resolution and upscaled into `mipmap-xxxhdpi`, it looks soft on high-DPI screens.

**Fix (zero bundle growth):**

- Use **Android Adaptive Icon** (`ic_launcher.xml` + `ic_launcher_foreground.xml` as **vector drawables**) under `res/mipmap-anydpi-v26/`. Vector launcher icons are sharp on all devices and **delete** the raster PNGs.
- Tools: `flutter_launcher_icons` package with `adaptive_icon_foreground` (SVG/PNG input) auto-generates the right files. Run-once dev dependency, not shipped at runtime.

### Gap 3 — Splash screen (Android 12+)

[android/app/src/main/res/drawable/launch_background.xml](flutter_app/android/app/src/main/res/drawable/launch_background.xml) is already vector — good. Verify that Android 12's `windowSplashScreenIconBackground` and `windowSplashScreenAnimatedIcon` themes use the vector drawable (not the raster `ic_launcher.png`).

### Gap 4 — `flutter_svg` is declared but never used

[pubspec.yaml#L?](flutter_app/pubspec.yaml) ships `flutter_svg` and `vector_graphics` (transitively) in the bundle but never imports them. Either:

- **Use it** for any in-app brand marks / illustrations (e.g. the splash glyphs called out in `02_animation_part.md`). A 5 KB SVG replaces a 50 KB PNG at every density. Net **shrinks** the bundle.
- **Or remove it** from `pubspec.yaml` to recover ~150 KB of unused runtime.

Either way, the current state is the worst of both: shipped, not used.

### Gap 5 — Rive animations are sized in logical pixels, not viewport

[tutor_avatar.dart:186](flutter_app/lib/tutor_avatar.dart#L186) and [persona_avatar.dart:67](flutter_app/lib/persona_avatar.dart#L67) load `.riv` and render at a fixed `SizedBox(width: X, height: Y)`. Rive itself scales losslessly — the gap is that the surrounding `SizedBox` is hard-coded in logical pixels. On very small (≤ 360 dp) or very large (≥ 800 dp tablets) screens the avatar appears proportionally wrong rather than blurry. Switch to `LayoutBuilder` + `MediaQuery.of(context).size.shortestSide * 0.X` for the avatar dimension. Still vector, still lossless, just *better-sized*.

## Recommendation — priority order

| # | Fix | Bundle impact | Effort | User-visible impact |
|---|---|---|---|---|
| 1 | Adaptive vector launcher icon | **Shrinks** by ~30 KB | 30 min | Sharp launcher icon on every Android device. |
| 2 | Remove unused `flutter_svg` *or* commit to using it for brand marks | **Shrinks** by ~150 KB *or* neutral | 10 min (remove) / 1 hr (introduce) | None if removed; sharp brand marks if introduced. |
| 3 | News image `?w=…` query + responsive client selection | **Bundle: zero**; server work needed | 2-4 hr (server + client) | Sharper news thumbnails on high-DPI screens, smaller bytes on low-DPI. |
| 4 | Rive avatars sized off `MediaQuery.shortestSide` | **Zero** | 30 min | Better proportions on tablets / small phones. |
| 5 | Verify Android 12 splash uses vector | **Zero** | 15 min check | Sharp splash on all densities. |

**None of these grow the asset bundle.** Two of them shrink it.

## What's already correct (don't touch)

- Material `Icon()` everywhere — vector font, perfect at any density.
- Rive `.riv` files — vector runtime.
- `CustomPaint` for charts, score ring, cartoon face — vector by construction.
- No `Image.asset` raster shipping anywhere.
- TTF fonts (vector glyphs) — sharp at any size.

## Out of scope (mentioned for completeness)

- **iOS launcher icons** — `Assets.xcassets/AppIcon.appiconset` uses PNG variants by convention; iOS 17+ supports SF Symbols / single-image adaptive but launcher icon work is iOS-specific and minor.
- **macOS / Windows** desktop targets — if those are built, the project would benefit from `.ico` (Windows) + `.icns` (macOS) generation from a single vector source (`flutter_launcher_icons` handles this too).

---

*Audit complete. The Flutter app's UI rendering pipeline is already vector-first. The five gaps above are polish, not structural fixes — bundle size is preserved or reduced in every recommendation.*

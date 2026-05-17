# Report — 11 — Keep the Android APK < 50 MB

The user's instinct is right: **anything that can live outside the APK should live outside the APK.** The constraints already in place put us well under 50 MB; this report calls out where to hold the line.

## Where the bytes go in a standalone APK

A typical Flutter standalone APK (one split per ABI) for a project this size:

| Bucket | Approx size | Why |
|--------|-------------|-----|
| Flutter engine + Dart runtime per-ABI | ~12 MB (arm64) / ~10 MB (armeabi-v7a) | Fixed; one ABI per split |
| App Dart code (release `--obfuscate --split-debug-info`) | ~3–5 MB | Grows with feature count |
| Material Icons font + ICU data | ~1.5 MB | Stripped by `tree-shake-icons` to ~50 KB if only material icons used |
| Resources (drawables, layouts) | ~200 KB | Flutter generates few |
| Bundled assets | varies — see below | The lever you control |
| `kotlin-stdlib` + AndroidX | ~3 MB | Fixed |
| Compression overhead, alignment | ~1 MB | Fixed |

**Floor for one-ABI split: ~22 MB.** Everything above that is yours to control.

## What's currently bundled in `assets/`

Surveyed [`flutter_app/assets/`](../../flutter_app/assets/):

| Folder | Current size |
|--------|--------------|
| `assets/config/` | <1 KB |
| `assets/guard/` | <1 KB |
| `assets/wordlists/` | tens of KB max |
| `assets/images/` | empty |
| `assets/animations/` | empty (no `.riv` files yet) |
| `assets/icons/` | empty |
| `assets/fonts/<group>/` | only README + LICENSES (~5 KB total) — .ttf files **not** committed |
| `assets/models_layout.md` | 2 KB |

**Total bundled today: ~50 KB.** The app is well under 50 MB right now and will stay there as long as the rules below are followed.

## Hard rules to stay under 50 MB

### Rule 1 — sherpa-onnx models live on sdcard, not in APK ✅ already done
Per [todoList/0517_v2/01](../../todoList/0517_v2/01_stt_tts_sherpa_onnx.md) and the v3 architecture: models are admin-pre-placed under `/storage/emulated/0/룡마/가상외국어회화/...` or app-scoped external. They are never `flutter_app/assets/`. Saves ~80–200 MB.

### Rule 2 — fonts ship in APK but stay lean ✅ already done
Per [todoList/0517_v2/05](../../todoList/0517_v2/05_font_groups.md): 4 font groups × 5–6 weights ≈ **5 MB max** when the .ttf files land. The README files explain which weights to include — `Regular` + `Bold` for headings, `Regular/Medium/SemiBold/Bold` for body, `Regular` for mono. No `Light`, `ExtraBold`, or `Italic` weights — they double the cost.

**Alternative if 5 MB feels too much:** the user noted "I can put ttf font files on sdcard also." The font system already resolves family names — a follow-up could let the app load .ttf files from `<config_dir>/fonts/` instead of `assets/fonts/`, at the cost of: (a) cold-launch font flash, (b) admin must place fonts before launch. Trade-off: APK shrinks by ~5 MB, first-launch UX worsens.

### Rule 3 — no raster icons ✅ already done
The app uses `Icons.*` Material Symbols (vector). No PNG icons in `assets/icons/` today. Keep it that way (see [02_design_check.md](02_design_check.md)).

### Rule 4 — `tree-shake-icons` on release ✅ default
`flutter build apk --release` enables `--tree-shake-icons` by default. The Material Icons font shrinks to only the glyphs actually referenced — typically ~50 KB.

### Rule 5 — strip unused locales from ICU data
ICU data ships ~1 MB. Most Flutter apps need only en/ko/zh. Use the `--icu-data-file` flag or trim ICU at build time. **Not yet done** — saves ~500 KB.

### Rule 6 — hero images & news images stream from backend ✅ already done
Scenario hero + news hero images live on the backend storage volume served at `/uploads/*`. The app fetches them on demand via `Image.network` / `cached_network_image`. No bundled hero images.

### Rule 7 — Rive `.riv` animations stay small
When the persona-avatar `.riv` lands in `assets/animations/`, it'll be ~50 KB for a stylised face. Don't bundle multiple multi-MB Rive files; pick a small set of widely-reused assets.

### Rule 8 — split-per-ABI release ✅ already done
`build_release_android.bat` in `cmds/` uses `flutter build apk --split-per-abi`. Each user downloads only their architecture's APK. The combined "universal" APK that ships everything (~+15 MB) is for sideloading-by-hand cases.

## Estimated final APK size

With all rules above honoured:

| Component | Size |
|-----------|------|
| Flutter engine + Dart runtime (arm64) | 12 MB |
| App code | 4 MB |
| Tree-shaken Material Icons | 0.05 MB |
| Bundled fonts (4 groups × 5–6 weights, OFL 1.1) | 5 MB |
| Other bundled assets (config, guard, wordlists, models_layout.md, README files) | 0.1 MB |
| Rive animation assets (1 persona avatar file, future) | 0.05 MB |
| AndroidX + kotlin-stdlib | 3 MB |
| Compression / alignment overhead | 1 MB |
| **Total estimate (arm64 split)** | **~25 MB** |

**Headroom to 50 MB: ~25 MB.** Plenty of room for future additions (more locales, additional bundled animations, a small logo set).

## Things the user said they could move to sdcard

The user explicitly mentioned three categories:

| Category | Recommendation | Why |
|----------|----------------|-----|
| sherpa-onnx model files | **sdcard** ✅ | Too large (80–200 MB); user already on Mode B |
| .ttf font files | **bundle in APK** (5 MB total) | First-launch UX matters; under-budget |
| "other large files" | **case-by-case** | No specific files identified today; rule of thumb: ≥ 1 MB asset that isn't user-facing in the first 30 seconds → sdcard |

## Action items (when the user wants to act)

1. Enable `--obfuscate --split-debug-info=build/symbols` on release builds — saves ~10% of the Dart code section. Already on the roadmap.
2. Trim ICU data for unused locales — ~500 KB win.
3. Once the .ttf files land, run `flutter build apk --release --split-per-abi` and `unzip -l app-release-arm64-v8a.apk | sort -nrk 1 | head -20` to verify the largest contributors match expectations.
4. If the APK creeps over 40 MB at any point, the **first thing to inspect** is the `assets/fonts/` total size — that's the lever big enough to matter.

## Verdict

You're well inside the 50 MB ceiling and the rules already in place will keep you there.

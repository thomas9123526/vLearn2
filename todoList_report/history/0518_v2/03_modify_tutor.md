# 03 — Cartoon tutor face

## Ask

> On Tutor mode screen, there should be human face and behaves like real human. at least cartoon like style.

## What changed

Previously, if a persona didn't ship a `riveAsset`, the Tutor mode avatar was just the gradient circle with a big white initial. That's now replaced with a hand-painted **cartoon face** that:

- has skin, hair, brows, eyes (with pupils + catchlight), nose, mouth, cheeks
- **blinks** every ~2.6s (300ms closed window)
- moves its **mouth** in time with TTS playback in `speaking` mood
- **tilts the head** when `listening`
- **lifts the brows** when `listening`
- gently **bobs** when `idle` / `encouraging` / `praising`
- mouth shape switches (open ↔ smile ↔ frown) based on mood

Each persona gets a deterministic look — same slug → same palette + hair style + accessory — driven from a 5-palette set and the persona's `gender` field:

- `female` → long hair or bun, oval glasses sometimes
- `male` → short crop or wavy, rectangular glasses sometimes
- `neutral` → wavy default

The face still sits inside the existing gradient halo, glow, listening-ring, and floating emotion icons from `TutorAvatar` — nothing else changes about the wrapping animations. Personas that *do* ship a `riveAsset` still play the Rive file; the cartoon face is the fallback path.

## Implementation

The face is drawn with a single `CustomPainter` in a 200×200 viewBox (matching the JSX reference's coordinate system), then `Canvas.scale`-d to whatever pixel size the parent wants. Animations run in 4 separate `AnimationController`s (blink, mouth, head, brow) so we can stop/start each cleanly per mood without driving idle CPU.

Anatomy is layered like an SVG group: neck → hair back → face → cheeks → brows → eyes → glasses → nose → mouth → hair front. All scaled to the same 200×200 grid so the proportions stay coherent at any size.

## Files

| Path | Change |
|------|--------|
| [flutter_app/lib/features/conversation/widgets/cartoon_face.dart](../../flutter_app/lib/features/conversation/widgets/cartoon_face.dart) | NEW — `CartoonFace` widget + `_FacePainter` |
| [flutter_app/lib/features/conversation/widgets/tutor_avatar.dart](../../flutter_app/lib/features/conversation/widgets/tutor_avatar.dart) | Initial-fallback replaced with `CartoonFace` |

## Notes / room to grow

- The mouth right now is "open vowel" only. To support lip-sync to phonemes you'd hook the TTS service's running phoneme stream (sherpa_onnx exposes one) and switch between `aa / ee / oo / mm / ss` shapes.
- Skin tones are warm-only. If you want diversity beyond the 5-palette set, drop in more `_Palette` entries — selection is deterministic by slug hash so adding palettes is non-disruptive (existing personas keep their look, only new slugs reach into the new entries).
- The reference design also has a "thinking" mood (sealed-lip side-roll). It's not in the `TutorMood` enum yet — easy follow-up if/when the orchestrator surfaces a "thinking" state.

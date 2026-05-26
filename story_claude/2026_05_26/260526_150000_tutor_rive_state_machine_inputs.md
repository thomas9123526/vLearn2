# Tutor avatar — wire Rive state-machine inputs to TutorMood

## What was there before

`TutorAvatar` already loaded the persona's `.riv` via
`rive.RiveAnimation.asset(...)` but **never touched the state-machine
inputs** — so blink, emotion, mouth_shape, nod, shake and attention
all sat at their default values forever. The outer ring / glow /
breathing pulse animated, but the character's face was frozen.

## What changed — `tutor_avatar.dart`

Added a state-machine integration layer in `_TutorAvatarState`:

- New `onInit` callback (`_onRiveInit`) passed to
  `RiveAnimation.asset`. It:
  1. Picks the first state machine on the artboard.
  2. Builds a `StateMachineController` and attaches it.
  3. Resolves each named input with `controller.findInput<T>(...)` and
     **`is`-checks the runtime subtype** (`SMITrigger` / `SMIBool` /
     `SMINumber`) so a missing or mistyped input becomes a clean
     no-op instead of a runtime cast error. Logs a one-line summary
     of which inputs were found — easy to diagnose stub rigs.
- A random-interval blink timer (3.5–7 s) — runs independently of
  mood so the character keeps blinking while speaking / listening.
- A mouth-viseme cycler (160 ms tick) — runs only while
  `TutorMood.speaking`. Today `tutor_hiro.riv` only ships viseme 1
  ("A"), so the cycler alternates `1↔0` for a basic open/close
  talking mouth. There's a one-line swap (`_visemeAt`) to cycle
  `1..5` once E/I/O/U ship.
- `_applyMoodToRive(TutorMood)`, called from `didUpdateWidget` on
  mood change AND once at the end of `_onRiveInit` (so the first
  frame already reflects the current mood):

  | Mood          | emotion | attention | trigger | mouth     |
  |---------------|---------|-----------|---------|-----------|
  | idle          | 0       | false     | —       | stopped   |
  | speaking      | 1       | false     | —       | cycling   |
  | listening     | 0       | true      | —       | stopped   |
  | praising      | 1       | false     | `nod`   | stopped   |
  | disappointed  | 2*      | false     | `shake` | stopped   |
  | encouraging   | 1       | false     | —       | stopped   |

  `*` `emotion=2` is the "sad" slot in the design; no-op on the
  current `tutor_hiro.riv` (not built yet). The values are sent
  through anyway so it lights up the moment the rig ships.

- `dispose()` cancels both timers. The state-machine controller is
  owned by the artboard, so Rive's own teardown handles it.

## How the rest of the app already feeds it

`TutorModeView._mood` already transitions through every value used
here, driven by real interaction:

- `idle` ↔ `speaking` — toggled by `TtsService.isSpeakingStream`.
- `listening` — set on `_startRecording`, cleared on `_stopRecording`.
- `encouraging` — set when the 20-second idle timer fires and the
  app asks for a suggestion.
- `praising` / `disappointed` — wired in the enum and applied here,
  ready for the (future) scoring layer to set after each turn.

No changes were needed to `TutorModeView`.

## Stub-rig safety

`tutor_hiro.riv` currently has only `blink`, `emotion=1`,
`mouth_shape=1`. The other characters (`tutor_mei.riv` etc.) don't
exist yet — those personas continue to fall through to `CartoonFace`
via the existing `_riveAssetUsable` gate. When stub `.riv`s land
without all inputs, `findInput` returns null and every input call is
a no-op — the avatar just renders the rig's default state. No code
change needed per character.

## Verification

```text
flutter analyze lib/features/conversation/widgets/tutor_avatar.dart
  → No issues found
```

Runtime check (do on a connected emulator after rebuild):

1. Open a scenario → switch to Face mode.
2. Wait ~5 s → Hiro blinks.
3. Send a message; assistant replies → Hiro smiles and the mouth
   opens/closes through the reply (TTS-driven via
   `isSpeakingStream`).
4. Tap the mic → "attention" should kick in (no visible change on
   today's rig — it's the boolean that has no animation built yet,
   logged at init).

## User prompt (verbatim)

> And I have put .riv assets. tutor_hiro.riv.
> … (working: blink, emotion=1 smile, mouth_shape=1 "A"; not built:
> emotion 2-7, mouth_shape 2-5, nod/shake triggers, attention bool)
> So can you implement this .riv for all character animations for
> tutor mode conversation screen with various status when
> interacting with the app user.

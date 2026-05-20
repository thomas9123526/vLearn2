# 07 – Character Animation (Rive)

## 7.1 Overview

The virtual tutor character uses **Rive** (formerly Rive 2) for real-time 2D animation.
Rive was chosen over Live2D because it is:
- Free and open-source runtime (`rive` Flutter package)
- State-machine driven (perfect for idle/speaking/listening/thinking states)
- Lightweight (binary `.riv` files)
- Cross-platform (Android + Windows both supported)

---

## 7.2 Rive Asset Design Spec

Each of the 4 personas (Maya, Leo, Sofia, Theo) needs a `.riv` file.

### State Machine: `TutorStateMachine`

```
States:
  Idle        — slow breath, occasional blink
  Thinking    — eyes look up-left, subtle head tilt
  Listening   — slight lean forward, attentive expression
  Speaking    — mouth animation sync, eyebrow raises

Transitions:
  Any → Idle      (trigger: setIdle)
  Any → Thinking  (trigger: setThinking)
  Any → Listening (trigger: setListening)
  Any → Speaking  (trigger: setSpeaking)
```

### Inputs (Rive State Machine Inputs)
| Input Name | Type | Description |
|-----------|------|-------------|
| `isSpeaking` | Boolean | true while tutor is "speaking" |
| `isListening` | Boolean | true while user is "speaking" |
| `isThinking` | Boolean | true while AI is processing |
| `blinkTrigger` | Trigger | fire to blink |

### Asset Files
```
assets/rive/
├── maya.riv
├── leo.riv
├── sofia.riv
└── theo.riv
```

**For MVP:** Use a single shared generic character `.riv` with persona color tinting applied at runtime via Rive's `ColorValue` or `ShapeRenderer`.

---

## 7.3 Flutter Integration

**File:** `lib/features/conversation/rive/tutor_animation_controller.dart`

```dart
class TutorAnimationController {
  late RiveAnimationController _controller;
  late StateMachineController _stateMachine;
  
  SMIBool? _isSpeaking;
  SMIBool? _isListening;
  SMIBool? _isThinking;
  SMITrigger? _blinkTrigger;
  
  void load(Artboard artboard) { ... }
  void setState(AvatarState state) { ... }
  void dispose() { ... }
}
```

- [ ] **7.3.1** Load `.riv` asset on conversation screen init
- [ ] **7.3.2** Initialize `StateMachineController` from artboard
- [ ] **7.3.3** Bind SMI inputs to controller fields
- [ ] **7.3.4** `setState(AvatarState)` maps enum to boolean inputs

---

## 7.4 State Transitions in Conversation

**File:** `lib/features/conversation/providers/conversation_provider.dart`

```dart
// When user sends message:
avatarState.value = AvatarState.thinking;
await api.sendMessage(content);
avatarState.value = AvatarState.speaking;
// Simulate speech duration (placeholder for TTS)
await Future.delayed(Duration(seconds: 2));
avatarState.value = AvatarState.idle;

// When user presses mic button (placeholder):
avatarState.value = AvatarState.listening;
```

- [ ] **7.4.1** `avatarStateProvider` — `StateProvider<AvatarState>`
- [ ] **7.4.2** Conversation notifier updates avatar state through message lifecycle
- [ ] **7.4.3** Speaking simulation: 1 second per ~10 words in response (placeholder for TTS)
- [ ] **7.4.4** Auto-return to idle after speaking

---

## 7.5 Face Mode Stage Widget

**File:** `lib/features/conversation/widgets/tutor_stage.dart`

```dart
TutorStage({
  required Persona persona,
  required AvatarState state,
})
```

- [ ] **7.5.1** `RiveAnimation.asset()` widget with `StateMachineController`
- [ ] **7.5.2** Stage spotlight: radial gradient overlay (dark edges, bright center)
- [ ] **7.5.3** Persona name + accent color tag below character
- [ ] **7.5.4** Smooth fade when switching personas

---

## 7.6 Chat Mode Avatar Ring

**File:** `lib/shared/widgets/talking_avatar.dart`

For chat mode, use a simpler animated ring around a static persona avatar:

- [ ] **7.6.1** `AnimationController` with `repeat(reverse: true)` for speaking pulse
- [ ] **7.6.2** `RadialGradient` ring: expands/contracts based on avatar state
- [ ] **7.6.3** Scale: 1.0 (idle) → 1.05 (speaking pulse) → 1.0 (repeat)
- [ ] **7.6.4** Color: persona accent color at 60% opacity

---

## 7.7 MVP Fallback (if Rive assets not ready)

If `.riv` files are not available during initial development:

- [ ] **7.7.1** Use static persona avatar with animated border ring (chat mode)
- [ ] **7.7.2** Use Lottie animation (`lottie` package) with a generic speaking character
- [ ] **7.7.3** Flag with `// TODO: Replace with Rive asset` comment
- [ ] **7.7.4** `const bool kUseRiveAnimation = false;` feature flag in `lib/core/utils/feature_flags.dart`

---

## 7.8 Other UI Animations

| Widget | Animation | Implementation |
|--------|-----------|----------------|
| Splash floating icons | Float up/down + gentle rotation | `AnimationController` + `Transform` |
| Onboarding step transition | Slide horizontal | `PageView` + custom `PageTransition` |
| Score ring fill | Arc sweep 0→score | `CustomPainter` + `AnimationController` |
| Animated bar fill | Width 0→value | `Tween<double>` + `CurvedAnimation` |
| XP number count | Count 0→n | Custom `AnimatedNumber` widget |
| Confetti burst | Particle rain | `confetti` package |
| Message appear | Fade + slide up | `AnimatedList` with `FadeTransition` |
| Typing indicator | Scale bounce 3 dots | `AnimationController` staggered |
| Theme switch | Color cross-fade | `AnimatedTheme` |
| Tab switch | Fade | `AnimatedSwitcher` |

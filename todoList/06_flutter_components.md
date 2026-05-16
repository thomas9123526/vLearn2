# 06 – Shared Flutter Components & Design System

All components use tokens from `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`.

---

## 6.1 Avatar

**File:** `lib/shared/widgets/avatar.dart`

```dart
// Sizes: sm(28), md(40), lg(56)
Avatar({
  required String initials,   // or emoji
  required Color backgroundColor,
  required Color textColor,
  AvatarSize size = AvatarSize.md,
  VoidCallback? onTap,
})
```

- [ ] **6.1.1** Circular container with colored background
- [ ] **6.1.2** Center initials (first 2 chars of display name) or emoji
- [ ] **6.1.3** Optional tap handler with ripple effect

---

## 6.2 PersonaChip

**File:** `lib/shared/widgets/persona_chip.dart`

```dart
PersonaChip({
  required Persona persona,
  bool showStatus = false,     // online dot
})
```

- [ ] **6.2.1** Small avatar (28dp) with persona gradient background
- [ ] **6.2.2** Persona name label (12sp)
- [ ] **6.2.3** Optional green online indicator dot

---

## 6.3 TalkingAvatar

**File:** `lib/shared/widgets/talking_avatar.dart`

```dart
enum AvatarState { idle, speaking, listening, thinking }

TalkingAvatar({
  required Persona persona,
  required AvatarState state,
  double size = 120,
})
```

- [ ] **6.3.1** For chat mode: large round avatar with persona gradient
- [ ] **6.3.2** Animated ring: pulses when `speaking`, gentle glow when `listening`
- [ ] **6.3.3** State icon overlay: 💬 (speaking), 👂 (listening), 💭 (thinking)
- [ ] **6.3.4** Used in chat header + report screen

---

## 6.4 ScoreRing

**File:** `lib/shared/widgets/score_ring.dart`

```dart
ScoreRing({
  required int score,          // 0–100
  double size = 120,
  Color? trackColor,
  Color? fillColor,
  TextStyle? centerStyle,
})
```

- [ ] **6.4.1** `CustomPainter` circular arc: track + animated fill arc
- [ ] **6.4.2** Center text: score number (JetBrains Mono)
- [ ] **6.4.3** `AnimationController` from 0 → score on first paint
- [ ] **6.4.4** Color graduation: red(0-49) → amber(50-69) → green(70-100)

---

## 6.5 AnimatedBar

**File:** `lib/shared/widgets/animated_bar.dart`

```dart
AnimatedBar({
  required String label,
  required int value,          // 0–100
  required Color color,
  IconData? icon,
  Duration delay = Duration.zero,
})
```

- [ ] **6.5.1** Label row (icon + text + value number)
- [ ] **6.5.2** Linear progress bar with rounded ends
- [ ] **6.5.3** Animated fill from 0 → value with `CurvedAnimation(curve: Curves.easeOut)`
- [ ] **6.5.4** Staggered start with `delay` parameter

---

## 6.6 AnimatedNumber

**File:** `lib/shared/widgets/animated_number.dart`

```dart
AnimatedNumber({
  required int target,
  String prefix = '',
  String suffix = '',
  TextStyle? style,
  Duration duration = const Duration(milliseconds: 800),
})
```

- [ ] **6.6.1** Count from 0 to `target` over `duration`
- [ ] **6.6.2** Uses `Tween<double>` + `AnimationController`

---

## 6.7 AppButton

**File:** `lib/shared/widgets/app_button.dart`

```dart
// Variants: primary, secondary, ghost, destructive
AppButton({
  required String label,
  required VoidCallback? onPressed,
  ButtonVariant variant = ButtonVariant.primary,
  bool isLoading = false,
  bool isFullWidth = false,
  IconData? leadingIcon,
})
```

- [ ] **6.7.1** Primary: filled theme primary color, white text, 8dp radius, 12dp vertical padding
- [ ] **6.7.2** Secondary: outlined, theme primary border + text
- [ ] **6.7.3** Ghost: text-only with hover ripple
- [ ] **6.7.4** Destructive: red fill
- [ ] **6.7.5** Loading state: `CircularProgressIndicator` replaces label
- [ ] **6.7.6** Disabled state when `onPressed == null`

---

## 6.8 AppCard

**File:** `lib/shared/widgets/app_card.dart`

```dart
AppCard({
  Widget child,
  Color? backgroundColor,
  EdgeInsets? padding,
  VoidCallback? onTap,
  bool elevated = false,
})
```

- [ ] **6.8.1** Rounded corners (12dp default, 16dp elevated)
- [ ] **6.8.2** Surface color from theme
- [ ] **6.8.3** Optional shadow from `app_shadows.dart`
- [ ] **6.8.4** Tap ripple if `onTap` provided

---

## 6.9 Waveform

**File:** `lib/shared/widgets/waveform.dart`

```dart
Waveform({
  required bool isActive,   // animates when true
  Color? color,
  int barCount = 20,
})
```

- [ ] **6.9.1** Row of thin vertical bars
- [ ] **6.9.2** When active: staggered height animation (sine wave pattern)
- [ ] **6.9.3** When inactive: flat static bars (placeholder state)
- [ ] **6.9.4** Used in face-mode bottom controls

---

## 6.10 VoiceBubble (Chat Message)

**File:** `lib/shared/widgets/voice_bubble.dart`

```dart
VoiceBubble({
  required String content,
  required bool isUser,
  required Color accentColor,   // persona accent for tutor
  DateTime? timestamp,
})
```

- [ ] **6.10.1** User: right-aligned, theme primary color, white text, tail right
- [ ] **6.10.2** Tutor: left-aligned, surface color, 3dp left colored border, tail left
- [ ] **6.10.3** Max width: 80% of screen
- [ ] **6.10.4** Timestamp shown on long-press

---

## 6.11 ConfettiBurst

**File:** `lib/shared/widgets/confetti_burst.dart`

```dart
ConfettiBurst({
  required bool trigger,
  int particleCount = 60,
})
```

- [ ] **6.11.1** Use `confetti` package or custom `CustomPainter`
- [ ] **6.11.2** Trigger on `trigger == true` (one-shot animation)
- [ ] **6.11.3** Multi-color particles in theme colors
- [ ] **6.11.4** 2s duration, particles fall from top

---

## 6.12 SectionHead

**File:** `lib/shared/widgets/section_head.dart`

```dart
SectionHead({
  required String title,
  String? actionLabel,
  VoidCallback? onAction,
})
```

- [ ] **6.12.1** Row: bold title left + text action right (optional)
- [ ] **6.12.2** Typography: Plus Jakarta Sans SemiBold 16sp

---

## 6.13 AppChip

**File:** `lib/shared/widgets/app_chip.dart`

```dart
AppChip({
  required String label,
  bool selected = false,
  VoidCallback? onTap,
  Color? selectedColor,
})
```

- [ ] **6.13.1** Pill shape (24dp height, horizontal padding 12dp)
- [ ] **6.13.2** Selected: filled theme color, white text
- [ ] **6.13.3** Unselected: outlined, theme color text

---

## 6.14 SkillRadarChart

**File:** `lib/features/progress/widgets/skill_radar_chart.dart`

```dart
SkillRadarChart({
  required SkillSnapshot skills,
  double size = 240,
})
```

- [ ] **6.14.1** `fl_chart` `RadarChart` with 5 axes
- [ ] **6.14.2** Axes: Pronunciation, Fluency, Vocabulary, Grammar, Listening
- [ ] **6.14.3** Theme-colored fill with 40% opacity
- [ ] **6.14.4** Animated on first render

---

## 6.15 Navigation Components

### BottomNavBar (Mobile)
**File:** `lib/shared/widgets/bottom_nav_bar.dart`
- [ ] **6.15.1** 4 tabs: Home (🏠), Scenarios (📖), Progress (📊), Settings (⚙️)
- [ ] **6.15.2** Active tab: theme primary color + filled icon
- [ ] **6.15.3** Animated indicator dot under active tab

### Sidebar (Desktop)
**File:** `lib/shared/widgets/sidebar.dart`
- [ ] **6.15.4** 240dp wide, surface color background
- [ ] **6.15.5** App logo at top
- [ ] **6.15.6** Nav items: Home, Scenarios, Progress, Course, Settings
- [ ] **6.15.7** Active item: primary color accent left border + filled background
- [ ] **6.15.8** User profile mini-card at bottom

---

## 6.16 Dialogs

### NotificationDialog
**File:** `lib/shared/dialogs/notification_dialog.dart`
- [ ] **6.16.1** Modal bottom sheet (mobile) / dialog (desktop)
- [ ] **6.16.2** List of notifications: achievement earned, streak reminder
- [ ] **6.16.3** Clear all button

### EditProfileDialog
**File:** `lib/shared/dialogs/edit_profile_dialog.dart`
- [ ] **6.16.4** Display name text field
- [ ] **6.16.5** Avatar emoji picker (grid of emojis)
- [ ] **6.16.6** Native language dropdown
- [ ] **6.16.7** Save / Cancel buttons

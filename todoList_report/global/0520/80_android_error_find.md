# Task 80 — Android (Flutter) app: find and fix errors

## Scope
Audit `flutter_app/` for analyzer warnings / errors and obvious defects.

## Audit performed
`cd flutter_app && flutter analyze` produced 24 issues:

* 2 **warnings** (real defects)
* 22 **info** (style hints — addressed under "Quality is important")

After fixes:

```text
> flutter analyze
No issues found! (ran in 3.5s)
```

## Real bugs

### 1. `tutor_avatar.dart`: force-unwrap on a nullable asset path
```dart
final asset = widget.persona.riveAsset;   // String?
...
AppConfig.logx('assets path', asset!);    // ← crashes when null
```
Because of the `!`, the analyzer narrowed `asset` to non-null afterwards,
which then flagged downstream code:
* `unnecessary_null_comparison` on line 180 (`asset != null` was "always true")
* `dead_code` on line 200 (the `else` branch that fell back to a `CartoonFace`
  was unreachable in the analyzer's view, but at runtime the `!` would have
  thrown first — so personas without a Rive asset would crash the tutor
  avatar instead of rendering the fallback face).

**Fix:** removed the force-unwrap, used `?? '(none)'` for the log line. The
later `asset != null ? RiveAnimation : CartoonFace` branch now behaves as
intended.

## Style / quality fixes ("Quality is important")

| File | Fix |
| --- | --- |
| `core/config/app_config.dart` | Removed duplicate `package:flutter/foundation.dart` import; reordered named constructor before non-constructor declarations. |
| `core/speech/audio_recorder.dart` | `Timer(maxDuration, () => stop())` → `Timer(maxDuration, stop)`. |
| `features/conversation/widgets/chat_bubble.dart` | `Radius.circular(_radius)` made `const`. |
| `features/conversation/widgets/tutor_mode_view.dart` | Dropped `elevation: 0` (default); dropped `width: 1` on `Border.all` (default). |
| `features/home/home_screen.dart` | `EdgeInsets.symmetric(horizontal: 0, vertical: 8)` → `EdgeInsets.symmetric(vertical: 8)`. |
| `features/news/news_detail_screen.dart` | `(_, __, ___)` → `(_, _, _)` (Dart 3 multi-underscore is the new norm). |
| `features/news/news_list_screen.dart` | Two underscore-tuple fixes. |
| `features/news/news_providers.dart` | Removed redundant `page: 1, limit: 20` defaults; rewrote `StateNotifierProvider` body as `UnreadNewsCountNotifier.new` tearoff. |
| `features/news/widgets/news_strip.dart` | Three underscore-tuple fixes. |
| `features/settings/settings_screen.dart` | Removed redundant `errorContext: ErrorContext.action` default. |
| `features/conversation/widgets/tutor_avatar.dart` | Single → double-quote fix; force-unwrap fix (the real bug). |

## Verification

```text
> flutter analyze
Analyzing flutter_app...
No issues found! (ran in 3.5s)
```

Zero warnings, zero errors, zero info hints. No behaviour change apart from
the `tutor_avatar` null-safety fix, which prevents a crash for personas
that ship without a Rive asset.

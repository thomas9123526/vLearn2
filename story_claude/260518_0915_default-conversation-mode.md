# Default conversation mode — remove picker dialog

## What this task did

Removes the chat/tutor picker bottom-sheet that fired every time the user tapped a scenario. Replaces it with:
- A persisted **default mode** setting (defaults to `'face'` = Tutor) that drives `POST /conversations` directly.
- A Settings → Conversation → Default mode tile to change the default.
- The existing AppBar toggle on the conversation screen continues to work — it's the in-session switch the user asked for.

This is task 1 of [todoList/0518_v1/manual.txt](../todoList/0518_v1/manual.txt). Task 2 (speech models prep) is delivered as a separate doc: [todoList_report/0518_v1/speech_models_prep.md](../todoList_report/0518_v1/speech_models_prep.md) — out next.

## Files

| Path | Change |
|------|--------|
| [flutter_app/lib/core/providers/settings_provider.dart](../flutter_app/lib/core/providers/settings_provider.dart) | New `defaultConversationMode` field + setter + Riverpod selector |
| [flutter_app/lib/features/scenarios/scenarios_screen.dart](../flutter_app/lib/features/scenarios/scenarios_screen.dart) | Deleted `_pickMode` bottom-sheet; reads `defaultConversationModeProvider` directly |
| [flutter_app/lib/features/settings/settings_screen.dart](../flutter_app/lib/features/settings/settings_screen.dart) | New "Default mode" tile + bottom-sheet picker (Tutor / Chat with check-mark on current) |
| [flutter_app/lib/l10n/app_en.arb](../flutter_app/lib/l10n/app_en.arb) + ko/zh | 5 new keys |

## Report

[todoList_report/0518_v1/manual.md](../todoList_report/0518_v1/manual.md)

## User prompt (verbatim)

> 1. when i enter conversation screen by tap scenario, the application show dialog and ask to select chat mode or tutor mode.
> I want remove this dialog and enter automatically to conversation screen by default mode.
> set default mode as tutor mode. this settings can be changed via settings screen.
> and put toggle button on conversation screen. so if the user tap toggle button, the conversation mode changes between chat mode and tutor mode.
>
> 2. When I enter conversation screen, I get error like
> "speech models not installed.
> No manifest.json was found in the expected folder. Your administrator should drop the bundle there per deployment instructions."
> So what should i prepare to make speech models work

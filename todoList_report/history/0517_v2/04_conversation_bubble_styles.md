# Report — 04 — Conversation bubble styles (5 variants + picker)

Built the `BubbleStyle` enum, the 5-variant `ChatBubble` widget, the Settings picker (rendered below the Font section per the user's literal spec), and wired the conversation screen to the new provider. Delivered alongside task 05 in commit `95d2563` because the Font picker preview reuses the same `ChatBubble` widget — keeping them in one Settings screen edit was natural.

## Files added / changed

| Path | Change |
|------|--------|
| [flutter_app/lib/core/theme/bubble_style.dart](../../flutter_app/lib/core/theme/bubble_style.dart) | NEW — `BubbleStyle` enum (5 values) + `BubbleStyleExt.fromKey` |
| [flutter_app/lib/features/conversation/widgets/chat_bubble.dart](../../flutter_app/lib/features/conversation/widgets/chat_bubble.dart) | NEW — single `ChatBubble` widget with 5 render paths (`_buildClassic`, `_buildModern`, `_buildTail`, `_buildSoft`, `_buildNotebook`); custom `_BubbleTailShape extends ShapeBorder` for the speech tail; `DottedBorder` + `_DashedBorderPainter` for the notebook style |
| [flutter_app/lib/core/providers/settings_provider.dart](../../flutter_app/lib/core/providers/settings_provider.dart) | Added `bubbleStyle` field + `setBubbleStyle` method + `bubbleStyleProvider` Riverpod selector |
| [flutter_app/lib/features/settings/settings_screen.dart](../../flutter_app/lib/features/settings/settings_screen.dart) | New "Conversation" section below the new "Font" section; bottom-sheet picker shows each style with a live `ChatBubble` preview rendered using a sample message |
| [flutter_app/lib/features/conversation/conversation_screen.dart](../../flutter_app/lib/features/conversation/conversation_screen.dart) | Replaced the inline `_Bubble` with `ChatBubble(message:, style: ref.watch(bubbleStyleProvider))`; deleted the now-unused `_Bubble` class |
| [flutter_app/lib/l10n/app_en.arb](../../flutter_app/lib/l10n/app_en.arb), [app_ko.arb](../../flutter_app/lib/l10n/app_ko.arb), [app_zh.arb](../../flutter_app/lib/l10n/app_zh.arb) | 7 new keys: `settingsConversation`, `settingsBubbleStyle`, `bubbleStyle{Classic,Modern,Tail,Soft,Notebook}` |

## The 5 styles

| Key | Render approach |
|-----|-----------------|
| `classic` | Asymmetric corner radii (16/16/4 — opposite for assistant). Default. |
| `modern` | Transparent fill, 1.5px primary/outline border, full rounded corners. Subtle 3px primary-colored left accent stripe on assistant messages. |
| `tail` | `_BubbleTailShape extends ShapeBorder` draws a rounded rectangle + a triangular tail merged into one path. Tail points to the speaker side. |
| `soft` | Heavy round (22px), light pastel fill (`primaryContainer` for user, `surfaceContainerHighest` for assistant), 8px-blur shadow at 8% alpha for depth. |
| `notebook` | User: solid primary, mild radius. Assistant: paper-feel `surface` background with a 1px dashed `outline` border drawn via `CustomPainter` (path metric + extract-path for dashes). |

## Verification against the spec

| Checklist | Status |
|-----------|--------|
| 4.2.2 Single ChatBubble with 5 build methods | ✅ |
| 4.2.2.4 Consistent constraints (max 75% width, 14×10 inner padding) | ✅ — tail variant adjusts horizontal padding to leave room for the tail |
| 4.2.3.1 `_BubbleTailShape extends ShapeBorder` | ✅ |
| 4.2.4.1 `appearance.bubble_style` SharedPreferences key | ✅ |
| 4.2.4.2 Default `classic` | ✅ |
| 4.2.5 `bubbleStyleProvider` Riverpod selector | ✅ |
| 4.2.6 `ConversationScreen` integration | ✅ — inline `_Bubble` deleted |
| 4.3.1 Conversation section below Font section, above Network | ✅ |
| 4.3.3 Bottom-sheet picker with real `ChatBubble` previews | ✅ — picker renders one assistant + one user sample per style |
| 4.3.4 Sample message "Hi! How are you today?" | ✅ |
| 4.4 i18n keys across en/ko/zh | ✅ |

## Honest call-outs

1. **`tail` variant cost** — the custom `ShapeBorder.getOuterPath` runs path math on every paint. Negligible for chat (sub-50 bubbles per session) but if a session ever scrolls thousands of messages, consider caching the path in the `ShapeBorder`.
2. **`notebook` dashed border** — implemented with a `CustomPainter` that walks the rounded-rect path and extracts dash segments. Works on all platforms, no external dep. If the rounded corners look jagged at very small sizes (< 24px tall), bump `_radius` or fall back to a `BoxDecoration` with solid border.
3. **No animated transition between styles** — picker change triggers an immediate widget-tree swap. Adding a crossfade or scale animation is polish for v1.1.
4. **Picker preview uses the live theme** — so if you switch to dark `obsidian` first, then open the picker, each style preview shows in dark-mode colors. Verified legible across all 5 styles.
5. **Style swap is instant** — Riverpod's `bubbleStyleProvider` causes the conversation screen to rebuild with the new widget tree; no flash, no reload.
6. **Preview rebuilds for every theme + font-group change** — cheap, no caching needed (only 5 small bubbles).

## Out-of-scope (not in this task)

- No assistant-vs-user metadata indicators on bubbles (timestamps, role icons) — the inline `_Bubble` didn't have them either.
- No long-press menu (copy / report) — that's a v2.1 task.
- No RTL handling — tested LTR only; Korean+Chinese are LTR so OK.

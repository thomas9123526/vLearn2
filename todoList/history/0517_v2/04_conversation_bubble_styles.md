# 04 — Conversation bubble styles (5 variants + picker)

Replace the single hardcoded chat-bubble look from [05 §Conversation](../0516/05_flutter_screens.md) with 5 distinct named styles, expose a picker in Settings below the font section (per task 05), and persist the user's choice.

## 4.1 The five styles

| Key | Name | Look |
|-----|------|------|
| `classic` | Classic | (Current) primary-colored user bubble, surface-variant assistant bubble; asymmetric corner radii (16/16/4 vs 16/16/4 reversed); no tail |
| `modern` | Modern | Flat — transparent fill, 1.5px border in primary color (user) / outline color (assistant); full rounded corners (`radiusLg`); subtle left-edge accent stripe for assistant messages |
| `tail` | Speech tail | Filled rounded rectangle with a triangular tail pointing toward the speaker side; classic "speech bubble" feel |
| `soft` | Soft pastel | Heavily rounded (`radiusXl`), light pastel fill (user uses `primaryContainer`, assistant uses `surfaceContainerHighest`), drop shadow at 8px blur for depth |
| `notebook` | Notebook | Paper-feel — assistant bubbles render on a textured `surface` background with a thin dashed border in `outline`; user bubbles stay solid primary; mono-leaning typography hints at handwritten notes |

5 is the user's minimum; the catalog is open to growth — the picker iterates the enum.

## 4.2 Code structure

### 4.2.1 Enum + theme tokens

**File:** `flutter_app/lib/core/theme/bubble_style.dart`

```dart
enum BubbleStyle { classic, modern, tail, soft, notebook }

extension BubbleStyleLabel on BubbleStyle {
  String get displayName => switch (this) {
        BubbleStyle.classic => 'Classic',
        BubbleStyle.modern => 'Modern',
        BubbleStyle.tail => 'Speech tail',
        BubbleStyle.soft => 'Soft pastel',
        BubbleStyle.notebook => 'Notebook',
      };

  static BubbleStyle fromKey(String? k) =>
      BubbleStyle.values.firstWhere(
        (s) => s.name == k,
        orElse: () => BubbleStyle.classic,
      );
}
```

### 4.2.2 ChatBubble widget

**File:** `flutter_app/lib/features/conversation/widgets/chat_bubble.dart`

- [ ] **4.2.2.1** Single `ChatBubble({required ConversationMessage message, required BubbleStyle style, ...})` widget; switch on `style` to choose the render path
- [ ] **4.2.2.2** Five private build methods: `_buildClassic`, `_buildModern`, `_buildTail`, `_buildSoft`, `_buildNotebook`
- [ ] **4.2.2.3** Each method handles both user + assistant roles (different color/alignment)
- [ ] **4.2.2.4** Constraints stay consistent across styles: max width = 75% of screen, vertical padding 4px, inner padding 14×10

### 4.2.3 Tail rendering

The `tail` variant needs a custom `ShapeBorder` or `CustomPainter` to draw the triangular tail.

- [ ] **4.2.3.1** `BubbleTailShape extends ShapeBorder` — overrides `getOuterPath` to draw the rectangle + triangle merged into one path
- [ ] **4.2.3.2** Tail position depends on `isUser` (right side for user, left for assistant)
- [ ] **4.2.3.3** Test on RTL locales if/when they're added (Korean is LTR, Chinese is LTR, so OK for v1)

### 4.2.4 Settings persistence

- [ ] **4.2.4.1** New key `appearance.bubble_style` (string enum) in `AppSettingsState`
- [ ] **4.2.4.2** Default `classic`
- [ ] **4.2.4.3** `AppSettingsNotifier.setBubbleStyle(BubbleStyle)` writes to SharedPreferences

### 4.2.5 Riverpod selector

```dart
final bubbleStyleProvider = Provider<BubbleStyle>(
  (ref) => BubbleStyleLabel.fromKey(
    ref.watch(appSettingsProvider.select((s) => s.bubbleStyle)),
  ),
);
```

### 4.2.6 ConversationScreen integration

- [ ] **4.2.6.1** Replace the inline `_Bubble` widget in `conversation_screen.dart` with `ChatBubble(message: m, style: ref.watch(bubbleStyleProvider))`
- [ ] **4.2.6.2** Style swap is instant — no rebuild flash because we're just changing the widget tree per Riverpod state

## 4.3 Settings screen — picker UI

Per the user's request: bubble picker sits **below** the font section (Task 05).

- [ ] **4.3.1** New section header "Conversation" in `settings_screen.dart`, below the (new) "Font" section, above "Network"
- [ ] **4.3.2** Tile: "Bubble style" with the current selection name as subtitle; chevron right
- [ ] **4.3.3** Tap → opens a bottom-sheet picker with **visual previews** of each style (rendered using the actual `ChatBubble` widget with a sample message). Tap any preview to select.
- [ ] **4.3.4** Sample message: `{ role: 'assistant', content: 'Hi! How are you today?' }` — short, language-neutral
- [ ] **4.3.5** Selected state shown via a check icon overlay

## 4.4 i18n

Add to `app_en.arb` / `app_ko.arb` / `app_zh.arb`:
- `settingsBubbleStyle` (label "Bubble style")
- `bubbleStyleClassic`, `bubbleStyleModern`, `bubbleStyleTail`, `bubbleStyleSoft`, `bubbleStyleNotebook`

## 4.5 Verification

- [ ] **4.5.1** Pick each style → conversation screen reflects immediately on next render
- [ ] **4.5.2** Setting persists across app restarts
- [ ] **4.5.3** Long-message wrapping looks reasonable on all 5 styles
- [ ] **4.5.4** Light theme + dark (obsidian) theme: every style is legible — especially `notebook` (paper feel) and `modern` (border-only) need contrast checks in dark mode

## 4.6 Honest call-outs

1. **`notebook` style is a vibe choice.** If it doesn't look right with the typography from Task 05's font groups, it might need its own subtle texture asset. Start without; add a faint paper SVG if needed.
2. **`tail` variant** has a slightly higher render cost (the custom `ShapeBorder` does path math per frame). Negligible for chat — sub-50 bubbles per session.
3. **No animation when switching styles.** A crossfade or scale on switch would be nice polish but adds animation orchestration. Keep simple for v1.
4. **Style preview in the picker** rebuilds for every theme + font-group change. Cheap; no caching needed.

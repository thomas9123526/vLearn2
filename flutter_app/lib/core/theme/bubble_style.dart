/// Five named chat-bubble looks for the conversation screen.
///
/// The picker in Settings → Appearance writes the chosen `.name` string to
/// SharedPreferences; [BubbleStyleExt.fromKey] resolves it back.
enum BubbleStyle { classic, modern, tail, soft, notebook }

extension BubbleStyleExt on BubbleStyle {
  String get displayName => switch (this) {
        BubbleStyle.classic => 'Classic',
        BubbleStyle.modern => 'Modern',
        BubbleStyle.tail => 'Speech tail',
        BubbleStyle.soft => 'Soft pastel',
        BubbleStyle.notebook => 'Notebook',
      };

  String get description => switch (this) {
        BubbleStyle.classic => 'Asymmetric rounded corners',
        BubbleStyle.modern => 'Flat, outline-only',
        BubbleStyle.tail => 'Triangular speech tail',
        BubbleStyle.soft => 'Heavy round, soft shadow',
        BubbleStyle.notebook => 'Paper feel, dashed border',
      };

  static BubbleStyle fromKey(String? k) =>
      BubbleStyle.values.firstWhere(
        (s) => s.name == k,
        orElse: () => BubbleStyle.classic,
      );
}

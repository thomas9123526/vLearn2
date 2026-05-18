import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bubble_style.dart';
import '../theme/font_group.dart';

/// Lightweight settings cache backed by SharedPreferences.
/// Drift's [AppSettings] table is the durable store; this provider exposes
/// a synchronous read for hot-path code (e.g. the compression interceptor).
class AppSettingsState {
  const AppSettingsState({
    required this.theme,
    required this.uiLanguage,
    required this.compressionEnabled,
    required this.fontGroup,
    required this.bubbleStyle,
    required this.textOnlyAcknowledged,
    required this.defaultConversationMode,
  });

  final String theme;
  final String uiLanguage;
  final bool compressionEnabled;
  final String fontGroup;
  final String bubbleStyle;

  /// `'face'` (tutor) or `'chat'`. Determines which mode a new conversation
  /// session starts in — replaces the bottom-sheet picker that used to fire
  /// from the scenarios screen. Toggled inside the conversation screen via
  /// the AppBar icon button without ending the session.
  final String defaultConversationMode;

  /// `true` once the user dismissed the "Models not installed" setup screen
  /// with the "Continue in text-only mode" button. The router uses this to
  /// stop forcing the setup screen on every cold boot. Resets back to false
  /// once a valid model bundle is detected (see [AppSettingsNotifier.snap]).
  final bool textOnlyAcknowledged;

  AppSettingsState copyWith({
    String? theme,
    String? uiLanguage,
    bool? compressionEnabled,
    String? fontGroup,
    String? bubbleStyle,
    bool? textOnlyAcknowledged,
    String? defaultConversationMode,
  }) => AppSettingsState(
        theme: theme ?? this.theme,
        uiLanguage: uiLanguage ?? this.uiLanguage,
        compressionEnabled: compressionEnabled ?? this.compressionEnabled,
        fontGroup: fontGroup ?? this.fontGroup,
        bubbleStyle: bubbleStyle ?? this.bubbleStyle,
        textOnlyAcknowledged: textOnlyAcknowledged ?? this.textOnlyAcknowledged,
        defaultConversationMode:
            defaultConversationMode ?? this.defaultConversationMode,
      );

  static const initial = AppSettingsState(
    theme: 'apricot',
    uiLanguage: 'en',
    compressionEnabled: true,
    fontGroup: 'editorial',
    bubbleStyle: 'classic',
    textOnlyAcknowledged: false,
    defaultConversationMode: 'face',
  );
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(AppSettingsState.initial) {
    _load();
  }

  static const _kTheme = 'settings.theme';
  static const _kLanguage = 'settings.ui_language';
  static const _kCompression = 'settings.compression_enabled';
  static const _kFontGroup = 'appearance.font_group';
  static const _kBubbleStyle = 'appearance.bubble_style';
  static const _kTextOnly = 'speech.text_only_acknowledged';
  static const _kDefaultMode = 'conversation.default_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettingsState(
      theme: prefs.getString(_kTheme) ?? AppSettingsState.initial.theme,
      uiLanguage: prefs.getString(_kLanguage) ?? AppSettingsState.initial.uiLanguage,
      compressionEnabled: prefs.getBool(_kCompression) ?? AppSettingsState.initial.compressionEnabled,
      fontGroup: prefs.getString(_kFontGroup) ?? AppSettingsState.initial.fontGroup,
      bubbleStyle: prefs.getString(_kBubbleStyle) ?? AppSettingsState.initial.bubbleStyle,
      textOnlyAcknowledged:
          prefs.getBool(_kTextOnly) ?? AppSettingsState.initial.textOnlyAcknowledged,
      defaultConversationMode: prefs.getString(_kDefaultMode) ??
          AppSettingsState.initial.defaultConversationMode,
    );
  }

  /// Persist the user's "I'll use the app without speech" choice. Cleared
  /// by [resetTextOnlyAck] once a valid model bundle is detected.
  Future<void> acknowledgeTextOnly() async {
    state = state.copyWith(textOnlyAcknowledged: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTextOnly, true);
  }

  Future<void> resetTextOnlyAck() async {
    if (!state.textOnlyAcknowledged) return;
    state = state.copyWith(textOnlyAcknowledged: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTextOnly, false);
  }

  Future<void> setTheme(String theme) async {
    state = state.copyWith(theme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, theme);
  }

  Future<void> setUiLanguage(String lang) async {
    state = state.copyWith(uiLanguage: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, lang);
  }

  Future<void> setCompressionEnabled(bool enabled) async {
    state = state.copyWith(compressionEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompression, enabled);
  }

  Future<void> setFontGroup(FontGroup group) async {
    state = state.copyWith(fontGroup: group.name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontGroup, group.name);
  }

  Future<void> setBubbleStyle(BubbleStyle style) async {
    state = state.copyWith(bubbleStyle: style.name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBubbleStyle, style.name);
  }

  /// `'face'` (tutor) or `'chat'`. Anything else is normalised to `'face'`.
  Future<void> setDefaultConversationMode(String mode) async {
    final normalised = (mode == 'chat') ? 'chat' : 'face';
    state = state.copyWith(defaultConversationMode: normalised);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultMode, normalised);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (_) => AppSettingsNotifier(),
);

/// Convenience selectors for hot-path code that wants a synchronous read
/// without subscribing to the whole settings object.
final compressionEnabledProvider = Provider<bool>(
  (ref) => ref.watch(appSettingsProvider.select((s) => s.compressionEnabled)),
);

final themeKeyProvider = Provider<String>(
  (ref) => ref.watch(appSettingsProvider.select((s) => s.theme)),
);

final localeProvider = Provider<Locale>(
  (ref) => Locale(ref.watch(appSettingsProvider.select((s) => s.uiLanguage))),
);

final fontGroupProvider = Provider<FontGroup>(
  (ref) => FontGroupExt.fromKey(
    ref.watch(appSettingsProvider.select((s) => s.fontGroup)),
  ),
);

final bubbleStyleProvider = Provider<BubbleStyle>(
  (ref) => BubbleStyleExt.fromKey(
    ref.watch(appSettingsProvider.select((s) => s.bubbleStyle)),
  ),
);

/// The mode a new conversation session starts in (`'face'` or `'chat'`).
final defaultConversationModeProvider = Provider<String>(
  (ref) =>
      ref.watch(appSettingsProvider.select((s) => s.defaultConversationMode)),
);

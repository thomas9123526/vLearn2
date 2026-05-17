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
  });

  final String theme;
  final String uiLanguage;
  final bool compressionEnabled;
  final String fontGroup;
  final String bubbleStyle;

  AppSettingsState copyWith({
    String? theme,
    String? uiLanguage,
    bool? compressionEnabled,
    String? fontGroup,
    String? bubbleStyle,
  }) => AppSettingsState(
        theme: theme ?? this.theme,
        uiLanguage: uiLanguage ?? this.uiLanguage,
        compressionEnabled: compressionEnabled ?? this.compressionEnabled,
        fontGroup: fontGroup ?? this.fontGroup,
        bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      );

  static const initial = AppSettingsState(
    theme: 'apricot',
    uiLanguage: 'en',
    compressionEnabled: true,
    fontGroup: 'editorial',
    bubbleStyle: 'classic',
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

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettingsState(
      theme: prefs.getString(_kTheme) ?? AppSettingsState.initial.theme,
      uiLanguage: prefs.getString(_kLanguage) ?? AppSettingsState.initial.uiLanguage,
      compressionEnabled: prefs.getBool(_kCompression) ?? AppSettingsState.initial.compressionEnabled,
      fontGroup: prefs.getString(_kFontGroup) ?? AppSettingsState.initial.fontGroup,
      bubbleStyle: prefs.getString(_kBubbleStyle) ?? AppSettingsState.initial.bubbleStyle,
    );
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

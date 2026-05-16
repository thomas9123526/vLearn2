import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight settings cache backed by SharedPreferences.
/// Drift's [AppSettings] table is the durable store; this provider exposes
/// a synchronous read for hot-path code (e.g. the compression interceptor).
class AppSettingsState {
  const AppSettingsState({
    required this.theme,
    required this.uiLanguage,
    required this.compressionEnabled,
  });

  final String theme;
  final String uiLanguage;
  final bool compressionEnabled;

  AppSettingsState copyWith({
    String? theme,
    String? uiLanguage,
    bool? compressionEnabled,
  }) => AppSettingsState(
        theme: theme ?? this.theme,
        uiLanguage: uiLanguage ?? this.uiLanguage,
        compressionEnabled: compressionEnabled ?? this.compressionEnabled,
      );

  static const initial = AppSettingsState(
    theme: 'apricot',
    uiLanguage: 'en',
    compressionEnabled: true,
  );
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(AppSettingsState.initial) {
    _load();
  }

  static const _kTheme = 'settings.theme';
  static const _kLanguage = 'settings.ui_language';
  static const _kCompression = 'settings.compression_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettingsState(
      theme: prefs.getString(_kTheme) ?? AppSettingsState.initial.theme,
      uiLanguage: prefs.getString(_kLanguage) ?? AppSettingsState.initial.uiLanguage,
      compressionEnabled: prefs.getBool(_kCompression) ?? AppSettingsState.initial.compressionEnabled,
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

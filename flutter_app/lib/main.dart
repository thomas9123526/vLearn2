// vLearn2 — entry point.
//
// Architecture summary:
//   * State: Riverpod. Every cross-screen thing (auth, settings, model
//     registry, API clients) lives behind a Provider so widgets stay
//     stateless and tests can override.
//   * Navigation: go_router. The single source of truth is
//     [routerProvider] (see core/router/app_router.dart) which wires auth
//     redirects, the speech-models gate, and per-route deeplinks.
//   * Theming: built per-(theme key × font group) pair via [AppTheme.build]
//     and rebuilt automatically when either changes.
//
// The runApp call uses `UncontrolledProviderScope` so we can warm one
// provider (the on-disk config) before the first widget tree builds. This
// avoids a flash of fallback config during cold start.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'core/config/app_config.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Requests storage permissions so the app can create the public
/// 룡마/가상외국어회화 config folder under `/storage/emulated/0/`.
///
/// Two paths, depending on Android version:
///   * **Android ≤ 12**: `READ_EXTERNAL_STORAGE` + `WRITE_EXTERNAL_STORAGE`
///     (`Permission.storage`). Standard runtime prompt.
///   * **Android 11+ (preferred on 13+)**: `MANAGE_EXTERNAL_STORAGE`.
///     Special permission — opens a Settings page the user must toggle.
///
/// Both are requested; whichever the OS honours grants the necessary write
/// access. Manifest `maxSdkVersion` guards keep the legacy entries from
/// being requested on Androids where they're a no-op.
Future<void> _requestAndroidStorage() async {
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // sherpa_onnx requires its FFI bindings to be wired up before any native
  // object (OfflineTts / OnlineRecognizer / OfflineRecognizer) is constructed.
  // Skipping this raises "Please initialize sherpa-onnx first" the moment a
  // speech service tries to instantiate the engine.
  sherpa_onnx.initBindings();
  // Request external storage permission before reading the config file so
  // that ConfigFileService can create the public 룡마/가상외국어회화 directory.
  if (Platform.isAndroid) await _requestAndroidStorage();
  // Resolve the on-disk config (creating it with defaults if missing) so the
  // Dio client and any other config-dependent provider sees the real values
  // on its first read. Without this, the first request would race the file
  // I/O and use AppConfig.defaults briefly.
  final container = ProviderContainer();
  try {
    await container.read(appConfigProvider.future);
  } catch (_) {
    // Treat unreadable config as "use defaults" — the service itself rewrites
    // a broken file on the next save, so this never leaves the app stuck.
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VLearn2App(),
    ),
  );
}

/// Root widget. Reads the theme key, font group, locale, and router from
/// providers so changes in any of them rebuild the MaterialApp once.
class VLearn2App extends ConsumerWidget {
  const VLearn2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeKey = ref.watch(themeKeyProvider);
    final fontGroup = ref.watch(fontGroupProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Virtual Foreign Language',
      debugShowCheckedModeBanner: false,
      // `themeKey + fontGroup` are the two ColorScheme/typography inputs;
      // AppTheme.build memoizes the result for the current pair.
      theme: AppTheme.build(themeKey, fontGroup),
      locale: locale,
      // Locales the app's ARB files cover. ICU 73's fallback rules pick
      // `en` for any unsupported locale automatically.
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

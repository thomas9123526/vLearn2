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
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:rive/rive.dart' as rive;
import 'package:shared_preferences/shared_preferences.dart';
import 'core/cache/cache_seeder.dart';
import 'core/config/layout_config_provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/cache/cache_store.dart';
import 'core/config/app_config.dart';
import 'core/config/rive_render_config.dart';
import 'core/license/license_state_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

const _kRequiredPackage = 'com.ryongma.cid';
const _kAppCheckChannel = MethodChannel('com.vlearn2/app_check');

/// Checks whether [_kRequiredPackage] is installed. If not, swaps in a
/// blocking screen that tells the user to install it and exits on confirm.
Future<void> _checkRequiredApp() async {
  bool installed = false;
  try {
    installed = await _kAppCheckChannel.invokeMethod<bool>(
          'isInstalled',
          {'packageName': _kRequiredPackage},
        ) ??
        false;
  } catch (_) {
    installed = false;
  }
  if (!installed) {
    runApp(const _RequiredAppMissingScreen());
    // Prevent the rest of main() from running.
    await Future<void>.delayed(const Duration(days: 9999));
  }
}

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
  // rive 0.14 moved to a native renderer (rive_native). RiveNative.init()
  // loads the platform library + initialises the font subsystem; without
  // it RiveWidget renders nothing and Factory.rive throws.
  await rive.RiveNative.init();
  // Request external storage permission before reading the config file so
  // that ConfigFileService can create the public 룡마/가상외국어회화 directory.
  if (Platform.isAndroid) {
    await _requestAndroidStorage();
    await _checkRequiredApp();
  }
  // Resolve the on-disk config (creating it with defaults if missing) so the
  // Dio client and any other config-dependent provider sees the real values
  // on its first read. Without this, the first request would race the file
  // I/O and use AppConfig.defaults briefly.
  final container = ProviderContainer();
  try {
    final cfg = await container.read(appConfigProvider.future);
    // Apply the optional Rive renderer override before the first avatar
    // builds. Null leaves the per-platform default (GPU off on the VMware
    // VM, on elsewhere) in place.
    if (cfg.riveUseGpu != null) {
      RiveRenderConfig.useGpu = cfg.riveUseGpu!;
    }
  } catch (_) {
    // Treat unreadable config as "use defaults" — the service itself rewrites
    // a broken file on the next save, so this never leaves the app stuck.
  }
  // Apply the admin-configured language (app.default_language) on every
  // launch. This lets the admin control the UI language from the panel;
  // it overrides any language the user previously stored in preferences.
  // If the key is absent or the server is unreachable, the stored preference
  // (or English) is kept.
  try {
    await container.read(layoutConfigProvider.notifier).refresh();
    const supportedLangs = {'en', 'zh', 'ru', 'ko'};
    final lang = container
        .read(layoutConfigProvider)
        .valueOrNull
        ?.get<String>('app.default_language');
    if (lang != null && supportedLangs.contains(lang)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings.ui_language', lang);
    }
  } catch (_) {
    // Language sync is best-effort; keep whatever is stored locally.
  }
  // Pre-seed the local SQLite cache from bundled asset JSON files so the
  // scenario/category lists show instantly on first launch without a network
  // round-trip. No-op on subsequent launches (cache already populated).
  await CacheSeeder.seedIfEmpty(container.read(cacheStoreProvider));
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VLearn2App(),
    ),
  );
}

/// Shown when [_kRequiredPackage] is not installed. Blocks app startup and
/// exits on user confirmation.
class _RequiredAppMissingScreen extends StatelessWidget {
  const _RequiredAppMissingScreen();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'Required app not installed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Please install the CID app (com.ryongma.cid) before using this application.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: SystemNavigator.pop,
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

    // Instantiate the license state provider at app start so the
    // auto-verify-on-signedIn listener inside it is already wired
    // before the user reaches the home screen. The value itself is
    // unused here -- the License screen and admin-side data are the
    // real consumers.
    ref.watch(licenseStateProvider);

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
        Locale('ru'),
        Locale('ko'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

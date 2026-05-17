import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: AppTheme.build(themeKey, fontGroup),
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
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

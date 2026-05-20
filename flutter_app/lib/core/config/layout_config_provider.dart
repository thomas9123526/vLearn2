import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class LayoutConfig {
  const LayoutConfig({required this.flags, this.fetchedAt});
  final Map<String, dynamic> flags;
  final DateTime? fetchedAt;

  bool isVisible(String key, {bool fallback = true}) {
    final v = flags[key];
    return v is bool ? v : fallback;
  }

  T? get<T>(String key) {
    final v = flags[key];
    return v is T ? v : null;
  }
}

class LayoutConfigNotifier extends AsyncNotifier<LayoutConfig> {
  static const _bakedDefaults = <String, dynamic>{
    // Mirror of the §12.6 catalog defaults — used when the server is unreachable
    'evaluation.radar.skills.pronunciation': true,
    'evaluation.radar.skills.fluency': true,
    'evaluation.radar.skills.vocabulary': true,
    'evaluation.radar.skills.grammar': true,
    'evaluation.radar.skills.listening': true,
    'home.streak_banner': true,
    'home.continue_course': true,
    'home.recommended_scenarios': true,
    'home.notification_bell': true,
    'progress.skill_radar': true,
    'progress.weekly_chart': true,
    'progress.achievements': true,
    'conversation.mode_toggle': true,
    'conversation.history': true,
    'settings.theme_selector': true,
    'settings.tutor_carousel': true,
    'tabs.home': true,
    'tabs.scenarios': true,
    'tabs.progress': true,
    'tabs.settings': true,
  };

  @override
  Future<LayoutConfig> build() async {
    // Start with baked defaults; refresh from server in the background.
    final defaults = LayoutConfig(
      flags: Map.of(_bakedDefaults),
      fetchedAt: DateTime.now(),
    );
    // Best-effort refresh — never throws
    Future<void>(() async {
      try {
        final dio = ref.read(apiClientProvider);
        final res = await dio.get<Map<String, dynamic>>('/app-config');
        final flags = (res.data?['flags'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        state = AsyncValue.data(LayoutConfig(
          flags: {..._bakedDefaults, ...flags},
          fetchedAt: DateTime.now(),
        ));
      } on DioException {
        // Keep defaults
      } on Object {
        // Keep defaults
      }
    });
    return defaults;
  }
}

final layoutConfigProvider =
    AsyncNotifierProvider<LayoutConfigNotifier, LayoutConfig>(LayoutConfigNotifier.new);

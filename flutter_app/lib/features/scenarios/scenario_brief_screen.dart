import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/app_apis.dart';
import '../../core/config/app_config.dart';
import '../../core/config/layout_config_provider.dart';
import '../../core/errors/polite_error.dart';
import '../../core/models/models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/speech/speech_service.dart';
import '../settings/settings_screen.dart';

final _scenarioProvider =
    FutureProvider.family<Scenario, String>((ref, idOrSlug) async {
  final raw = await ref.read(scenariosApiProvider).get(idOrSlug);
  return Scenario.fromJson(raw);
});

final _personasProvider = FutureProvider<List<Persona>>((ref) async {
  final raw = await ref.read(personasApiProvider).list();
  return raw.map(Persona.fromJson).toList();
});

/// Returns the most recent active session for this scenario, or null.
final _activeSessionProvider =
    FutureProvider.family<ConversationSession?, String>((ref, scenarioId) async {
  final raw = await ref.read(conversationsApiProvider).listSessions(
        scenarioId: scenarioId,
        status: 'active',
        limit: 1,
      );
  if (raw.isEmpty) return null;
  return ConversationSession.fromJson(raw.first);
});

/// Intermediate "brief" between picking a topic on the scenarios screen and
/// actually starting the conversation. Matches design_handoff_freetalk
/// `screens.md` §5 — header, hero card, roles, twist, objectives,
/// persona pairing, level picker, sticky bottom dock.
class ScenarioBriefScreen extends ConsumerStatefulWidget {
  const ScenarioBriefScreen({required this.scenarioId, super.key});

  final String scenarioId;

  @override
  ConsumerState<ScenarioBriefScreen> createState() => _ScenarioBriefScreenState();
}

class _ScenarioBriefScreenState extends ConsumerState<ScenarioBriefScreen> {
  @override
  Widget build(BuildContext context) {
    final scenarioAsync = ref.watch(_scenarioProvider(widget.scenarioId));
    final personasAsync = ref.watch(_personasProvider);
    final activeSessionAsync = ref.watch(_activeSessionProvider(widget.scenarioId));
    final locale = ref.watch(localeProvider).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider).user;
    final uploadsOrigin = _resolveUploadsOrigin();
    final layoutConfig = ref.watch(layoutConfigProvider).valueOrNull;
    final showBgImage    = layoutConfig?.isVisible('scenario_detail.background_image') ?? true;
    final showDescription = layoutConfig?.isVisible('scenario_detail.description') ?? true;
    final showObjectives  = layoutConfig?.isVisible('scenario_detail.objectives') ?? true;
    final showKeyPhrases  = layoutConfig?.isVisible('scenario_detail.key_phrases') ?? true;
    final showCefrPill    = layoutConfig?.isVisible('scenario_detail.cefr_pill') ?? true;
    final showXpPill      = layoutConfig?.isVisible('scenario_detail.xp_pill') ?? true;

    final activeSession = activeSessionAsync.asData?.value;
    final speechReady = ref.watch(speechReadyProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: scenarioAsync.maybeWhen(
          data: (s) => Text(
            'BRIEF · ${s.category.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'EditorialMono',
              fontSize: 12,
              letterSpacing: 1.4,
            ),
          ),
          orElse: () => const Text(''),
        ),
      ),
      body: scenarioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logRawError('scenario_brief.load', e, st);
          return PoliteErrorCenter(
            error: e,
            context: ErrorContext.loadDetail,
            onRetry: () => ref.invalidate(_scenarioProvider(widget.scenarioId)),
          );
        },
        data: (scenario) {
          final activePersona = personasAsync.asData?.value.firstWhere(
            (p) => p.id == user?.activePersonaId,
            orElse: () => personasAsync.asData!.value.isNotEmpty
                ? personasAsync.asData!.value.first
                : const Persona(
                    id: '',
                    slug: '',
                    name: 'Tutor',
                    accent: 'neutral',
                    style: 'friendly',
                    specialties: [],
                    gradientFrom: '#FF6B47',
                    gradientTo: '#FFB997',
                  ),
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              if (activeSession != null) ...[
                _ContinueBanner(session: activeSession),
                const SizedBox(height: 16),
              ],
              _HeroCard(
                scenario: scenario,
                locale: locale,
                uploadsOrigin: uploadsOrigin,
                showBackgroundImage: showBgImage,
                showDescription: showDescription,
                showCefrPill: showCefrPill,
                showXpPill: showXpPill,
              ),
              const SizedBox(height: 20),
              _RolesRow(scenario: scenario, persona: activePersona),
              const SizedBox(height: 20),
              _TwistBanner(scenario: scenario, locale: locale),
              if (showObjectives) ...[
                const SizedBox(height: 20),
                const _SectionHeader(text: 'Objectives'),
                const SizedBox(height: 8),
                _Objectives(scenario: scenario),
              ],
              if (showKeyPhrases) ...[
                const SizedBox(height: 20),
                const _SectionHeader(text: 'Phrases worth stealing'),
                const SizedBox(height: 8),
                _Phrases(scenario: scenario),
              ],
              const SizedBox(height: 20),
              _PersonaPairing(
                persona: activePersona,
                scheme: scheme,
                onChange: () => pickActivePersona(context, ref),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: scenarioAsync.maybeWhen(
        data: (scenario) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: activeSession != null
                ? _ContinueDock(
                    scenario: scenario,
                    activeSession: activeSession,
                    onContinue: () => context.pushReplacement(
                      AppRoute.conversation(activeSession.id),
                    ),
                    onStartFresh: () =>
                        _startFresh(context, scenario, activeSession),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Back to topics'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: speechReady
                              ? () => _startSession(context, scenario)
                              : null,
                          icon: speechReady
                              ? const Icon(Icons.play_arrow)
                              : const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white70,
                                  ),
                                ),
                          label: Text(speechReady
                              ? scenario.timeConstrained
                                  ? 'Start speaking (${scenario.estimatedMinutes}m)'
                                  : 'Start speaking'
                              : 'Loading engines…'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  /// Computes the origin that /uploads/... paths should be resolved against.
  /// Uses the actual loaded config (or env override), not the hardcoded defaults.
  String _resolveUploadsOrigin() {
    const envOverride = String.fromEnvironment('API_BASE_URL');
    final config = ref.read(appConfigProvider).asData?.value ?? AppConfig.defaults;
    final base = envOverride.isNotEmpty ? envOverride : config.backendBaseUrl;
    String strip(String s, String suffix) {
      final i = s.indexOf(suffix);
      return i > 0 ? s.substring(0, i) : s;
    }
    return strip(strip(base, '/api'), '/vfls');
  }

  Future<void> _startFresh(
    BuildContext context,
    Scenario scenario,
    ConversationSession activeSession,
  ) async {
    try {
      await ref
          .read(conversationsApiProvider)
          .endSession(activeSession.id, status: 'abandoned');
      ref.invalidate(_activeSessionProvider(widget.scenarioId));
    } catch (_) {
      // If abandon fails, proceed anyway — the session will stay active on the
      // server but the user wanted to start fresh.
    }
    if (context.mounted) {
      await _startSession(context, scenario);
    }
  }

  Future<void> _startSession(
    BuildContext context,
    Scenario scenario,
  ) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    String personaId = user.activePersonaId ?? '';
    if (personaId.isEmpty) {
      final personas = await ref.read(_personasProvider.future);
      if (personas.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No personas available')),
          );
        }
        return;
      }
      personaId = personas.first.id;
    }
    final mode = ref.read(defaultConversationModeProvider);
    try {
      final session = await ref.read(conversationsApiProvider).startSession(
            personaId: personaId,
            scenarioId: scenario.id,
            mode: mode,
            cefrLevel: scenario.cefrLevel,
          );
      final sessionId = session['id'] as String;
      if (context.mounted) {
        context.pushReplacement(AppRoute.conversation(sessionId));
      }
    } on Exception catch (e, st) {
      if (context.mounted) {
        showPoliteErrorSnack(
          context,
          e,
          tag: 'scenario_brief.start',
          stack: st,
        );
      }
    }
  }
}

class _ContinueBanner extends StatelessWidget {
  const _ContinueBanner({required this.session});
  final ConversationSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final turns = session.turnCount;
    final ago = _timeAgo(session.startedAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: scheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unfinished conversation',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$turns ${turns == 1 ? 'turn' : 'turns'} · started $ago',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ContinueDock extends StatelessWidget {
  const _ContinueDock({
    required this.scenario,
    required this.activeSession,
    required this.onContinue,
    required this.onStartFresh,
  });
  final Scenario scenario;
  final ConversationSession activeSession;
  final VoidCallback onContinue;
  final VoidCallback onStartFresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Continue conversation'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onStartFresh,
                child: Text(scenario.timeConstrained
                    ? 'Start fresh (${scenario.estimatedMinutes}m)'
                    : 'Start fresh'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.scenario,
    required this.locale,
    required this.uploadsOrigin,
    this.showBackgroundImage = true,
    this.showDescription = true,
    this.showCefrPill = true,
    this.showXpPill = true,
  });
  final Scenario scenario;
  final String locale;
  final String uploadsOrigin;
  final bool showBackgroundImage;
  final bool showDescription;
  final bool showCefrPill;
  final bool showXpPill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levelLabels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final lvl = scenario.cefrLevel;
    final levelLabel = (lvl != null && lvl >= 1 && lvl <= 6)
        ? levelLabels[lvl - 1]
        : '—';
    // When the admin uploaded a scenario image, drop it in above the
    // gradient hero. /uploads/... URLs are absolute against the API
    // origin — Dio's baseUrl is /vfls/api on prod, but the static
    // mount lives at the server root, so we strip the suffix here.
    final bgImageUrl = scenario.backgroundImageUrl;
    final hasBg = showBackgroundImage && bgImageUrl != null && bgImageUrl.isNotEmpty;
    const cardRadius = BorderRadius.vertical(
      top: Radius.circular(20),
      bottom: Radius.circular(20),
    );
    return DecoratedBox(
          decoration: BoxDecoration(
            // Background image sits behind the gradient overlay.
            image: hasBg
                ? DecorationImage(
                    image: _imageProvider(_resolveScenarioImage(bgImageUrl)),
                    fit: BoxFit.cover,
                    onError: (_, _) {},
                  )
                : null,
            borderRadius: cardRadius,
            border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
          ),
          child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: hasBg ? 0.82 : 1.0),
            scheme.surfaceContainerHighest.withValues(alpha: hasBg ? 0.82 : 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryIllustration(category: scenario.category, scheme: scheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCENE',
                      style: TextStyle(
                        fontFamily: 'EditorialMono',
                        fontSize: 11,
                        letterSpacing: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scenario.title.forLocale(locale),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDescription) ...[
            const SizedBox(height: 16),
            Text(
              scenario.description.forLocale(locale),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              if (showCefrPill) _Pill(text: 'CEFR · $levelLabel', scheme: scheme),
              if (scenario.timeConstrained)
                _Pill(text: '~${scenario.estimatedMinutes} min', scheme: scheme),
              if (showXpPill) _Pill(text: '+${scenario.xpReward} XP', scheme: scheme),
            ],
          ),
        ],
      ),
    ),
  );
  }

  /// Resolves a stored image URL to one the image widgets can load.
  /// - `http(s)://...`    → returned as-is (absolute network URL)
  /// - `asset:...`        → returned as-is (handled by [_imageProvider])
  /// - `/uploads/...`     → prepends uploadsOrigin (relative backend path)
  String _resolveScenarioImage(String relative) {
    if (relative.startsWith('http') || relative.startsWith('asset:')) {
      return relative;
    }
    return '$uploadsOrigin$relative';
  }

  /// Returns the correct [ImageProvider] for both network and asset URLs.
  ImageProvider _imageProvider(String url) {
    if (url.startsWith('asset:')) return AssetImage(url.substring(6));
    return NetworkImage(url);
  }

}

class _CategoryIllustration extends StatelessWidget {
  const _CategoryIllustration({required this.category, required this.scheme});
  final String category;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final emoji = switch (category) {
      'travel' => '✈️',
      'business' => '💼',
      'social' => '☕',
      'daily' => '🏠',
      'academic' => '🎓',
      'roleplay' => '🎭',
      _ => '💬',
    };
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 32)),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.scheme});
  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'EditorialMono',
          fontSize: 11,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _RolesRow extends StatelessWidget {
  const _RolesRow({required this.scenario, required this.persona});
  final Scenario scenario;
  final Persona? persona;

  @override
  Widget build(BuildContext context) {
    final personaName = persona?.name ?? 'Tutor';
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            label: 'You play',
            value: 'Yourself, practising ${scenario.category}',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            label: '$personaName plays',
            value: _personaRoleFor(scenario.category),
            icon: Icons.face_outlined,
          ),
        ),
      ],
    );
  }

  String _personaRoleFor(String category) => switch (category) {
        'travel' => 'A local you bump into',
        'business' => 'A colleague at the office',
        'social' => 'A friend at the café',
        'daily' => 'A neighbour or shopkeeper',
        'academic' => 'A classmate or tutor',
        'roleplay' => 'A character in the scene',
        _ => 'Your conversation partner',
      };
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'EditorialMono',
              fontSize: 10,
              letterSpacing: 1.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TwistBanner extends StatelessWidget {
  const _TwistBanner({required this.scenario, required this.locale});
  final Scenario scenario;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '?!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _twistFor(scenario.category),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _twistFor(String category) => switch (category) {
        'travel' => 'Surprise: your flight is delayed by 4 hours.',
        'business' => 'Surprise: the deadline just moved up by a week.',
        'social' => 'Surprise: your friend has unexpected news to share.',
        'daily' => 'Surprise: something you ordered arrived broken.',
        'academic' => 'Surprise: the topic has shifted to something you didn\'t prepare for.',
        _ => 'Surprise: the conversation takes an unexpected turn.',
      };
}

class _Objectives extends StatelessWidget {
  const _Objectives({required this.scenario});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final items = _objectivesFor(scenario.category);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NumberedRow(index: i + 1, text: items[i]),
          ),
      ],
    );
  }

  List<String> _objectivesFor(String category) => switch (category) {
        'travel' => const [
            'Make small-talk with a stranger.',
            'Ask for directions or recommendations.',
            'Politely handle a request you can\'t fulfil.',
          ],
        'business' => const [
            'Greet a colleague and set context.',
            'Make a clear request with a reason.',
            'Wrap up with a next-step commitment.',
          ],
        'social' => const [
            'Open with a friendly hook.',
            'Share something specific about your day.',
            'Ask a follow-up that invites a story.',
          ],
        _ => const [
            'Open the conversation naturally.',
            'Stay on-topic for at least 3 turns.',
            'Use one new word or phrase.',
          ],
      };
}

class _NumberedRow extends StatelessWidget {
  const _NumberedRow({required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$index',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _Phrases extends StatelessWidget {
  const _Phrases({required this.scenario});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final phrases = _phrasesFor(scenario.category);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final p in phrases)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"$p"',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  List<String> _phrasesFor(String category) => switch (category) {
        'travel' => const [
            'Could you point me in the direction of…?',
            'Do you have any recommendations?',
            'Thanks so much, you\'ve been a lifesaver.',
          ],
        'business' => const [
            'I wanted to circle back on…',
            'Could we sync on this later today?',
            'I\'d push back gently on that.',
          ],
        'social' => const [
            'Funny you should mention that — I…',
            'Wait, what? Tell me everything.',
            'I\'ve been meaning to ask you about…',
          ],
        _ => const [
            'That makes sense — could you say more?',
            'I see what you mean. From my side…',
            'Mind if I ask a follow-up?',
          ],
      };
}

class _PersonaPairing extends StatelessWidget {
  const _PersonaPairing({
    required this.persona,
    required this.scheme,
    required this.onChange,
  });
  final Persona? persona;
  final ColorScheme scheme;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final name = persona?.name ?? 'Default tutor';
    final style = persona?.style ?? 'friendly';
    final accent = persona?.accent ?? 'neutral';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '$style · $accent',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'EditorialMono',
        fontSize: 11,
        letterSpacing: 1.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}


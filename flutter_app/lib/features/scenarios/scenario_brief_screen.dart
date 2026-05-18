import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/models/models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/router/app_router.dart';

final _scenarioProvider =
    FutureProvider.family<Scenario, String>((ref, idOrSlug) async {
  final raw = await ref.read(scenariosApiProvider).get(idOrSlug);
  return Scenario.fromJson(raw);
});

final _personasProvider = FutureProvider<List<Persona>>((ref) async {
  final raw = await ref.read(personasApiProvider).list();
  return raw.map(Persona.fromJson).toList();
});

/// Intermediate "brief" between picking a topic on the scenarios screen and
/// actually starting the conversation. Matches design_handoff_freetalk
/// `screens.md` §5 — header, hero card, roles, twist, objectives,
/// persona pairing, sticky bottom dock.
class ScenarioBriefScreen extends ConsumerWidget {
  const ScenarioBriefScreen({required this.scenarioId, super.key});

  final String scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarioAsync = ref.watch(_scenarioProvider(scenarioId));
    final personasAsync = ref.watch(_personasProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider).user;

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
            onRetry: () => ref.invalidate(_scenarioProvider(scenarioId)),
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
              _HeroCard(scenario: scenario, locale: locale),
              const SizedBox(height: 20),
              _RolesRow(scenario: scenario, persona: activePersona),
              const SizedBox(height: 20),
              _TwistBanner(scenario: scenario, locale: locale),
              const SizedBox(height: 20),
              const _SectionHeader(text: 'Objectives'),
              const SizedBox(height: 8),
              _Objectives(scenario: scenario),
              const SizedBox(height: 20),
              const _SectionHeader(text: 'Phrases worth stealing'),
              const SizedBox(height: 8),
              _Phrases(scenario: scenario),
              const SizedBox(height: 20),
              _PersonaPairing(persona: activePersona, scheme: scheme),
            ],
          );
        },
      ),
      bottomNavigationBar: scenarioAsync.maybeWhen(
        data: (scenario) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
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
                    onPressed: () => _startSession(context, ref, scenario),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Start speaking (${scenario.estimatedMinutes}m)'),
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

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.scenario, required this.locale});
  final Scenario scenario;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levelLabels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final levelLabel = scenario.difficulty >= 1 && scenario.difficulty <= 6
        ? levelLabels[scenario.difficulty - 1]
        : '—';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
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
          const SizedBox(height: 16),
          Text(
            scenario.description.forLocale(locale),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _Pill(text: 'CEFR · $levelLabel', scheme: scheme),
              _Pill(text: '~${scenario.estimatedMinutes} min', scheme: scheme),
              _Pill(text: '+${scenario.xpReward} XP', scheme: scheme),
            ],
          ),
        ],
      ),
    );
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
  const _PersonaPairing({required this.persona, required this.scheme});
  final Persona? persona;
  final ColorScheme scheme;

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
            onPressed: () {
              // Settings → tutor section. Stays inside the brief flow so the
              // user can come back without losing their place.
              // Settings change persona globally; the brief auto-refreshes
              // because it reads the active persona from authProvider.
            },
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

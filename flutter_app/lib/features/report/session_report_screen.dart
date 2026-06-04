import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/router/app_router.dart';

// ─── Providers ──────────────────────────────────────────────────────────────

final _sessionProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.read(conversationsApiProvider).getSession(id);
});

// ─── Screen ─────────────────────────────────────────────────────────────────

class SessionReportScreen extends ConsumerStatefulWidget {
  const SessionReportScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  ConsumerState<SessionReportScreen> createState() =>
      _SessionReportScreenState();
}

class _SessionReportScreenState extends ConsumerState<SessionReportScreen> {
  Map<String, dynamic>? _scoreData;
  bool _evaluationDone = false; // true once score arrived or gave up
  int _pollAttempts = 0;
  static const _maxPollAttempts = 12; // ~36 s total
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollScore();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollScore() async {
    try {
      final score = await ref
          .read(conversationsApiProvider)
          .getSessionScore(widget.sessionId);
      if (!mounted) return;
      if (score != null) {
        setState(() {
          _scoreData = score;
          _evaluationDone = true;
        });
        return;
      }
    } catch (_) {
      // network hiccup — keep polling
    }
    if (_pollAttempts < _maxPollAttempts) {
      _pollAttempts++;
      _pollTimer = Timer(const Duration(seconds: 3), _pollScore);
    } else {
      if (mounted) setState(() => _evaluationDone = true); // gave up
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(_sessionProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session report'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoute.home),
        ),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logRawError('session_report_screen', e, st);
          return PoliteErrorCenter(
            error: e,
            context: ErrorContext.loadDetail,
            onRetry: () =>
                ref.invalidate(_sessionProvider(widget.sessionId)),
          );
        },
        data: (session) => _Body(
          session: session,
          scoreData: _scoreData,
          evaluationDone: _evaluationDone,
        ),
      ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.session,
    required this.scoreData,
    required this.evaluationDone,
  });

  final Map<String, dynamic> session;
  final Map<String, dynamic>? scoreData;
  final bool evaluationDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final xp = (session['xpEarned'] as num? ?? 0).toInt();
    final turns = (session['turnCount'] as num? ?? 0).toInt();
    final words = (session['wordCount'] as num? ?? 0).toInt();
    final status = session['status'] as String? ?? 'completed';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        // ── XP badge ──────────────────────────────────────────
        Center(
          child: Container(
            width: 160,
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primaryContainer]),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$xp',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w800)),
                const Text('XP',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            status == 'completed' ? 'Great work!' : 'Session ended',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'You spoke $words words across $turns turns.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 32),
        // ── AI evaluation section ──────────────────────────────
        _EvaluationSection(
          scoreData: scoreData,
          evaluationDone: evaluationDone,
          scheme: scheme,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go(AppRoute.home),
          child: const Text('Back to home'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.go(AppRoute.scenarios),
          child: const Text('Practice another scenario'),
        ),
      ],
    );
  }
}

// ─── Evaluation section ───────────────────────────────────────────────────────

class _EvaluationSection extends StatelessWidget {
  const _EvaluationSection({
    required this.scoreData,
    required this.evaluationDone,
    required this.scheme,
  });

  final Map<String, dynamic>? scoreData;
  final bool evaluationDone;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (!evaluationDone && scoreData == null) {
      return _PendingCard(scheme: scheme);
    }
    if (scoreData == null) {
      return _UnavailableCard(scheme: scheme);
    }
    return _ScoreCard(score: scoreData!, scheme: scheme);
  }
}

// ── Pending (still polling) ───────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'AI is evaluating your session… this takes a few seconds.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unavailable ───────────────────────────────────────────────────────────────

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'AI evaluation is not available for this session.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.scheme});

  final Map<String, dynamic> score;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final sessionFeedback = score['sessionFeedback'] as String?;
    final cefr = score['cefrEstimate'] as String?;
    final fluency = (score['fluencyScore'] as num?)?.toInt();
    final accuracy = (score['accuracyScore'] as num?)?.toInt();
    final vocabulary = (score['vocabularyScore'] as num?)?.toInt();
    final interaction = (score['interactionScore'] as num?)?.toInt();
    final topicAdherence = (score['topicAdherenceScore'] as num?)?.toInt();
    final strengths = (score['strengths'] as List?)?.cast<String>() ?? [];
    final rawSpecific = (score['specificFeedback'] as List?) ?? [];
    final specificFeedback = rawSpecific
        .cast<Map<String, dynamic>>()
        .where((f) {
          final issue = f['issue'] as String?;
          return issue != null && issue.isNotEmpty && issue != 'None';
        })
        .toList();
    final practice = score['suggestedPractice'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CEFR badge + title row
        Row(
          children: [
            Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI Evaluation',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (cefr != null) _CefrBadge(label: cefr, scheme: scheme),
          ],
        ),
        const SizedBox(height: 16),

        // Session feedback prose — shown first
        if (sessionFeedback != null && sessionFeedback.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              sessionFeedback,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.55),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Score bars (scores are 0-100; display as 1-5 dots for clarity)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (fluency != null)
                _ScoreRow('Fluency', fluency, scheme,
                    'Pacing, hesitation, naturalness'),
              if (accuracy != null)
                _ScoreRow('Accuracy', accuracy, scheme,
                    'Grammar, tense, articles'),
              if (vocabulary != null)
                _ScoreRow('Vocabulary', vocabulary, scheme,
                    'Range, appropriateness'),
              if (interaction != null)
                _ScoreRow('Interaction', interaction, scheme,
                    'Turn-taking, engagement'),
              if (topicAdherence != null)
                _ScoreRow('Topic focus', topicAdherence, scheme,
                    'Engagement with assigned topic'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Strengths
        if (strengths.isNotEmpty) ...[
          _SectionHeader('Strengths', Icons.thumb_up_outlined, scheme),
          const SizedBox(height: 8),
          ...strengths.map((s) => _BulletLine(s, scheme)),
          const SizedBox(height: 16),
        ],

        // Turn-by-turn feedback
        if (specificFeedback.isNotEmpty) ...[
          _SectionHeader('Turn feedback', Icons.rate_review_outlined, scheme),
          const SizedBox(height: 8),
          ...specificFeedback.map((f) => _TurnFeedbackItem(f, scheme)),
          const SizedBox(height: 16),
        ],

        // Suggested practice
        if (practice != null && practice.isNotEmpty) ...[
          _SectionHeader('Suggested practice', Icons.school_outlined, scheme),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              practice,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CefrBadge extends StatelessWidget {
  const _CefrBadge({required this.label, required this.scheme});
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.value, this.scheme, this.subtitle);

  final String label;
  final int value; // 0-100
  final ColorScheme scheme;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // Convert 0-100 back to 1-5 dots
    final dots = (value / 20).round().clamp(1, 5);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              final filled = i < dots;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  filled ? Icons.circle : Icons.circle_outlined,
                  size: 14,
                  color: filled ? scheme.primary : scheme.outlineVariant,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.icon, this.scheme);
  final String title;
  final IconData icon;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text, this.scheme);
  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 6, color: scheme.primary),
          ),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TurnFeedbackItem extends StatelessWidget {
  const _TurnFeedbackItem(this.item, this.scheme);
  final Map<String, dynamic> item;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final turnIndex = item['turn_index'] as int? ?? 0;
    final userText = item['user_text'] as String? ?? '';
    final issue = item['issue'] as String? ?? '';
    final correction = item['correction'] as String?;
    final severity = item['severity'] as String? ?? 'minor';

    final severityColor = switch (severity) {
      'major'    => scheme.error,
      'moderate' => const Color(0xFFE67E22),
      _          => scheme.onSurfaceVariant,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: severityColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Turn $turnIndex',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  severity,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (userText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"$userText"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
          const SizedBox(height: 6),
          Text(issue, style: Theme.of(context).textTheme.bodyMedium),
          if (correction != null && correction.isNotEmpty && correction != 'None') ...[
            const SizedBox(height: 4),
            Text(
              '→ $correction',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/router/app_router.dart';

final _reportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.read(conversationsApiProvider).getSession(id);
});

class SessionReportScreen extends ConsumerWidget {
  const SessionReportScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(_reportProvider(sessionId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session report'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoute.home),
        ),
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logRawError('session_report_screen', e, st);
          return PoliteErrorCenter(
            error: e,
            context: ErrorContext.loadDetail,
            onRetry: () => ref.invalidate(_reportProvider(sessionId)),
          );
        },
        data: (data) {
          final xpEarned = (data['xpEarned'] as num? ?? 0).toInt();
          final turnCount = (data['turnCount'] as num? ?? 0).toInt();
          final wordCount = (data['wordCount'] as num? ?? 0).toInt();
          final status = data['status'] as String? ?? 'completed';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [scheme.primary, scheme.primaryContainer]),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$xpEarned',
                          style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800)),
                      const Text('XP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  status == 'completed' ? 'Great work!' : 'Session ended',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'You spoke $wordCount words across $turnCount turns.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 32),
              _ScoreSection(scheme: scheme),
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
        },
      ),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  const _ScoreSection({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    // Per-skill scores will be computed by §09 once the AI provider lands.
    // For now we surface "—" with a note explaining why.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Skill scores',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AI-driven scoring (grammar, fluency, vocabulary) arrives when AI integration lands. Your XP and engagement are already tracked.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final skill in const ['Grammar', 'Vocabulary', 'Fluency', 'Engagement'])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(skill, style: Theme.of(context).textTheme.bodyMedium)),
                  Text('—', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

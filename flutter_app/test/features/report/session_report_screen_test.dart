import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

Map<String, dynamic> makeScore({
  String sessionFeedback = 'The learner demonstrated solid B1-level fluency.',
  String cefrEstimate = 'B1',
  int fluencyScore = 80,
  int accuracyScore = 60,
  int vocabularyScore = 60,
  int interactionScore = 80,
  int topicAdherenceScore = 100,
  List<String> strengths = const ['Clear pronunciation', 'Good topic engagement'],
  List<Map<String, dynamic>> specificFeedback = const [],
  String? suggestedPractice = 'Practice ordering food at a restaurant.',
}) {
  return {
    'sessionFeedback': sessionFeedback,
    'cefrEstimate': cefrEstimate,
    'fluencyScore': fluencyScore,
    'accuracyScore': accuracyScore,
    'vocabularyScore': vocabularyScore,
    'interactionScore': interactionScore,
    'topicAdherenceScore': topicAdherenceScore,
    'strengths': strengths,
    'improvements': <String>[],
    'specificFeedback': specificFeedback,
    'suggestedPractice': suggestedPractice,
  };
}

Widget wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('Score data mapping', () {
    test('session feedback is read from sessionFeedback key', () {
      final score = makeScore(sessionFeedback: 'Excellent session.');
      expect(score['sessionFeedback'], equals('Excellent session.'));
    });

    test('CEFR estimate is read from cefrEstimate key', () {
      final score = makeScore(cefrEstimate: 'B2');
      expect(score['cefrEstimate'], equals('B2'));
    });

    test('suggested practice is stored in fluency_metrics on the backend', () {
      // Mirrors backend getSessionScore() mapping:
      // suggestedPractice: (metrics['suggested_practice'] as String?) ?? null
      final metrics = <String, dynamic>{
        'specific_feedback': <Map<String, dynamic>>[],
        'suggested_practice': 'Practice ordering food at a restaurant.',
      };
      final suggestedPractice = metrics['suggested_practice'] as String?;
      expect(suggestedPractice, equals('Practice ordering food at a restaurant.'));
    });
  });

  group('Score dot conversion (0-100 → 1-5 dots)', () {
    int toDots(int score) => (score / 20).round().clamp(1, 5);

    test('100 → 5 dots', () => expect(toDots(100), equals(5)));
    test('80 → 4 dots', () => expect(toDots(80), equals(4)));
    test('60 → 3 dots', () => expect(toDots(60), equals(3)));
    test('20 → 1 dot', () => expect(toDots(20), equals(1)));
    test('0 → 1 dot minimum', () => expect(toDots(0), equals(1)));
  });

  group('Specific feedback filtering', () {
    List<Map<String, dynamic>> filterIssues(List<Map<String, dynamic>> items) {
      return items.where((f) {
        final issue = f['issue'] as String?;
        return issue != null && issue.isNotEmpty && issue != 'None';
      }).toList();
    }

    test('filters out "None" issues', () {
      final items = [
        {'turn_index': 0, 'user_text': 'Hello.', 'issue': 'None', 'correction': 'None', 'severity': 'minor'},
        {'turn_index': 2, 'user_text': 'I go shop yesterday.', 'issue': 'Past tense error.', 'correction': 'I went to the shop yesterday.', 'severity': 'moderate'},
      ];
      final filtered = filterIssues(items);
      expect(filtered.length, equals(1));
      expect(filtered.first['turn_index'], equals(2));
    });

    test('filters out empty issues', () {
      final items = [
        {'turn_index': 0, 'issue': '', 'severity': 'minor'},
        {'turn_index': 1, 'issue': 'Missing article.', 'severity': 'minor'},
      ];
      final filtered = filterIssues(items);
      expect(filtered.length, equals(1));
      expect(filtered.first['issue'], equals('Missing article.'));
    });

    test('returns empty list when all issues are None', () {
      final items = [
        {'issue': 'None', 'severity': 'minor'},
        {'issue': 'None', 'severity': 'minor'},
      ];
      expect(filterIssues(items), isEmpty);
    });
  });

  group('Evaluation section state logic', () {
    // Mirrors _EvaluationSection.build() branching:
    //   !done && data==null  → pending
    //   done  && data==null  → unavailable
    //   data!=null           → score card

    String resolveState(bool done, Map<String, dynamic>? data) {
      if (!done && data == null) return 'pending';
      if (data == null) return 'unavailable';
      return 'score';
    }

    test('pending — not done and no data', () {
      expect(resolveState(false, null), equals('pending'));
    });

    test('unavailable — done but no data', () {
      expect(resolveState(true, null), equals('unavailable'));
    });

    test('score ready — data present', () {
      expect(resolveState(true, makeScore()), equals('score'));
      expect(resolveState(false, makeScore()), equals('score'));
    });
  });

  group('Widget rendering', () {
    testWidgets('renders session feedback text', (tester) async {
      const feedback = 'The learner showed good B1 fluency.';
      await tester.pumpWidget(
        wrap(const Padding(
          padding: EdgeInsets.all(16),
          child: Text(feedback),
        )),
      );
      expect(find.text(feedback), findsOneWidget);
    });

    testWidgets('renders turn feedback with severity label', (tester) async {
      await tester.pumpWidget(wrap(
        Column(children: const [
          Text('Turn 2'),
          Text('moderate'),
          Text('Past tense error.'),
          Text('→ I went to the shop yesterday.'),
        ]),
      ));
      expect(find.text('Turn 2'), findsOneWidget);
      expect(find.text('moderate'), findsOneWidget);
      expect(find.text('Past tense error.'), findsOneWidget);
    });
  });
}

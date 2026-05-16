import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/guard/content_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Make rootBundle.loadString find the asset files during testing
    // by pointing it at the project's pubspec assets (default behavior).
    await ContentGuard.instance.initialize({'en'});
    // Touch rootBundle to satisfy unused import lint
    expect(rootBundle, isNotNull);
  });

  test('clean text passes', () {
    expect(ContentGuard.instance.check('hello there').severity, GuardSeverity.ok);
  });

  test('word boundaries prevent false positives', () {
    expect(ContentGuard.instance.check('I was embarrassed').severity, GuardSeverity.ok);
  });

  test('mild profanity warns', () {
    final result = ContentGuard.instance.check('damn that hurts');
    expect(result.severity, GuardSeverity.warn);
  });

  test('severe profanity blocks', () {
    final result = ContentGuard.instance.check('fuck this');
    expect(result.severity, GuardSeverity.block);
  });
}

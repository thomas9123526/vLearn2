import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GuardSeverity { ok, warn, block }

class GuardResult {
  const GuardResult({
    required this.severity,
    this.matchedTerms = const [],
    this.language,
  });
  final GuardSeverity severity;
  final List<String> matchedTerms;
  final String? language;
}

class _Wordlist {
  const _Wordlist({required this.block, required this.warn});
  final Set<String> block;
  final Set<String> warn;
}

/// Client-side content guard. Mirrors the server-side check (see
/// backend/src/guard/content-guard.service.ts) so the user gets instant UX
/// feedback. Server is authoritative — even if this passes, the server re-checks.
class ContentGuard {
  ContentGuard._();

  static final ContentGuard instance = ContentGuard._();

  final Map<String, _Wordlist> _wordlists = {};
  bool _initialized = false;

  Future<void> initialize(Set<String> languages) async {
    if (_initialized) return;
    final toLoad = <String>{...languages, 'en'};
    for (final lang in toLoad) {
      try {
        final raw = await rootBundle.loadString('assets/guard/profanity_$lang.json');
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _wordlists[lang] = _Wordlist(
          block: (j['block'] as List<dynamic>? ?? const []).cast<String>().map((s) => s.toLowerCase()).toSet(),
          warn: (j['warn'] as List<dynamic>? ?? const []).cast<String>().map((s) => s.toLowerCase()).toSet(),
        );
      } on Object {
        // Wordlist missing — skip silently.
      }
    }
    _initialized = true;
  }

  GuardResult check(String text, {Set<String>? activeLanguages}) {
    if (!_initialized) {
      // Fail-open if not initialized
      return const GuardResult(severity: GuardSeverity.ok);
    }
    if (text.trim().isEmpty) {
      return const GuardResult(severity: GuardSeverity.ok);
    }
    final normalized = _normalize(text);
    final langs = <String>{...?activeLanguages, 'en'};
    final warned = <String>[];

    for (final lang in langs) {
      final wl = _wordlists[lang];
      if (wl == null) continue;

      for (final term in wl.block) {
        if (_matches(normalized, term)) {
          return GuardResult(severity: GuardSeverity.block, matchedTerms: [term], language: lang);
        }
      }
      for (final term in wl.warn) {
        if (_matches(normalized, term)) warned.add(term);
      }
    }
    if (warned.isNotEmpty) {
      return GuardResult(severity: GuardSeverity.warn, matchedTerms: warned);
    }
    return const GuardResult(severity: GuardSeverity.ok);
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _matches(String normalized, String term) {
    if (term.contains(' ')) return normalized.contains(term);
    final escaped = RegExp.escape(term);
    final re = RegExp('(^|[^a-z0-9가-힣ㄱ-ㅎㅏ-ㅣ一-鿿])$escaped([^a-z0-9가-힣ㄱ-ㅎㅏ-ㅣ一-鿿]|\$)');
    return re.hasMatch(normalized);
  }
}

final contentGuardProvider = Provider<ContentGuard>((_) => ContentGuard.instance);

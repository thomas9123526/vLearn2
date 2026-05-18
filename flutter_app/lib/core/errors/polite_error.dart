/// Polite, user-facing error UX shared across every screen.
///
/// User-visible flow:
///   1. Some `await api...()` throws (DioException, ApiException, network
///      error, whatever).
///   2. Screen catches and either renders [PoliteBanner] / [PoliteErrorCenter]
///      or calls [showPoliteErrorSnack].
///   3. We translate the raw error into a single short, friendly sentence
///      via [politeMessageFor], picking the wording from a small set so the
///      app never displays a DioException toString.
///   4. We log the raw error to the debug console via [logRawError] so
///      developers can still see exactly what happened.
///
/// Style: soft green container, info icon. Reads as recoverable, not
/// alarming. The exact shade is also used on the sign-in screen so the UX
/// is consistent.
library;

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../api/interceptors/error_interceptor.dart';

/// What the user was trying to do. Drives the *fallback* copy when the
/// error doesn't match a specific status-code / network pattern. Network
/// + status-code messages are the same regardless of context.
enum ErrorContext {
  /// Loading a list / feed (scenarios, news list, sessions list, ...).
  loadList,

  /// Loading a single item's detail page (news item, session report, ...).
  loadDetail,

  /// Sending a message in conversation.
  send,

  /// Starting / ending a conversation session, marking news read, etc.
  action,

  /// Sign-in attempt specifically.
  signIn,

  /// Sign-up / registration attempt.
  signUp,

  /// Anything else.
  generic,
}

/// Returns a single short, polite sentence describing the failure.
/// Never returns a DioException toString.
String politeMessageFor(Object error, {ErrorContext context = ErrorContext.generic}) {
  if (error is ApiException && error.isNetwork) {
    return "Couldn't reach the server. Check your connection and try again.";
  }

  // ── Network-class errors (the user actually can't reach us) ─────────
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return "Couldn't reach the server. Check your connection and try again.";
      case DioExceptionType.cancel:
        return 'That action was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Connection blocked by a security check. Please try again later.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        // Fall through to status-code / generic handling below.
        break;
    }
  }

  // ── Status-code-driven messages ────────────────────────────────────
  final status = _statusOf(error);
  if (status != null) {
    if (status == 401 || _i18nMatches(error, 'auth.invalid_credentials')) {
      return context == ErrorContext.signIn
          ? 'Email or password is not correct.'
          : 'You need to sign in again.';
    }
    if (status == 403 ||
        _i18nMatches(error, 'account.suspended') ||
        _i18nMatches(error, 'account.deleted')) {
      return "You don't have permission to do that right now.";
    }
    if (status == 404) {
      return context == ErrorContext.loadDetail
          ? "We couldn't find that. It may have been removed."
          : "Couldn't find what you were looking for.";
    }
    if (status == 409 || _i18nMatches(error, 'auth.email_taken')) {
      return 'That value is already in use.';
    }
    if (status == 422 || status == 400) {
      return 'Something in that request looked off. Please check and try again.';
    }
    if (status == 429) {
      return 'Too many tries in a short time. Please wait a moment and try again.';
    }
    if (status >= 500) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
  }

  // ── Context-flavoured fallback ─────────────────────────────────────
  switch (context) {
    case ErrorContext.loadList:
      return "Couldn't load this list. Pull to refresh.";
    case ErrorContext.loadDetail:
      return "Couldn't load this page. Please try again.";
    case ErrorContext.send:
      return "Couldn't send your message. Try again.";
    case ErrorContext.action:
      return "That didn't work. Please try again.";
    case ErrorContext.signIn:
      return "Sign in didn't work. Please try again.";
    case ErrorContext.signUp:
      return "Couldn't create your account. Please try again.";
    case ErrorContext.generic:
      return "Something didn't work. Please try again.";
  }
}

/// Sends the full raw error to the debug console with a screen-specific
/// tag. Stripped from release builds. Never visible to the user.
void logRawError(String tag, Object error, [StackTrace? stack]) {
  developer.log(
    '$error',
    name: tag,
    level: 1000,
    error: error,
    stackTrace: stack,
  );
  debugPrint('[$tag] $error');
}

int? _statusOf(Object error) {
  if (error is ApiException) return error.statusCode;
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return inner.statusCode;
    return error.response?.statusCode;
  }
  return null;
}

bool _i18nMatches(Object error, String key) {
  if (error is ApiException) return error.i18nKey == key;
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return inner.i18nKey == key;
  }
  return error.toString().contains(key);
}

// ─── UI primitives ────────────────────────────────────────────────────

/// Soft green banner used inside cards or above form buttons.
class PoliteBanner extends StatelessWidget {
  const PoliteBanner({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline_rounded, color: palette.fg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered "failed to load" widget for full-page error states.
/// Optional [onRetry] adds a small retry button.
class PoliteErrorCenter extends StatelessWidget {
  const PoliteErrorCenter({
    super.key,
    required this.error,
    this.context = ErrorContext.generic,
    this.onRetry,
  });

  final Object error;
  final ErrorContext context;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext ctx) {
    final palette = _palette(ctx);
    final msg = politeMessageFor(error, context: context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, color: palette.fg, size: 36),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: palette.fg),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a polite SnackBar (and logs the raw error). Call this from any
/// catch block where you'd previously do `SnackBar(Text('Failed: $e'))`.
void showPoliteErrorSnack(
  BuildContext context,
  Object error, {
  String tag = 'screen',
  ErrorContext errorContext = ErrorContext.action,
  StackTrace? stack,
}) {
  logRawError(tag, error, stack);
  if (!context.mounted) return;
  final palette = _palette(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: palette.bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.border),
        ),
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: palette.fg, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                politeMessageFor(error, context: errorContext),
                style: TextStyle(color: palette.fg),
              ),
            ),
          ],
        ),
      ),
    );
}

class _PolitePalette {
  const _PolitePalette(this.bg, this.border, this.fg);
  final Color bg;
  final Color border;
  final Color fg;
}

_PolitePalette _palette(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? const _PolitePalette(
          Color(0xFF0F2A1A),
          Color(0xFF2F6B43),
          Color(0xFFC8E6D2),
        )
      : const _PolitePalette(
          Color(0xFFE8F5EE),
          Color(0xFFB7E0C6),
          Color(0xFF1F5132),
        );
}

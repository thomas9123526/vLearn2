import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  /// Polite, user-facing version of whatever blew up. Translated from the
  /// raw auth-provider error in [ref.listen] below; never displays a
  /// DioException toString. Cleared on the next submit attempt.
  String? _politeError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _politeError = null);
    await ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  /// Maps the noisy DioException / ApiException toString() into a single
  /// polite sentence. The full raw error is sent to the debug console
  /// separately (see [_logRaw]).
  String _politeFor(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('auth.invalid_credentials') ||
        lower.contains('401') ||
        lower.contains('unauthorized')) {
      return 'Email or password is not correct.';
    }
    if (lower.contains('account.suspended') ||
        lower.contains('account.deleted') ||
        lower.contains('403') ||
        lower.contains('forbidden')) {
      return 'This account can\'t sign in right now. Please contact support.';
    }
    if (lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('handshake') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused')) {
      return 'Couldn\'t reach the server. Check your internet connection and try again.';
    }
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('server')) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
    return 'Sign in didn\'t work. Please try again.';
  }

  void _logRaw(String raw) {
    // Goes to the IDE Run/Debug Console + `flutter run` terminal but never
    // to the user. debugPrint is throttled-safe for long messages; developer
    // .log adds the structured tag so it's easy to filter on.
    developer.log(raw, name: 'sign_in_screen', level: 1000);
    debugPrint('[sign_in] raw error: $raw');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.checking;
    final scheme = Theme.of(context).colorScheme;

    // React to auth state changes from this screen's submit only. Translates
    // the raw provider error into the polite local one and logs the raw
    // version to the debug console.
    ref.listen<AuthState>(authProvider, (prev, next) {
      final raw = next.errorMessage;
      if (next.status == AuthStatus.signedOut &&
          raw != null &&
          raw != prev?.errorMessage) {
        _logRaw(raw);
        if (mounted) setState(() => _politeError = _politeFor(raw));
      } else if (next.status == AuthStatus.checking ||
          next.status == AuthStatus.signedIn) {
        if (_politeError != null && mounted) {
          setState(() => _politeError = null);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 64),
                Icon(Icons.school_rounded, size: 64, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your English journey.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                ),
                if (_politeError != null) ...[
                  const SizedBox(height: 16),
                  _PoliteBanner(text: _politeError!),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading ? null : () => context.push(AppRoute.signUp),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft green banner used in place of the previous red error banner. Reads
/// as polite/recoverable rather than alarming — matches the "polite and
/// green" UX the screen asks for.
class _PoliteBanner extends StatelessWidget {
  const _PoliteBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F2A1A) : const Color(0xFFE8F5EE);
    final border = isDark ? const Color(0xFF2F6B43) : const Color(0xFFB7E0C6);
    final fg = isDark ? const Color(0xFFC8E6D2) : const Color(0xFF1F5132);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: fg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

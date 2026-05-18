import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _language = 'en';
  bool _obscure = true;

  /// Polite, user-facing version of the last sign-up failure. Never shows a
  /// raw DioException string. Cleared on the next submit attempt.
  String? _politeError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _politeError = null);
    await ref.read(authProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
          uiLanguage: _language,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.checking;

    ref.listen<AuthState>(authProvider, (prev, next) {
      final raw = next.error;
      if (next.status == AuthStatus.signedOut &&
          raw != null &&
          raw != prev?.error) {
        logRawError('sign_up_screen', raw);
        if (mounted) {
          setState(() {
            _politeError = politeMessageFor(raw, context: ErrorContext.signUp);
          });
        }
      } else if (next.status == AuthStatus.checking ||
          next.status == AuthStatus.signedIn) {
        if (_politeError != null && mounted) {
          setState(() => _politeError = null);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      )),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Create your account',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Name must be at least 2 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                    helperText: 'At least 8 characters, with upper, lower, and a digit',
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Min 8 characters';
                    if (!RegExp('[a-z]').hasMatch(v)) return 'Need a lowercase letter';
                    if (!RegExp('[A-Z]').hasMatch(v)) return 'Need an uppercase letter';
                    if (!RegExp('[0-9]').hasMatch(v)) return 'Need a digit';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _language,
                  decoration: const InputDecoration(
                    labelText: 'Preferred language',
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ko', child: Text('한국어')),
                    DropdownMenuItem(value: 'zh', child: Text('中文')),
                  ],
                  onChanged: (v) => setState(() => _language = v ?? 'en'),
                ),
                if (_politeError != null) ...[
                  const SizedBox(height: 16),
                  PoliteBanner(text: _politeError!),
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
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

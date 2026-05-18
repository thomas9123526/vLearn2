import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/remembered_credentials.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cidUsernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;

  String? _politeError;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final creds =
        await ref.read(rememberedCredentialsStoreProvider).load();
    if (!mounted) return;
    setState(() {
      _rememberMe = creds.enabled;
      if (creds.cidUsername != null) _cidUsernameCtrl.text = creds.cidUsername!;
      if (creds.password != null) _passwordCtrl.text = creds.password!;
    });
  }

  @override
  void dispose() {
    _cidUsernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _politeError = null);
    await ref.read(authProvider.notifier).signIn(
          cidUsername: _cidUsernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          rememberMe: _rememberMe,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.checking;
    final scheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (prev, next) {
      final raw = next.error;
      if (next.status == AuthStatus.signedOut &&
          raw != null &&
          raw != prev?.error) {
        logRawError('sign_in_screen', raw);
        if (mounted) {
          setState(() {
            _politeError = politeMessageFor(raw, context: ErrorContext.signIn);
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
                  controller: _cidUsernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username (CID username)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.username],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username is required';
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: isLoading
                          ? null
                          : (v) => setState(() => _rememberMe = v ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => setState(() => _rememberMe = !_rememberMe),
                        child: Text(
                          'Remember me on this device',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
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

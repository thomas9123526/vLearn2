import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/auth_api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/auth/remembered_credentials.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/services/cid_fetch_service.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cidCtrl = TextEditingController();
  final _cidUsernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;
  bool _cidSyncing = false;
  bool _usernameSyncing = false;

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
    _cidCtrl.dispose();
    _cidUsernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Resolves the username for the CID currently typed (or just synced)
  /// in the CID field by hitting the public `/auth/lookup-username`
  /// endpoint. Fills the Username field on success; shows a snackbar
  /// with the polite error on failure.
  Future<void> _syncUsername() async {
    final cid = _cidCtrl.text.trim();
    if (cid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter or sync your CID first.'),
        ),
      );
      return;
    }
    setState(() => _usernameSyncing = true);
    try {
      final username = await ref.read(authApiProvider).lookupUsernameByCid(cid);
      if (mounted) setState(() => _cidUsernameCtrl.text = username);
    } catch (e, st) {
      logRawError('sign_in_screen.lookup_username', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              politeMessageFor(e, context: ErrorContext.signIn),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _usernameSyncing = false);
    }
  }

  Future<void> _syncCid() async {
    setState(() => _cidSyncing = true);
    try {
      final cid = await ref.read(cidFetchServiceProvider).fetchCid();
      if (mounted) setState(() => _cidCtrl.text = cid);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch CID. Please enter it manually.')),
        );
      }
    } finally {
      if (mounted) setState(() => _cidSyncing = false);
    }
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
    final l10n = AppLocalizations.of(context);
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
            _politeError = politeMessageFor(
              raw,
              context: ErrorContext.signIn,
              i18nKey: next.errorI18nKey,
            );
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
                  l10n.welcomeBack,
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
                  controller: _cidCtrl,
                  decoration: InputDecoration(
                    labelText: 'CID',
                    prefixIcon: const Icon(Icons.credit_card_outlined),
                    suffixIcon: _cidSyncing
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Sync CID from network',
                            icon: const Icon(Icons.sync),
                            onPressed: isLoading ? null : _syncCid,
                          ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cidUsernameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    // Mirrors the CID field's sync control: tap once the
                    // CID is filled to pull the registered username
                    // from the backend (`GET /auth/lookup-username`).
                    suffixIcon: _usernameSyncing
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Fetch username for this CID',
                            icon: const Icon(Icons.sync),
                            onPressed: isLoading ? null : _syncUsername,
                          ),
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
                    labelText: l10n.password,
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
                          l10n.signInRememberMe,
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
                      : Text(l10n.signIn),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading ? null : () => context.push(AppRoute.signUp),
                  child: Text(l10n.dontHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/api/interceptors/error_interceptor.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/services/cid_fetch_service.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cidCtrl = TextEditingController();
  final _cidUsernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _language = 'en';
  bool _obscure = true;
  bool _cidSyncing = false;

  // Birthday — stored as DateTime, displayed as text, not submitted to server.
  DateTime? _birthday;

  String? _politeError;
  List<String> _suggestions = [];
  bool _suggestingUsernames = false;

  @override
  void dispose() {
    _cidCtrl.dispose();
    _cidUsernameCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
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

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1994),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select your birthday',
    );
    if (picked != null && mounted) {
      setState(() {
        _birthday = picked;
        _suggestions = [];
      });
    }
  }

  Future<void> _fetchSuggestions() async {
    final name = _nameCtrl.text.trim();
    final bday = _birthday;
    if (name.isEmpty || bday == null) return;

    setState(() {
      _suggestingUsernames = true;
      _suggestions = [];
    });
    try {
      final birthday =
          '${bday.year.toString().padLeft(4, '0')}-'
          '${bday.month.toString().padLeft(2, '0')}-'
          '${bday.day.toString().padLeft(2, '0')}';
      final list = await ref.read(authApiProvider).suggestCidUsernames(
            displayName: name,
            birthday: birthday,
          );
      if (mounted) setState(() => _suggestions = list);
    } catch (_) {
      // Silent — suggestions are best-effort.
    } finally {
      if (mounted) setState(() => _suggestingUsernames = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _politeError = null;
      _suggestions = [];
    });
    await ref.read(authProvider.notifier).signUp(
          cid: _cidCtrl.text.trim(),
          cidUsername: _cidUsernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
          uiLanguage: _language,
        );
  }

  bool _isCidUsernameTaken(Object? err) {
    if (err == null) return false;
    if (err is ApiException) return err.i18nKey == 'auth.cid_username_taken';
    // DioException wraps ApiException as .error
    final dynamic dyn = err;
    try {
      final inner = dyn.error;
      if (inner is ApiException) return inner.i18nKey == 'auth.cid_username_taken';
    } catch (_) {}
    return false;
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
          if (_isCidUsernameTaken(raw)) {
            _fetchSuggestions();
          }
        }
      } else if (next.status == AuthStatus.checking ||
          next.status == AuthStatus.signedIn) {
        if (mounted) setState(() => _politeError = null);
      }
    });

    return Scaffold(
      appBar: AppBar(leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.canPop() ? context.pop() : context.go(AppRoute.signIn),
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

                // ── Display name ──────────────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: (_) => setState(() => _suggestions = []),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Name must be at least 2 characters'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── CID ───────────────────────────────────────────────────
                TextFormField(
                  controller: _cidCtrl,
                  decoration: InputDecoration(
                    labelText: 'CID (National ID)',
                    prefixIcon: const Icon(Icons.credit_card_outlined),
                    helperText: 'Up to 10 characters',
                    suffixIcon: _cidSyncing
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20, height: 20,
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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'CID is required';
                    if (v.trim().length > 10) return 'CID must be 10 characters or less';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Birthday (used only for username suggestions) ──────────
                _BirthdayField(
                  birthday: _birthday,
                  onTap: _pickBirthday,
                ),
                const SizedBox(height: 16),

                // ── CID Username ──────────────────────────────────────────
                TextFormField(
                  controller: _cidUsernameCtrl,
                  decoration: InputDecoration(
                    labelText: 'CID Username',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    helperText: 'At least 2 characters, used to sign in',
                    suffixIcon: _suggestingUsernames
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_birthday != null && _nameCtrl.text.trim().isNotEmpty
                            ? IconButton(
                                tooltip: 'Suggest available usernames',
                                icon: const Icon(Icons.auto_fix_high_outlined),
                                onPressed: _fetchSuggestions,
                              )
                            : null),
                  ),
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.newUsername],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'CID username is required';
                    if (v.trim().length < 2) return 'At least 2 characters';
                    return null;
                  },
                ),

                // ── Suggestion chips ──────────────────────────────────────
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SuggestionChips(
                    suggestions: _suggestions,
                    onSelected: (s) => setState(() {
                      _cidUsernameCtrl.text = s;
                      _politeError = null;
                    }),
                  ),
                ],
                const SizedBox(height: 16),

                // ── Password ──────────────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Language ──────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _language,
                  decoration: const InputDecoration(
                    labelText: 'Preferred language',
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
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
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Birthday field ───────────────────────────────────────────────────────────

class _BirthdayField extends StatelessWidget {
  const _BirthdayField({required this.birthday, required this.onTap});
  final DateTime? birthday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = birthday == null
        ? 'Birthday (for username suggestions)'
        : '${birthday!.year}.${birthday!.month.toString().padLeft(2, '0')}'
          '.${birthday!.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.cake_outlined),
          helperText: 'Used only to generate username suggestions',
        ),
        child: Text(
          label,
          style: birthday == null
              ? Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant)
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

// ─── Suggestion chips ─────────────────────────────────────────────────────────

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.suggestions, required this.onSelected});
  final List<String> suggestions;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available usernames — tap to use:',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: suggestions
              .map((s) => ActionChip(
                    label: Text(s),
                    onPressed: () => onSelected(s),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

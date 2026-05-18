import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';

/// Profile-edit dialog shown when the user taps the profile tile in Settings.
/// Lets the user change:
///   * display name
///   * avatar emoji (we don't host avatar uploads yet — emoji is the design)
///   * gender (male / female / nonbinary / unspecified)
///   * password (requires current password as proof-of-control)
///
/// Three sections live inside one scrollable dialog so the user doesn't have
/// to dig through nested screens just to flip their gender.
Future<void> showEditProfileDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      // When the Android IME opens, viewInsets.bottom grows to the keyboard
      // height. By reflecting that in insetPadding.bottom the Dialog shifts
      // up above the keyboard, keeping the focused field visible.
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      return Dialog(
        insetPadding: EdgeInsets.fromLTRB(24, 48, 24, bottom > 0 ? bottom + 8 : 48),
        child: const SizedBox(width: 460, child: _EditProfileBody()),
      );
    },
  );
}

class _EditProfileBody extends ConsumerStatefulWidget {
  const _EditProfileBody();

  @override
  ConsumerState<_EditProfileBody> createState() => _EditProfileBodyState();
}

class _EditProfileBodyState extends ConsumerState<_EditProfileBody> {
  final _nameCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  String _gender = 'unspecified';
  bool _saving = false;
  String? _error;

  static const _genders = [
    ('female', 'Female'),
    ('male', 'Male'),
    ('nonbinary', 'Non-binary'),
    ('unspecified', 'Prefer not to say'),
  ];
  static const _avatarChoices = [
    '🐣', '🦊', '🐯', '🐼', '🦁', '🐸',
    '👩', '👨', '🧑', '👧', '👦', '🧒',
    '👩‍🎓', '👨‍🎓', '🧑‍💻', '👩‍🏫', '👨‍🏫', '🌟',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameCtrl.text = user.displayName;
      _avatarCtrl.text = user.avatarEmoji;
      _gender = user.gender.isEmpty ? 'unspecified' : user.gender;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() {
      _error = null;
      _saving = true;
    });
    final patch = <String, Object?>{};
    if (_nameCtrl.text.trim() != user.displayName) {
      patch['displayName'] = _nameCtrl.text.trim();
    }
    if (_avatarCtrl.text.trim() != user.avatarEmoji) {
      patch['avatarEmoji'] = _avatarCtrl.text.trim();
    }
    if (_gender != user.gender) {
      patch['gender'] = _gender;
    }
    final wantsPasswordChange = _newPwCtrl.text.isNotEmpty;
    if (wantsPasswordChange) {
      if (_currentPwCtrl.text.isEmpty) {
        setState(() {
          _error = 'Enter your current password to change it.';
          _saving = false;
        });
        return;
      }
      if (_newPwCtrl.text.length < 8) {
        setState(() {
          _error = 'New password must be at least 8 characters.';
          _saving = false;
        });
        return;
      }
      if (_newPwCtrl.text != _confirmPwCtrl.text) {
        setState(() {
          _error = 'New passwords don\'t match.';
          _saving = false;
        });
        return;
      }
      patch['currentPassword'] = _currentPwCtrl.text;
      patch['newPassword'] = _newPwCtrl.text;
    }
    if (patch.isEmpty) {
      // Nothing to do — just close the dialog quietly.
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      await ref.read(usersApiProvider).updateProfile(patch);
      await ref.read(authProvider.notifier).refreshProfile();
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e, st) {
      logRawError('edit_profile.save', e, st);
      if (!mounted) return;
      setState(() {
        _error = politeMessageFor(e, context: ErrorContext.action);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Sign in first.'),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const Divider(height: 32),
          const _SectionLabel('Display name'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            enabled: !_saving,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Avatar'),
          const SizedBox(height: 6),
          TextField(
            controller: _avatarCtrl,
            enabled: !_saving,
            maxLength: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              counterText: '',
              hintText: '🐣',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _avatarChoices)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _saving
                      ? null
                      : () => setState(() => _avatarCtrl.text = e),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _avatarCtrl.text == e
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _avatarCtrl.text == e
                            ? scheme.primary
                            : scheme.outline.withValues(alpha: 0.3),
                        width: _avatarCtrl.text == e ? 2 : 1,
                      ),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Photo upload comes later — for now pick an emoji.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Gender'),
          const SizedBox(height: 6),
          RadioGroup<String>(
            groupValue: _gender,
            onChanged: (v) {
              if (!_saving && v != null) setState(() => _gender = v);
            },
            child: Column(
              children: [
                for (final g in _genders)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: g.$1,
                    title: Text(g.$2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Change password'),
          const SizedBox(height: 4),
          Text(
            'Leave blank to keep your current password.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _currentPwCtrl,
            enabled: !_saving,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              labelText: 'Current password',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPwCtrl,
            enabled: !_saving,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              labelText: 'New password (≥ 8 chars)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPwCtrl,
            enabled: !_saving,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              labelText: 'Confirm new password',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            PoliteBanner(text: _error!),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'EditorialMono',
        fontSize: 11,
        letterSpacing: 1.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

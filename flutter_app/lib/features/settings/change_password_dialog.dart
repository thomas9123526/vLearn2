import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';

Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      return Dialog(
        insetPadding: EdgeInsets.fromLTRB(24, 48, 24, bottom > 0 ? bottom + 8 : 48),
        child: const SizedBox(width: 460, child: _ChangePasswordBody()),
      );
    },
  );
}

class _ChangePasswordBody extends ConsumerStatefulWidget {
  const _ChangePasswordBody();

  @override
  ConsumerState<_ChangePasswordBody> createState() => _ChangePasswordBodyState();
}

class _ChangePasswordBodyState extends ConsumerState<_ChangePasswordBody> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_currentCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'New passwords don\'t match.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(usersApiProvider).updateProfile({
        'currentPassword': _currentCtrl.text,
        'newPassword': _newCtrl.text,
      });
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e, st) {
      logRawError('change_password.save', e, st);
      if (!mounted) return;
      setState(() {
        _error = politeMessageFor(e, context: ErrorContext.action);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Change password',
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
          const Divider(height: 28),
          TextField(
            controller: _currentCtrl,
            enabled: !_saving,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              labelText: 'Current password',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newCtrl,
            enabled: !_saving,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              labelText: 'New password (≥ 6 chars)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            enabled: !_saving,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saving ? null : _save(),
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
                    : const Text('Update password'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

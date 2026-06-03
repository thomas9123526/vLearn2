import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/app_apis.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';

/// Profile-edit dialog shown when the user taps the profile tile in Settings.
/// Lets the user change display name, avatar emoji, and gender.
/// Password changes use the separate showChangePasswordDialog.
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

  String _gender = 'female';
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  static const _genders = [
    ('female', 'Female'),
    ('male', 'Male'),
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
      final g = user.gender;
      _gender = (g == 'male' || g == 'female') ? g : 'female';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_uploading || _saving) return;
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref.read(usersApiProvider).uploadAvatar(
            filePath: picked.path,
            filename: picked.name,
          );
      await ref.read(authProvider.notifier).refreshProfile();
    } on Exception catch (e, st) {
      logRawError('edit_profile.avatar_upload', e, st);
      if (!mounted) return;
      setState(() {
        _error = politeMessageFor(e, context: ErrorContext.action);
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
            user.email ?? '',
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
          const _SectionLabel('Photo'),
          const SizedBox(height: 8),
          Row(
            children: [
              // Live preview. avatar_url > avatar_emoji.
              _AvatarPreview(
                user: user,
                uploading: _uploading,
                fallbackEmoji: _avatarCtrl.text,
                scheme: scheme,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                          onPressed: (_saving || _uploading)
                              ? null
                              : () => _pickAndUpload(ImageSource.camera),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                          onPressed: (_saving || _uploading)
                              ? null
                              : () => _pickAndUpload(ImageSource.gallery),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload replaces the emoji avatar everywhere — admin panel, chat bubbles, settings.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Emoji fallback'),
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

/// Round preview that mirrors what the rest of the app will render
/// after upload. While [uploading] is true the spinner sits over
/// whatever the current source is (uploaded photo > emoji).
class _AvatarPreview extends ConsumerStatefulWidget {
  const _AvatarPreview({
    required this.user,
    required this.uploading,
    required this.fallbackEmoji,
    required this.scheme,
  });

  final dynamic user; // UserProfile — kept dynamic to avoid widening imports
  final bool uploading;
  final String fallbackEmoji;
  final ColorScheme scheme;

  @override
  ConsumerState<_AvatarPreview> createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends ConsumerState<_AvatarPreview> {
  bool _imageError = false;

  @override
  void didUpdateWidget(_AvatarPreview old) {
    super.didUpdateWidget(old);
    // Reset error when the URL changes (e.g. after a successful upload).
    if (old.user.avatarUrl != widget.user.avatarUrl) {
      _imageError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.user.avatarUrl as String?;
    // avatar_url comes from the backend as `/uploads/avatars/<file>`.
    // Prepend the Dio base URL so NetworkImage can resolve it.
    final fullUrl = (!_imageError && url != null && url.isNotEmpty)
        ? _resolveAvatarUrl(url)
        : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: widget.scheme.primaryContainer,
          backgroundImage: fullUrl != null ? NetworkImage(fullUrl) : null,
          onBackgroundImageError: fullUrl != null
              ? (_, _) => setState(() => _imageError = true)
              : null,
          child: fullUrl == null
              ? Text(
                  widget.fallbackEmoji.isEmpty ? '🐣' : widget.fallbackEmoji,
                  style: const TextStyle(fontSize: 28),
                )
              : null,
        ),
        if (widget.uploading)
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
      ],
    );
  }

  /// Joins the relative `/uploads/...` path with the configured backend
  /// origin so NetworkImage gets a fully-qualified URL.
  String _resolveAvatarUrl(String relative) {
    if (relative.startsWith('http')) return relative;
    final base = (ref.read(appConfigProvider).asData?.value ?? AppConfig.defaults).backendBaseUrl;
    // strip the /vfls or /api suffix from the API base — uploads sit
    // at the server root, not behind the /api prefix.
    final origin = _stripApiSuffix(base);
    return '$origin$relative';
  }

  String _stripApiSuffix(String base) {
    final marker = base.indexOf('/api');
    final cut = marker > 0 ? base.substring(0, marker) : base;
    final marker2 = cut.indexOf('/vfls');
    return marker2 > 0 ? cut.substring(0, marker2) : cut;
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

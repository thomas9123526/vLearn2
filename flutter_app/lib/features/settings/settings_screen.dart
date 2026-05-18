import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/storage/model_registry.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/bubble_style.dart';
import '../../core/theme/font_group.dart';
import '../../features/conversation/widgets/chat_bubble.dart';
import '../../core/models/models.dart';
import 'edit_profile_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final settings = ref.watch(appSettingsProvider);
    final fontGroup = ref.watch(fontGroupProvider);
    final bubbleStyle = ref.watch(bubbleStyleProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (user != null)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text(user.avatarEmoji, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(user.displayName),
              subtitle: Text(user.email),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => showEditProfileDialog(context),
            ),
          const Divider(),
          const _SectionHeader(text: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(settings.theme),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: Text(_languageLabel(settings.uiLanguage)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, ref),
          ),
          const _SectionHeader(text: 'Font'),
          ListTile(
            leading: const Icon(Icons.text_fields_outlined),
            title: const Text('Font group'),
            subtitle: Text(fontGroup.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickFontGroup(context, ref, fontGroup),
          ),
          const _SectionHeader(text: 'Conversation'),
          ListTile(
            leading: Icon(
              settings.defaultConversationMode == 'face'
                  ? Icons.face_retouching_natural
                  : Icons.chat_bubble_outline,
            ),
            title: const Text('Default mode'),
            subtitle: Text(
              settings.defaultConversationMode == 'face'
                  ? 'Tutor mode (face-to-face)'
                  : 'Chat mode',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickDefaultMode(
              context,
              ref,
              settings.defaultConversationMode,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Bubble style'),
            subtitle: Text(bubbleStyle.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickBubbleStyle(context, ref, bubbleStyle),
          ),
          const Divider(),
          const _SectionHeader(text: 'Storage'),
          const _ModelStorageTile(),
          const Divider(),
          const _SectionHeader(text: 'Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sign out'),
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  String _languageLabel(String code) => switch (code) {
        'ko' => '한국어',
        'zh' => '中文',
        _ => 'English',
      };

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final current = ref.read(appSettingsProvider).theme;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Choose theme',
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              for (final key in const ['apricot', 'sage', 'iris', 'obsidian'])
                _ThemeTile(
                  themeKey: key,
                  isSelected: key == current,
                  onTap: () => Navigator.pop(sheetCtx, key),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(appSettingsProvider.notifier).setTheme(picked);
    }
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final l in const [('en', 'English'), ('ko', '한국어'), ('zh', '中文')])
            ListTile(
              title: Text(l.$2),
              onTap: () => Navigator.pop(context, l.$1),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(appSettingsProvider.notifier).setUiLanguage(picked);
    }
  }

  Future<void> _pickFontGroup(
    BuildContext context,
    WidgetRef ref,
    FontGroup current,
  ) async {
    final picked = await showModalBottomSheet<FontGroup>(
      context: context,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final g in FontGroup.values)
                ListTile(
                  title: Text(
                    g.displayName,
                    style: TextStyle(
                      fontFamily: g.families.heading,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The quick brown fox jumps',
                        style: TextStyle(fontFamily: g.families.body, fontSize: 14),
                      ),
                      Text(
                        'v1.0.0  •  ${g.description}',
                        style: TextStyle(
                          fontFamily: g.families.mono,
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  trailing: g == current
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, g),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      await ref.read(appSettingsProvider.notifier).setFontGroup(picked);
    }
  }

  Future<void> _pickDefaultMode(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        final scheme = Theme.of(sheetCtx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.face_retouching_natural),
                title: const Text('Tutor mode (face-to-face)'),
                subtitle: const Text(
                  'Speak with the animated tutor. The tutor speaks back.',
                ),
                trailing: current == 'face'
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => Navigator.pop(sheetCtx, 'face'),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chat mode'),
                subtitle: const Text('Type back and forth with the tutor.'),
                trailing: current == 'chat'
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => Navigator.pop(sheetCtx, 'chat'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      await ref
          .read(appSettingsProvider.notifier)
          .setDefaultConversationMode(picked);
    }
  }

  Future<void> _pickBubbleStyle(
    BuildContext context,
    WidgetRef ref,
    BubbleStyle current,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final sampleAssistant = ConversationMessage(
      id: '_preview_a',
      role: 'assistant',
      content: 'Hi! How are you today?',
      sequence: 0,
      createdAt: now,
    );
    final sampleUser = ConversationMessage(
      id: '_preview_u',
      role: 'user',
      content: "I'm great, thanks!",
      sequence: 1,
      createdAt: now,
    );

    final picked = await showModalBottomSheet<BubbleStyle>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final s in BubbleStyle.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: InkWell(
                    onTap: () => Navigator.pop(sheetContext, s),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: s == current ? scheme.primary : scheme.outline,
                          width: s == current ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.displayName,
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              if (s == current)
                                Icon(Icons.check_circle,
                                    color: scheme.primary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ChatBubble(message: sampleAssistant, style: s),
                          ChatBubble(message: sampleUser, style: s),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      await ref.read(appSettingsProvider.notifier).setBubbleStyle(picked);
    }
  }
}

class _ModelStorageTile extends ConsumerWidget {
  const _ModelStorageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(modelRegistrySnapshotProvider);
    final scheme = Theme.of(context).colorScheme;
    return snap.when(
      loading: () => const ListTile(
        leading: Icon(Icons.storage_outlined),
        title: Text('Speech models'),
        subtitle: Text('Checking…'),
      ),
      error: (e, st) {
        logRawError('settings_screen.model_registry', e, st);
        return ListTile(
          leading: Icon(Icons.storage_outlined, color: scheme.onSurfaceVariant),
          title: const Text('Speech models'),
          subtitle: Text(politeMessageFor(e, context: ErrorContext.loadDetail)),
        );
      },
      data: (s) {
        final okCount = s.verifications
            .where((v) => v.status == FileVerificationStatus.ok)
            .length;
        final totalCount = s.verifications.length;
        final subtitle = switch (s.status) {
          ModelRegistryStatus.ready => '$okCount/$totalCount files verified',
          ModelRegistryStatus.corrupt => 'Bundle corrupted ($okCount/$totalCount ok)',
          ModelRegistryStatus.manifestMissing => 'manifest.json not found',
          ModelRegistryStatus.notReady => 'Not ready',
        };
        return Column(
          children: [
            ListTile(
              leading: Icon(
                s.isReady ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                color: s.isReady ? Colors.green : scheme.error,
              ),
              title: const Text('Speech models'),
              subtitle: Text(subtitle),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Model folder'),
              subtitle: SelectableText(
                s.modelRoot,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-verify all'),
                      onPressed: () =>
                          ref.invalidate(modelRegistrySnapshotProvider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Setup screen'),
                      onPressed: () => context.push('/setup/models'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

/// One row in the theme picker sheet. Shows the theme's actual colors so the
/// user can tell what each theme will look like before selecting it.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.themeKey,
    required this.isSelected,
    required this.onTap,
  });

  final String themeKey;
  final bool isSelected;
  final VoidCallback onTap;

  static const _labels = <String, String>{
    'apricot': 'Apricot',
    'sage': 'Sage',
    'iris': 'Iris',
    'obsidian': 'Obsidian',
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.byKey[themeKey]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? palette.primary : palette.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Three colour dots: primary → accent → surface variant
              _Dot(color: palette.primary, size: 28),
              const SizedBox(width: 6),
              _Dot(color: palette.accent, size: 20),
              const SizedBox(width: 6),
              _Dot(color: palette.surfaceVariant, size: 14, border: palette.outline),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _labels[themeKey] ?? themeKey,
                  style: TextStyle(
                    color: palette.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: palette.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, this.border});
  final Color color;
  final double size;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border != null ? Border.all(color: border!) : null,
      ),
    );
  }
}

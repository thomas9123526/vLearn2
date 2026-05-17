import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/storage/model_registry.dart';
import '../../core/theme/bubble_style.dart';
import '../../core/theme/font_group.dart';
import '../../features/conversation/widgets/chat_bubble.dart';
import '../../core/models/models.dart';

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
          const _SectionHeader(text: 'Network'),
          SwitchListTile(
            secondary: const Icon(Icons.compress_outlined),
            title: const Text('Compress large responses'),
            subtitle: const Text(
              'Save bandwidth by compressing responses larger than 100 KB.',
            ),
            value: settings.compressionEnabled,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setCompressionEnabled(v),
          ),
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
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final t in const ['apricot', 'sage', 'iris', 'obsidian'])
            ListTile(title: Text(t), onTap: () => Navigator.pop(context, t)),
        ],
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
      error: (e, _) => ListTile(
        leading: Icon(Icons.storage_outlined, color: scheme.error),
        title: const Text('Speech models'),
        subtitle: Text('Error: $e'),
      ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final settings = ref.watch(appSettingsProvider);
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
          const _SectionHeader(text:'Appearance'),
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
          const Divider(),
          const _SectionHeader(text:'Network'),
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
          const _SectionHeader(text:'Account'),
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

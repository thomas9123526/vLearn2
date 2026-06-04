import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/models/models.dart';
import '../../core/providers/settings_provider.dart';
import 'news_providers.dart';

class NewsListScreen extends ConsumerWidget {
  const NewsListScreen({super.key});

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(newsApiProvider).markAllRead();
      ref.invalidate(newsListProvider);
      await ref.read(unreadNewsCountProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked all news as read.')),
        );
      }
    } catch (e, st) {
      if (context.mounted) {
        showPoliteErrorSnack(
          context,
          e,
          tag: 'news_list.mark_all_read',
          stack: st,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(newsListProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllRead(context, ref),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: list.when(
          loading: () => const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          ),
          error: (e, st) {
            logRawError('news_list_screen', e, st);
            return PoliteErrorCenter(
              key: const ValueKey('error'),
              error: e,
              context: ErrorContext.loadList,
              onRetry: () => ref.invalidate(newsListProvider),
            );
          },
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                key: ValueKey('empty'),
                child: Text('No news yet.'),
              );
            }
            return RefreshIndicator(
              key: const ValueKey('list'),
              onRefresh: () async {
                ref.invalidate(newsListProvider);
                await ref.read(newsListProvider.future);
                await ref.read(unreadNewsCountProvider.notifier).refresh();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _NewsListTile(
                  post: items[i],
                  lang: lang,
                  onTap: () => context.push('/news/${items[i].slug}'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NewsListTile extends StatelessWidget {
  const _NewsListTile({
    required this.post,
    required this.lang,
    required this.onTap,
  });

  final NewsPost post;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = post.titleFor(lang);
    final summary = post.summaryFor(lang) ?? post.bodyFor(lang);
    return Material(
      color: post.read ? scheme.surface : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (post.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _ImageFallback(scheme: scheme),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (post.pinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: scheme.primary,
                            ),
                          ),
                        if (!post.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.article_outlined, color: scheme.onPrimaryContainer),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/settings_provider.dart';
import 'news_providers.dart';

/// Single news post viewer. Body is rendered as plain text — the spec calls
/// for markdown via `flutter_markdown`, deferred until that dep is bundled.
class NewsDetailScreen extends ConsumerWidget {
  const NewsDetailScreen({required this.idOrSlug, super.key});

  final String idOrSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(newsDetailProvider(idOrSlug));
    final lang = ref.watch(localeProvider).languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logRawError('news_detail_screen', e, st);
          return PoliteErrorCenter(
            error: e,
            context: ErrorContext.loadDetail,
            onRetry: () => ref.invalidate(newsDetailProvider(idOrSlug)),
          );
        },
        data: (post) {
          final title = post.titleFor(lang);
          final body = post.bodyFor(lang);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: scheme.primaryContainer,
                          alignment: Alignment.center,
                          child: Icon(Icons.image_not_supported,
                              color: scheme.onPrimaryContainer),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (post.publishedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMMd().format(post.publishedAt!.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

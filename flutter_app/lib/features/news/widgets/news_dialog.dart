import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/app_apis.dart';
import '../../../core/errors/polite_error.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/settings_provider.dart';
import '../news_providers.dart';

/// Modal news viewer launched from the home-screen bell icon.
///
/// Port of the `NotifModal` flow in
/// `vLearn2Spec/design_handoff_freetalk/reference/screens.jsx`:
///
/// * Tap the bell → dialog shows a list of posts (newest first, unread
///   highlighted).
/// * Tap a post → swaps to the detail view inside the same modal.
/// * Back arrow from detail → list. Close button → dismiss the modal.
///
/// Stays on top of whatever route the user is on (it's pushed onto the
/// root navigator by `showDialog`, so it doesn't fight with the shell's
/// nested Navigator).
/// Open the news modal. If [initialSlug] is supplied the dialog opens
/// directly on that post's detail view; otherwise it opens on the list.
Future<void> showNewsDialog(BuildContext context, {String? initialSlug}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _NewsDialog(initialSlug: initialSlug),
  );
}

class _NewsDialog extends ConsumerStatefulWidget {
  const _NewsDialog({this.initialSlug});
  final String? initialSlug;

  @override
  ConsumerState<_NewsDialog> createState() => _NewsDialogState();
}

class _NewsDialogState extends ConsumerState<_NewsDialog> {
  /// `null` => list view; non-null => detail view of that post's slug.
  late String? _activeSlug = widget.initialSlug;

  @override
  void initState() {
    super.initState();
    // newsListProvider is a FutureProvider that would otherwise cache
    // whatever it fetched at first build — so a post published after
    // the app loaded never appears here, even though the bell badge
    // sees it (the unread-count poller refreshes every 60s).
    // Force a fresh fetch every time the dialog opens, and prod the
    // unread counter at the same time so the header subtitle is
    // in sync with the list body.
    Future.microtask(() {
      if (!mounted) return;
      ref.invalidate(newsListProvider);
      ref.read(unreadNewsCountProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 16,
        vertical: 48,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: scheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height - 96,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              activeSlug: _activeSlug,
              onBack: () => setState(() => _activeSlug = null),
              onClose: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 1),
            Flexible(
              child: _activeSlug == null
                  ? _NewsListBody(
                      onOpen: (slug) => setState(() => _activeSlug = slug),
                    )
                  : _NewsDetailBody(idOrSlug: _activeSlug!),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.activeSlug,
    required this.onBack,
    required this.onClose,
  });
  final String? activeSlug;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final listAsync = ref.watch(newsListProvider);
    final unread = ref.watch(unreadNewsCountProvider);

    final subtitle = activeSlug != null
        ? 'News'
        : listAsync.maybeWhen(
            data: (items) => '${items.length} update${items.length == 1 ? '' : 's'}',
            orElse: () => 'Loading…',
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      child: Row(
        children: [
          if (activeSlug != null)
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_outlined, color: scheme.primary),
                  if (unread > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeSlug != null ? 'News' : 'Updates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (activeSlug == null)
            IconButton(
              tooltip: 'Mark all read',
              icon: const Icon(Icons.done_all),
              onPressed: () => _markAllRead(context, ref),
            ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(newsApiProvider).markAllRead();
      ref.invalidate(newsListProvider);
      await ref.read(unreadNewsCountProvider.notifier).refresh();
    } on Exception catch (e, st) {
      if (context.mounted) {
        showPoliteErrorSnack(
          context,
          e,
          tag: 'news_dialog.mark_all_read',
          stack: st,
        );
      }
    }
  }
}

class _NewsListBody extends ConsumerWidget {
  const _NewsListBody({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(newsListProvider);
    final lang = ref.watch(localeProvider).languageCode;
    return list.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) {
        logRawError('news_dialog.list', e, st);
        return PoliteErrorCenter(
          error: e,
          context: ErrorContext.loadList,
          onRetry: () => ref.invalidate(newsListProvider),
        );
      },
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No news yet.')),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _NewsTile(
            post: items[i],
            lang: lang,
            onTap: () => onOpen(items[i].slug),
          ),
        );
      },
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _TileFallback(scheme: scheme),
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
                            size: 13,
                            color: scheme.primary,
                          ),
                        ),
                      if (!post.read)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: post.read
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
    );
  }
}

class _TileFallback extends StatelessWidget {
  const _TileFallback({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.article_outlined, color: scheme.onPrimaryContainer),
    );
  }
}

class _NewsDetailBody extends ConsumerWidget {
  const _NewsDetailBody({required this.idOrSlug});
  final String idOrSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(newsDetailProvider(idOrSlug));
    final lang = ref.watch(localeProvider).languageCode;
    final scheme = Theme.of(context).colorScheme;
    return detail.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) {
        logRawError('news_dialog.detail', e, st);
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.imageUrl != null) ...[
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
                        child: Icon(
                          Icons.image_not_supported,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              const SizedBox(height: 12),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

# 09 — News on home screen via dialog

## Task

> Is the app shows news for news table?
> If not implemented, plz implement the news logic.
> You can find design in
> "C:\project\vLearn2\vLearn2Spec\design_handoff_freetalk"
> on home screen. New are showing via dialog.

## Audit before the change

News **was** rendered, but not the way the design specifies. State of
the world before this commit:

| Surface | Mode |
|---|---|
| Home AppBar bell (`features/news/widgets/bell_icon.dart`) | Pushed `/news` as a **full-screen route** (`NewsListScreen`) |
| Home news strip (`features/news/widgets/news_strip.dart`) | Tapping a card pushed `/news/$slug` as a **full-screen route** (`NewsDetailScreen`) |
| Design (`vLearn2Spec/.../screens.jsx`, `NotifModal`) | **Dialog overlay** containing list + in-place detail |

So the data plumbing — `newsListProvider`, `newsDetailProvider`,
`unreadNewsCountProvider`, the unread-count poll, mark-all-read,
mark-read-on-detail-view — was already there and working. What
mismatched the design was the *container*: full-screen routes
instead of a modal.

## What I built

New widget: **`flutter_app/lib/features/news/widgets/news_dialog.dart`**.

```dart
Future<void> showNewsDialog(BuildContext context, {String? initialSlug});
```

It opens a centered `Dialog` (root navigator, no shell-pop issues)
that:

- **Renders a list view by default**, mirroring `NotifModal` in
  `screens.jsx`. Each post tile shows the optional thumbnail
  (`56×56`), the title, the summary, an unread dot, a pin icon for
  pinned posts, and the date.
- **Swaps to an in-place detail view** when a tile is tapped — same
  modal, body replaced. Hits `newsDetailProvider(slug)` which
  re-uses the existing read-marker side effect (server marks the
  post read; `unreadNewsCountProvider` refreshes, badge updates).
- **Header switches modes**: list mode shows the bell icon with
  unread badge, "Updates", count subtitle, "Mark all read", and
  close. Detail mode swaps the bell for a back arrow (returns to
  the list view inside the same dialog) and keeps the close button.
- **Optional `initialSlug` param** so tapping a news-strip card opens
  the dialog already on that post's detail — the strip used to push
  `/news/$slug`; now it calls `showNewsDialog(context, initialSlug: post.slug)`
  and lands the user in the same place visually.
- **Width-responsive insetPadding** — wider gutter on desktop
  (`>= 720`), tighter on mobile. `maxWidth: 560` keeps the line
  length comfortable on big windows.

## Files touched

- **`flutter_app/lib/features/news/widgets/news_dialog.dart`** — new.
- **`flutter_app/lib/features/news/widgets/bell_icon.dart`** —
  swapped `context.push('/news')` for `showNewsDialog(context)`.
  Dropped the `go_router` import (no longer needed); added
  `news_dialog.dart`.
- **`flutter_app/lib/features/news/widgets/news_strip.dart`** —
  swapped `context.push('/news/${post.slug}')` for
  `showNewsDialog(context, initialSlug: post.slug)`. Dropped the
  `go_router` import.

## What I deliberately did NOT do

- **Did not remove** `news_list_screen.dart` or `news_detail_screen.dart`
  or the `/news` / `/news/:idOrSlug` routes in `app_router.dart`. The
  fullscreen screens are now dead code on the bell + strip flow, but
  removing them would also remove the routes' ability to handle deep
  links (e.g., a push notification carrying a news slug). Cheap to
  keep; easy to delete in a follow-up if confirmed unused.
- **Did not move the news-strip to "tile opens dialog and
  initial-slug=null"** — preserving the "this card → that detail"
  affordance felt right; users who tap a specific card expect to land
  on that specific post, not a list of everything.
- **Did not migrate to `flutter_markdown`** for the body. The detail
  view body is still rendered as plain `Text` — same behavior the
  fullscreen detail screen had. Easy upgrade once that dep is bundled.
- **Did not change `LayoutVisibility(configKey: 'home.news_strip')`**
  — the news strip still respects the admin's flag.

## Verification

- `flutter analyze` on the three touched files: **clean**.
- `bell_icon.dart`, `news_strip.dart` now compile without `go_router`
  imports (both warned as unused after the switch; cleaned up).
- The dialog uses the dialog's own builder context for its
  Navigator.pop (we learned that lesson in the
  `delete-dialog-wrong-navigator` fix). No shell-tab teardown risk.

## How it behaves now

1. User taps the bell on the home AppBar.
   → `showNewsDialog(context)` → modal opens to the list view.
2. User taps a post tile.
   → Same modal swaps to the detail view; server marks the post
     read; the bell badge decrements.
3. User taps the back arrow.
   → Detail view goes away, list view returns (same modal).
4. User taps the close icon (or the barrier outside the panel).
   → Dialog dismisses, user is back on the home screen
     untouched.

For the strip on the home body:

5. User taps a strip card.
   → `showNewsDialog(context, initialSlug: slug)` → modal opens
     directly on that post's detail view.

## Files inspected

- `vLearn2Spec/design_handoff_freetalk/reference/screens.jsx` (NotifModal)
- `flutter_app/lib/features/news/widgets/bell_icon.dart`
- `flutter_app/lib/features/news/widgets/news_strip.dart`
- `flutter_app/lib/features/news/news_list_screen.dart`
- `flutter_app/lib/features/news/news_detail_screen.dart`
- `flutter_app/lib/features/news/news_providers.dart`
- `flutter_app/lib/features/home/home_screen.dart`
- `flutter_app/lib/core/router/app_router.dart`

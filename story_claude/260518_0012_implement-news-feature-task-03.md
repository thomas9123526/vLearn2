# Implement 03_news_feature — full vertical slice

## What this task did

Delivered the news feature end-to-end per [todoList/0517_v2/03_news_feature.md](../todoList/0517_v2/03_news_feature.md):

### Backend
- Two new entities (`NewsPostEntity`, `NewsReadStatusEntity`) with the compound-PK "absence = unread" pattern
- Migration `1716000000000-news-tables` with both tables, status+pinned partial index, FKs
- 4 new permissions in the catalog (`news.view/edit/delete/upload_image`), all grantable to subadmins, with `implies` chains
- New `NewsModule` with `NewsService`, user-facing `NewsController`, admin `AdminNewsController` (gated by `@RequirePermission`)
- 10 endpoints total: 5 user-facing + 6 admin (counting `:id/publish` etc.)
- New seed flag `home.news_strip` so admins can hide the home strip

### Flutter
- `NewsApi` Dio client + `newsApiProvider`
- `NewsPost` model with i18n resolver (English fallback)
- `newsListProvider` + `unreadNewsCountProvider` (60s poll, error-swallowing, retains previous value)
- `news_list_screen.dart` with pull-to-refresh + "Mark all read" + pinned/unread visual states
- `news_detail_screen.dart` with hero image / title / date / body
- `news_strip.dart` for the horizontal home-screen scroller
- `bell_icon.dart` with red badge ("99+" cap)
- Home screen now has an AppBar with the bell + a news strip slotted above quick-stats; both wrapped in `LayoutVisibility` so admins can hide them via the existing flag system
- `/news` and `/news/:idOrSlug` routes
- 5 i18n keys across en/ko/zh

### Out of scope (documented in report)
- Image upload endpoint and the markdown renderer for detail bodies
- Audit logging on admin writes
- Admin panel CRUD page (deferred to task 02, Next.js sibling project)

## Report

[todoList_report/0517_v2/03_news_feature.md](../todoList_report/0517_v2/03_news_feature.md)

## User prompt (verbatim)

> For every txt files inside todoList\\0517_v2 folder, plz do the todo List one by one.
> After you have done task, produce report what you have done and save as md format to "todoList_report\\0517_v2" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
> You have many times. take it easy.
> Quality is important.

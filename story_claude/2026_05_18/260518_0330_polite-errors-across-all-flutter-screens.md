# Polite, green error UX across every Flutter screen

## What this task did

Generalized the signin-screen polite-error pattern (commit `030ba1c`) to
every Flutter screen that previously displayed `'Failed to load: $e'` or
`'Send failed: $e'`-style raw DioException messages. Users now see a soft
green banner with one of a small set of friendly sentences chosen by the
error's type; the raw error still goes to the debug console for developers.

### New shared module

[lib/core/errors/polite_error.dart](../flutter_app/lib/core/errors/polite_error.dart) — single source of truth:

- `politeMessageFor(Object error, {ErrorContext context = generic})` —
  returns a short friendly sentence. Dispatch order:
  1. `DioExceptionType` (connection/timeout/cancel/badCertificate)
  2. HTTP status code (401 / 403 / 404 / 409 / 422 / 400 / 429 / 5xx),
     extracted from `ApiException.statusCode` or
     `DioException.response.statusCode`
  3. Known i18n keys: `auth.invalid_credentials`, `account.suspended`,
     `account.deleted`, `auth.email_taken`
  4. Context-flavoured fallback (`loadList`, `loadDetail`, `send`,
     `action`, `signIn`, `generic`)
- `logRawError(tag, error, [stack])` — `developer.log` + `debugPrint`
  with a screen tag. Stripped in release.
- `PoliteBanner({text, icon})` — soft green inline container (the same
  one signin uses).
- `PoliteErrorCenter({error, context, onRetry})` — full-page centered
  variant with optional "Try again" button.
- `showPoliteErrorSnack(context, error, {tag, errorContext, stack})` —
  green floating SnackBar; logs raw before showing.

Colors are unified light/dark green palette so the UX is consistent
across signin and the rest of the app.

### Screens swept

| Screen | What changed |
|---|---|
| [sign_in_screen](../flutter_app/lib/features/auth/sign_in_screen.dart) | Refactored to import the shared module — removed the duplicated `_PoliteBanner` + `_politeFor` it had as a one-off. |
| [scenarios_screen](../flutter_app/lib/features/scenarios/scenarios_screen.dart) | List error → `PoliteErrorCenter` with retry; `_startSession` failure → `showPoliteErrorSnack`. |
| [home_screen](../flutter_app/lib/features/home/home_screen.dart) | "Recommended scenarios" tile error → inline `PoliteBanner`. Removed the now-unused `_ErrorTile` class. |
| [news_list_screen](../flutter_app/lib/features/news/news_list_screen.dart) | List error → `PoliteErrorCenter` with retry; "mark all read" failure → `showPoliteErrorSnack`. |
| [news_detail_screen](../flutter_app/lib/features/news/news_detail_screen.dart) | Detail error → `PoliteErrorCenter` with retry. |
| [conversation_screen](../flutter_app/lib/features/conversation/conversation_screen.dart) | Three sites: load error → `PoliteErrorCenter` with retry; send failure → `showPoliteErrorSnack` (`ErrorContext.send`); end failure → `showPoliteErrorSnack`. |
| [session_report_screen](../flutter_app/lib/features/report/session_report_screen.dart) | Report load error → `PoliteErrorCenter` with retry. |
| [settings_screen](../flutter_app/lib/features/settings/settings_screen.dart) | Model-registry error tile now uses `politeMessageFor` + neutral icon (no red), and `logRawError` for the raw. |
| [models_not_installed_screen](../flutter_app/lib/features/setup/models_not_installed_screen.dart) | Read-failure path → `PoliteErrorCenter` with retry. |

### What users see now

- **No more `DioException [bad response]: Unauthorized` walls of text** —
  anywhere.
- **One of ~10 polite sentences** depending on error class. Most common:
  - "Couldn't reach the server. Check your connection and try again." (timeouts / no DNS)
  - "You need to sign in again." (401 from any screen besides signin)
  - "We couldn't find that. It may have been removed." (404 on detail pages)
  - "Couldn't load this list. Pull to refresh." (loadList fallback)
  - "Something went wrong on our side. Please try again in a moment." (5xx)
- **Soft green look** (icon, light bg, dark green text) so the banner reads
  as informative-and-recoverable rather than alarming.
- **A "Try again" button** on every full-page error state (where it makes
  sense — provider invalidation is the retry mechanism).

### What developers see now

Every error path logs the raw error to the debug console with a screen tag:

```
[scenarios_screen] DioException [bad response]: …
[conversation_screen.send] DioException [connection error]: …
[news_list_screen] ApiException(404 "news.not_found"): …
```

`flutter run` terminal + DevTools both show the structured log. None of
this is visible to end users in release.

## Conversation summary

- User: *"at the signin screen on the application, when there's error
  occurs because password is not correct or user credentials is not
  correct, DioException error message shows. It looks bad. So I want
  you to don't show this bad look message and show polite and green
  message based on the error types. I want do this all over the screens."*
- Prior task (commit `030ba1c`) implemented this for the signin screen
  only with locally-duplicated logic. This task lifts that into a
  shared module and applies it everywhere.

## Decisions / call-outs

- **Generic helper, not per-screen copies.** Every screen reuses the
  same translator + widgets so the UX stays consistent and future
  screens get polite errors for free.
- **`ErrorContext` enum disambiguates fallback copy** for screens where
  the error doesn't match a specific status code. `send` reads naturally
  for the chat input, `loadDetail` for a single-item page, `loadList`
  for feeds, etc.
- **Status detection unwraps `DioException.error` if it's an
  `ApiException`.** The `ErrorInterceptor` wraps Dio errors in
  `ApiException` and re-rejects with a new `DioException`, so the actual
  status lives one nest deep. Both layers are checked.
- **Did NOT change the auth provider's error storage** — the signin
  screen still reads `auth.errorMessage` (a toString()) and translates
  via `politeMessageFor`. This is consistent with the previous
  task's scope decision; keeps the provider unaware of UX concerns.
- **Did NOT touch the admin panel** — the user's request was
  specifically about the Flutter app's screens. The admin panel has
  its own error display patterns; could be a future task.
- **Did NOT replace SnackBars for *success* cases** — the news "Marked
  all news as read." SnackBar stays as-is; this task is errors only.
- **Did NOT change the AuthInterceptor's silent-retry behavior** —
  the previous "self-recover from 401" fix (commit `9a49bae`) already
  handles that. The new polite error UX wraps anything that still
  bubbles up after that recovery attempt.
- **Pre-existing analyzer info lints are unrelated.** `flutter analyze`
  flags 14 issues in this task's scope — all `info` level, none mine,
  all in untouched code (`(_, __, ___)` separator builders, etc.).

## How to verify

1. Hot-restart the Flutter app.
2. **Force a bad-credentials signin** → polite green banner shows
   "Email or password is not correct."; `flutter run` terminal shows
   `[sign_in_screen]` log lines.
3. **Stop the backend, then open Scenarios tab** → polite green
   `PoliteErrorCenter` with a "Try again" button.
4. **Start the backend back up, tap "Try again"** → list loads.
5. **Send a message during a conversation while the backend is down**
   → green floating SnackBar reading "Couldn't send your message. Try
   again."

## User prompt (verbatim)

> "at the signin screen on the application, when there's error occurs because password is not correct or user credentials is not correct,  DioException error message shows. It looks bad.
> So I want you to don't show this bad look message and show polite and green message based on the error types. "
>
> I want do this all over the screens.

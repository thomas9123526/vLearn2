# 08 — Illegal-word guard during AI chat (Flutter + backend)

## Task

> I want check if the application implement guard for illegal words on
> application side and backend side when the user chat with ai tutor.

## Verdict — **Both guards are defined but neither is invoked from the chat send path. The infrastructure exists; the call site doesn't.**

## Flutter side

### What exists

- **`flutter_app/lib/core/guard/content_guard.dart`** — defines
  `ContentGuard`, `GuardResult`, and `GuardSeverity { ok, warn, block }`.
- **Wordlists are bundled** in `flutter_app/assets/guard/`:
  `profanity_en.json`, `profanity_ko.json`, `profanity_zh.json`.
- **`ContentGuard.initialize(languages)`** loads them at boot.
- **`ContentGuard.check(text, activeLanguages)`** performs a
  word-boundary-aware match against the wordlists and returns
  `{block, warn, ok}` plus the matched terms.
- **Provider exposed**: `contentGuardProvider`.
- The doc comment on the class explicitly says:
  > Mirrors the server-side check (see
  > backend/src/guard/content-guard.service.ts) so the user gets
  > instant UX feedback. Server is authoritative — even if this
  > passes, the server re-checks.

### What doesn't exist

- **Zero call sites for `guard.check(...)` in `flutter_app/lib/features/`.**
  Greped the entire `features/` tree for `ContentGuard`,
  `contentGuard`, `guard.check`, `GuardResult`, `GuardSeverity`,
  `guard.initialize`. **No matches.**
- The conversation screen builds messages and POSTs straight to
  the backend without consulting the guard.
- `ContentGuard.initialize(...)` is never called from `main.dart`
  or any provider init, so even if a screen wanted to call
  `guard.check(...)` today, the guard would be in its "not
  initialized → fail-open" state and pass everything through.

### So in practice

The Flutter app currently sends every user-typed message
unmodified to the backend. The intended "instant UX feedback" the
class comment promises does not happen.

## Backend side

### What exists

- **`backend/src/guard/content-guard.service.ts`** —
  `ContentGuardService` with the same API shape as the Flutter
  class: `check(text, activeLanguages): GuardResult`. Same
  three-tier severity. Same normalization (lowercase, NFKC,
  combining-mark strip, whitespace collapse). Word-boundary regex
  using Unicode property escapes (\p{L}\p{N}).
- **Wordlists on disk** at `backend/src/guard/wordlists/`:
  `profanity_en.json`, `profanity_ko.json`, `profanity_zh.json`,
  plus a `custom.json` for ad-hoc terms.
- **Module wiring** in `backend/src/guard/guard.module.ts` —
  provides and exports `ContentGuardService`.
- **Unit test** at `backend/src/guard/content-guard.service.spec.ts`.
- **An entity** for storing violations:
  `vl_guard_violations` (`backend/src/database/entities/guard-violation.entity.ts`).
- **Admin endpoint** (referenced in the service header comment):
  `POST /admin/guard/reload` to reload wordlists without a
  restart.

### What doesn't exist

- **Zero invocations of `ContentGuardService.check(...)` outside
  of the service's own file and its spec test.** Grepped
  `backend/src/` for `ContentGuardService`, `guardService.check`,
  `contentGuard.check`. The only hits are the class declaration,
  the `guard.module.ts` providers list, and the spec — no service
  injects it as a dependency.
- The conversation send path in
  `backend/src/conversations/conversations.service.ts` (`sendMessage`)
  does **not** import or call the guard. Messages go straight from
  HTTP body → DB → AI provider.
- The `vl_guard_violations` table exists in the schema but no
  service inserts rows (one comment in
  `conversations.service.ts:256` mentions nulling its FK on
  session-delete — defensive code that runs if rows ever exist,
  but there's no insert path today).

### So in practice

Same as the Flutter side — the service is defined, tested,
registered, and the wordlists are on disk, but nothing along the
`POST /conversations/sessions/:id/messages` flow consults it. A
user can send any text and it lands in the DB and is forwarded to
the AI provider.

## Cross-check on the chat send path

### Flutter

`features/conversation/conversation_screen.dart` →
`messagesApiProvider.send(sessionId, text)` (via Dio) → over the
wire.

Search for `guard` in that file: no hits. Search for
`ContentGuard`: no hits.

### Backend

`POST /conversations/sessions/:id/messages`
→ `ConversationsController.sendMessage` (`conversations.module.ts:76`)
→ `ConversationsService.sendMessage` (`conversations.service.ts:124`).

Inside `sendMessage`: no `guard.check`, no
`ContentGuardService` injection, no `vl_guard_violations` insert.
The DTO is validated by `class-validator` (length, type), then the
record is persisted, then forwarded to the AI orchestrator.

## Wordlist coverage (FYI)

Both sides ship `en`, `ko`, `zh`. Backend also has a `custom.json`
for ops-managed additions; Flutter doesn't have an equivalent
extension hook beyond shipping bundle assets. That asymmetry is
fine if the server is authoritative, which is the documented
design.

## What "wiring it up" would look like (out of scope; see TL;DR)

### Flutter (instant feedback)

1. Call `ContentGuard.instance.initialize({'en'})` in `main.dart`
   before `runApp(...)` so the wordlists are ready by the time the
   chat screen mounts. ~3 lines.
2. In `conversation_screen.dart`'s `_send` handler, do
   `final res = contentGuard.check(text, activeLanguages: {nativeLang})`
   before the API call. On `block`, show a polite SnackBar and
   return early. On `warn`, you can either send anyway or show a
   confirm dialog. ~10 lines.

### Backend (authoritative)

1. `conversations.module.ts` already imports `GuardModule` (or
   needs to). Inject `ContentGuardService` into
   `ConversationsService`.
2. In `sendMessage`, call `guardService.check(dto.text, [user.uiLanguage])`
   before persisting. On `block`, throw a `BadRequestException`
   with `i18nKey: 'guard.blocked'` and insert a row into
   `vl_guard_violations` with severity + matched terms. On `warn`,
   log + insert the violation row but allow the message through
   (the admin can review).
3. Front the audit dashboard with
   `GET /admin/guard/violations` (likely already scaffolded; can
   confirm if asked).

Estimated effort: half a day, both sides, with tests.

## Files inspected (audit only; no changes)

- `flutter_app/lib/core/guard/content_guard.dart`
- `flutter_app/assets/guard/profanity_*.json`
- `flutter_app/lib/features/conversation/` (entire feature)
- `backend/src/guard/content-guard.service.ts`
- `backend/src/guard/guard.module.ts`
- `backend/src/guard/wordlists/*.json`
- `backend/src/conversations/conversations.module.ts`
- `backend/src/conversations/conversations.service.ts`
- `backend/src/database/entities/guard-violation.entity.ts`

## TL;DR

**Both sides have the guard machinery ready — class, wordlists,
provider/module wiring, even a spec test — but nothing along the
chat-send path actually calls `guard.check(...)`.** A user can
send any text today, and it reaches the AI provider unfiltered.
Both shells (Flutter widget code, backend ConversationsService)
need ~10 lines each to wire the call in. This is a *partially
implemented feature*, not a missing one.

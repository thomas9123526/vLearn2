# 11 – Security & Performance (Content Guard + Compression)

Two cross-cutting concerns that touch both backend and Flutter app:

1. **Content Guard** — block illegal / abusive language from being sent to the AI tutor (both client-side for instant UX feedback, and server-side as the authoritative gate)
2. **Network Compression** — opt-in gzip for response payloads, with a size threshold so small payloads stay uncompressed (compression overhead exceeds gain on tiny bodies)

---

## 11.1 Content Guard

### 11.1.1 Goals

- Block clearly abusive language (slurs, severe profanity, sexual content, threats) before it reaches the AI tutor
- Warn (but allow) milder profanity so the user can self-correct
- Work in **English, Korean, Chinese** at minimum
- Enforce on **both sides**: client for instant UX feedback (zero network round-trip), server as authoritative gate
- Log violations for moderation review

### 11.1.2 Non-Goals (Honest Scope)

- Not trying to defeat a determined adversary (leetspeak chains, Unicode lookalikes, image-based bypass — out of scope)
- Not trying to detect *all* hate speech contextually — that's an ML problem the small offline models won't reliably solve
- Not blocking legitimate words that contain a slur substring (e.g. "ass" → "embarrass" → must not match)

### 11.1.3 Wordlist Structure

Bundle one JSON per language in the Flutter app and ship the **same wordlists** to the backend via shared assets (copied at build time, not imported as a runtime dependency).

```
flutter_app/assets/guard/
├── profanity_en.json
├── profanity_ko.json
├── profanity_zh.json
└── custom.json            ← project-specific additions (empty by default)

backend/src/guard/wordlists/
├── profanity_en.json      ← identical content; copied at build time
├── profanity_ko.json
├── profanity_zh.json
└── custom.json
```

Schema (each language file):
```json
{
  "version": "2026.05.16",
  "language": "en",
  "block": [
    "term1", "term2", "phrase with spaces", "..."
  ],
  "warn": [
    "milder_term1", "..."
  ]
}
```

- `block` — severe terms; user message is rejected, never sent to AI
- `warn` — milder terms; user sees a warning but can override and send

### 11.1.4 Matching Algorithm

```
1. Normalize input:
   - Lowercase
   - Strip diacritics (NFD → strip combining marks)
   - Collapse whitespace
   - Keep core punctuation positions for word boundaries
2. For each (block/warn) term in active language(s):
   - If term contains spaces (multi-word phrase): substring match with word boundaries on both ends
   - If term is single word: regex \btermN\b
3. Return earliest match with severity (block wins over warn)
```

Active languages = user's UI language + English (always checked, because the conversation is English-learning).

- [ ] **11.1.4.1** Pure-Dart implementation in `flutter_app/lib/core/guard/content_guard.dart`
- [ ] **11.1.4.2** Mirror TypeScript implementation in `backend/src/guard/content-guard.service.ts`
- [ ] **11.1.4.3** Both implementations covered by unit tests with shared fixture inputs (so behavior matches)

### 11.1.5 Client-Side Integration (Flutter)

**File:** `flutter_app/lib/core/guard/content_guard.dart`

```dart
enum GuardSeverity { ok, warn, block }

class GuardResult {
  final GuardSeverity severity;
  final List<String> matchedTerms;
  final String? localizedMessage;
}

abstract class ContentGuard {
  Future<void> initialize(Set<String> languages); // loads wordlists
  GuardResult check(String text, {Set<String>? languages});
}
```

**Where it runs in the conversation flow:**

```
User types in input → debounced check (300ms) → if block: disable Send + show inline error
                                              ↓ if warn: show ⚠️ + still allow Send
                                              ↓ if ok: enable Send
User taps Send → final check on full message:
                                              ↓ if block: refuse, show modal "We can't send this"
                                              ↓ if warn (and not already acknowledged): show "Continue anyway?"
                                              ↓ if ok: POST to /conversations/.../messages
```

- [ ] **11.1.5.1** `ContentGuard` initialized at app start (after sign-in) with user's UI language + English
- [ ] **11.1.5.2** Wired into `ConversationNotifier.sendMessage()` as a pre-send check
- [ ] **11.1.5.3** Inline UI feedback in `voice_bubble.dart` input row (red border + small message on block, amber on warn)
- [ ] **11.1.5.4** Strings for blocked/warned messages localized via `app_*.arb` (see 08_i18n.md)
- [ ] **11.1.5.5** "Continue anyway?" modal for warn-tier — records user's choice for the session

### 11.1.6 Server-Side Integration (NestJS)

**File:** `backend/src/guard/content-guard.service.ts`

```typescript
@Injectable()
export class ContentGuardService {
  check(text: string, languages: string[]): GuardResult;
}
```

**Where it runs:**

```
POST /conversations/sessions/:id/messages
  ├─ guard.check(body.content, [user.ui_language, 'en'])
  ├─ if BLOCK → 422 + log to guard_violations + DO NOT call AI provider, DO NOT save message
  ├─ if WARN  → log to guard_violations with severity='warn' + proceed (server trusts client's "continue anyway")
  └─ if OK    → proceed to AI provider
```

**Response shape on block:**
```json
{
  "statusCode": 422,
  "error": "Content not allowed",
  "matchedTerms": ["..."],          // safe to expose: helps client show specific feedback
  "severity": "block",
  "i18nKey": "guard.blocked"        // client-side localization key
}
```

- [ ] **11.1.6.1** `ContentGuardService` registered in `GuardModule`, exported globally
- [ ] **11.1.6.2** Custom `@GuardContent()` decorator + `ContentGuardInterceptor` for endpoints that accept user free text (only the messages endpoint for v1)
- [ ] **11.1.6.3** Wordlists loaded into memory at boot; reload triggered by `SIGHUP` or admin endpoint (don't restart for wordlist update)
- [ ] **11.1.6.4** **Defense in depth:** even if client doesn't send a flag, server always re-checks
- [ ] **11.1.6.5** Rate limit guard violations per user (e.g. 10 blocks/hour) → temporary mute on repeated abuse

### 11.1.7 DB Table — Cross-Reference

The `guard_violations` table is defined in [02_database_schema.md](02_database_schema.md). It records every server-side block (and warn, when client forwarded one) for moderation review.

### 11.1.8 Custom Wordlist (Admin-Editable)

The `custom.json` file is intended for project-specific terms (competitor names, internal taboo terms, profanity not covered by the base lists). Empty by default. Edited in place by an admin and shipped with the next app update — OR hot-reloaded on the backend via admin endpoint without app update for backend-only severity.

- [ ] **11.1.8.1** Document the format + how to update in `docs/admin-deployment.md`
- [ ] **11.1.8.2** Admin endpoint `POST /admin/guard/reload` (auth-gated) reloads wordlists from disk

### 11.1.9 Edge Cases & Decisions

| Edge case | Decision |
|-----------|----------|
| Word with profanity substring (e.g. "Scunthorpe") | Word-boundary regex avoids matching |
| User types in romanized Korean/Chinese | Treated as English text — caught by `en` list if applicable |
| Mixed-language message | All active languages checked; first block wins |
| Very long message (>5000 chars) | Truncated to 5000 before matching (DOS guard); flagged for review |
| Unicode lookalikes (`f𝑢ck` using mathematical chars) | NFKC normalization in the pipeline catches common ones; not a full defense |
| Server wordlist newer than client wordlist | Server is authoritative; client's permissive check is fine because server re-checks |

---

## 11.2 Network Compression (Conditional Gzip)

### 11.2.1 Goals

- Reduce traffic on **large** payloads (session history exports, scenario bulk fetches)
- Avoid wasting CPU + adding ~20 bytes of gzip overhead on **small** payloads (most conversation traffic is < 1 KB per turn)
- Two modes, user-controllable in Settings:
  - **Enabled** — server compresses responses ≥ threshold (default **100 KB** per user request)
  - **Disabled** — server never compresses; client never requests compression
- Request-body compression (client → server) is **not** implemented — payloads are too small to benefit, and adds complexity

### 11.2.2 Honest Note on the 100 KB Threshold

A 100 KB threshold means *most* of this app's payloads are NOT compressed:

| Endpoint | Typical size | Compresses? |
|----------|-------------|-------------|
| `POST /conversations/.../messages` (single user msg + tutor reply) | ~1 KB | No |
| `GET /scenarios` (list, 20 items) | ~10–30 KB | No |
| `GET /scenarios/:id` (full detail) | ~3–8 KB | No |
| `GET /progress` (dashboard) | ~5–15 KB | No |
| `GET /conversations/sessions` (full history, 100 sessions) | ~80–200 KB | **Yes** when > 100 KB |
| `GET /conversations/sessions/:id` (long session, 50 turns) | ~30–80 KB | Usually no |
| `GET /conversations/sessions/:id/report` (with all metric JSONB) | ~10–25 KB | No |

The 100 KB threshold is configurable via env. If you want compression to kick in more aggressively, drop it to 4 KB — that's where the industry default sits (nginx, Apache, Express's `compression` middleware all default around there).

- [ ] **11.2.2.1** `.env`: `GZIP_THRESHOLD_BYTES=102400` (100 KB) — easy to tune without code change

### 11.2.3 Server-Side Implementation (NestJS)

**File:** `backend/src/main.ts`

```typescript
import compression from 'compression';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);
  
  app.use(compression({
    threshold: parseInt(config.get('GZIP_THRESHOLD_BYTES') ?? '102400', 10),
    filter: (req, res) => {
      // Master switch in case admin wants to force-disable globally
      if (config.get('GZIP_ENABLED') === 'false') return false;
      // Otherwise: honor client's Accept-Encoding header
      return compression.filter(req, res);
    },
    // level: 6 (default) — good balance of speed vs ratio
  }));
  
  // ... other setup
}
```

**How it actually works:**

- The `compression` middleware looks at the response body size + client's `Accept-Encoding` header
- If client sends `Accept-Encoding: gzip` AND body size ≥ threshold → compresses, adds `Content-Encoding: gzip`
- If client sends `Accept-Encoding: identity` (or omits gzip) → never compresses (regardless of size)
- If body < threshold → never compresses (regardless of client preference)

This means the **client's setting drives everything**: the client opts in by advertising `gzip`, the server then applies the threshold.

- [ ] **11.2.3.1** Install: `npm install compression @types/compression --save` (in `backend/`)
- [ ] **11.2.3.2** Add `GZIP_THRESHOLD_BYTES` and `GZIP_ENABLED` to `.env.example`
- [ ] **11.2.3.3** Verify with `curl -H "Accept-Encoding: gzip" -v <url>` that small endpoints return uncompressed and large ones return `Content-Encoding: gzip`

### 11.2.4 Client-Side Implementation (Flutter / Dio)

**File:** `flutter_app/lib/core/api/interceptors/compression_interceptor.dart`

```dart
class CompressionInterceptor extends Interceptor {
  final Ref ref;
  CompressionInterceptor(this.ref);
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final enabled = ref.read(settingsProvider).compressionEnabled;
    options.headers['Accept-Encoding'] = enabled ? 'gzip' : 'identity';
    handler.next(options);
  }
}
```

**Decompression:** the underlying `dart:io` HttpClient that Dio uses **auto-decompresses** gzip responses transparently. No manual gunzip step needed.

- [ ] **11.2.4.1** `CompressionInterceptor` registered on the shared Dio instance in `api_client.dart`
- [ ] **11.2.4.2** New setting `compression_enabled` (bool, default `true`) added to `app_settings` table (SQLite) — see [02_database_schema.md](02_database_schema.md)
- [ ] **11.2.4.3** Settings screen exposes the toggle (see §11.2.6)
- [ ] **11.2.4.4** Add localized strings for the setting label + description

### 11.2.5 Settings UI

Add a new "Network" section in Settings:

```
Network
  ┌──────────────────────────────────────────────────────┐
  │ Compress large responses                       [ON]  │
  │ When ON, the server will compress responses          │
  │ larger than 100 KB to save bandwidth. Small           │
  │ responses are sent uncompressed for speed.            │
  └──────────────────────────────────────────────────────┘
```

- [ ] **11.2.5.1** Add `settingsCompressionLabel`, `settingsCompressionHint` keys to ARB files
- [ ] **11.2.5.2** Toggle updates `app_settings.compression_enabled` (SQLite) + invalidates the settings provider

### 11.2.6 Verifying Compression Works

- [ ] **11.2.6.1** Unit test: server with `GZIP_ENABLED=true`, threshold=1024, returns 2 KB body with header `Content-Encoding: gzip`
- [ ] **11.2.6.2** Unit test: server with `GZIP_ENABLED=false`, returns 2 KB body without compression header
- [ ] **11.2.6.3** Unit test: server with threshold=102400, returns 50 KB body without compression header (below threshold)
- [ ] **11.2.6.4** Integration test: Flutter with `compression_enabled=true` → fetch large endpoint → verify response received intact + log shows fewer bytes on wire than body length
- [ ] **11.2.6.5** Integration test: Flutter with `compression_enabled=false` → header is `Accept-Encoding: identity` → response is uncompressed

---

## 11.3 Order of Operations (Backend Middleware Pipeline)

For clarity, this is the order middleware/interceptors execute on the `POST /conversations/.../messages` path:

```
HTTP request arrives
  ↓
1. Helmet (security headers)
  ↓
2. CORS
  ↓
3. Compression middleware (peeks at Accept-Encoding for response; doesn't decompress requests since we don't accept gzipped requests)
  ↓
4. Body parsing (JSON)
  ↓
5. JwtAuthGuard (authenticate)
  ↓
6. ValidationPipe (DTO validation, length checks)
  ↓
7. ContentGuardInterceptor (profanity check on user message)
  ↓
8. ThrottlerGuard (rate limit per user)
  ↓
9. Controller method → AiProvider → save message → respond
  ↓
10. (response) ResponseInterceptor + Compression middleware applies gzip if eligible
```

- [ ] **11.3.1** Document this order in `backend/README.md` so future-you knows where to insert new concerns
- [ ] **11.3.2** Each layer can short-circuit with a proper HTTP status; nothing reaches AI provider until guard + throttle pass

---

## 11.4 Future Considerations (Out of Scope for v1)

| Idea | Why deferred |
|------|--------------|
| Brotli compression in addition to gzip | Modern browsers prefer brotli but Dart's HttpClient does not auto-decode it — would need manual handling. Save for later if traffic volume justifies it |
| ML-based content moderation (offline classifier ONNX) | Wordlist approach is good enough for v1; add a small classifier alongside if false-negative rate is high |
| Request-body compression (client → server) | Payloads are tiny (~500 bytes per user message); compression overhead exceeds savings. Reconsider when audio uploads land |
| End-to-end encryption beyond TLS | TLS is sufficient for v1; consider only if compliance requires |
| Per-endpoint compression overrides | Possible but adds config complexity; revisit if some endpoints need special treatment |

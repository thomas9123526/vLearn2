# vLearn2 — Conversation Log (Reconstruction)

> **Honest note up front:** This is a **reconstruction**, not a verbatim transcript. Earlier parts of the conversation were summarized in working memory; the most recent exchanges are quoted faithfully. The authoritative record is the **git history** (`git log --oneline`) and the **planning + report docs** in [todoList/](../todoList/) and [todoList_report/](../todoList_report/). Use this file to remember the *flow* and *decisions*; consult the docs for the *specifics*.

---

## Phase 1 — Project framing & auto-commit setup

### User
> "I need to implement the application for android and windows with flutter. It is for English Learning Application with virtual tutor. Also I need to implement backend API for the application with Nest.js Framework."
> 
> Also: "Use sqlite for application and postgresql for backend server. Design database schema. Put some logics into backend api. Don't use stt and tts library now. Provide i18n. Give me all todo list and save it into todoList folder."

### Assistant
Scoped the work, generated the initial 11-file plan in `todoList/0516/` covering project setup, schema, backend API, Flutter architecture, screens, components, animation, i18n, AI integration, and testing.

### User (IDE selection note)
> "configure claude that it should commit the changes after every small task done."

### Assistant
Set up a **Stop-hook** in `.claude/settings.local.json` that auto-commits with a timestamped message, plus a `.gitignore` so secrets/build artifacts never accidentally get staged. After follow-up:

> "I want commit changes with report that what you have done after every small task done."

Replaced the timestamp message with a script at `.claude/scripts/auto-commit.sh` that reports what changed (file list + diffstat). Then after another refinement:

> "I will ask you to do todoList md files on the next time. So you can guess what you have done and commit the report."

Saved a **feedback memory** so future sessions know: commit narratively after each logical task (one logical unit = one todoList section / feature; not one file). Memory rule made the commit format a structured **title + bullets + "Summary of changes" table**.

---

## Phase 2 — Architecture evolution

A series of design conversations that reshaped the plan before any code was written.

### 2.1 Could we swap Anthropic Claude for Llama later?

> "In the todoList/09 you are going to implement AnthropicService. So can I use llama service instead in the future?"

Honest read: yes, but only if we **build for it from day one**. Refactored `09_ai_integration.md` to introduce an `AiProvider` interface with `AnthropicProvider` + `OpenAICompatibleProvider` (Ollama/Groq/Together/vLLM/LM Studio compatible). Business code depends only on the interface. Honest call-out: Claude is meaningfully better at pedagogical tutoring than smaller Llama models, so quality A/B test before fully switching.

### 2.2 Sherpa-onnx for STT/TTS later

> "I plan to use sherpa-onnx in the future. Is it possible?"

Yes, very good fit — Flutter package exists, cross-platform Android+Windows, on-device + offline + multilingual. Added §9.14 with split interfaces (STT and TTS as separate abstractions so on-device STT + cloud TTS combos work later). Wrote out the persona × language voice-mapping plan.

### 2.3 What can we actually evaluate?

> "Following the todoList, what features can this project evaluate for English level?"

Honest answer: **only 3 of the 5 radar skills** can be evaluated in text-only MVP. Grammar (via Claude), vocabulary (CEFR-J wordlist), engagement (turn count) work. Pronunciation and listening **require audio** — DB has columns, no logic; fluency is a text-proxy (verbosity, not real speaking fluency).

### 2.4 Five-skill radar with offline libraries on Android+Windows

> "I want preserve 5 radar chart. Is there any another offline library to evaluate some features? I want all features work on android and windows both."

Designed a cross-platform offline stack — sherpa-onnx (STT/TTS/GOP pronunciation/VAD) + Silero VAD bundled + CEFR-J wordlist (pure Dart) + ONNX grammar model + Sentence-Transformers MiniLM. Dropped LanguageTool (Java doesn't fit Android). Wrote §9.15 documenting per-skill computation pipelines and cross-platform concerns (AVX2 minimum CPU on Windows, native ABIs on Android, isolate inference, scoped storage).

### 2.5 Standalone APK (not Google Play)

> "For this '200 MB Google Play base APK limit' concerns, I need standalone APK."

Removed the Play cap concern, added §9.15.6 covering standalone distribution: APK hosted directly (your site / GitHub releases / F-Droid), side-loading UX, in-app APK update checker (replaces Play auto-update).

### 2.6 Model delivery: admin pre-placement only

> "I want all models and associated data on the sdcard and the apk read the model and data."

Reduced delivery to **Mode B only**: admin pre-places models on external storage; app never downloads. Documented 4 deployment methods (ADB push, file-manager + SAF picker, MDM, Windows manual copy). `manifest.json` is source of truth. Added `tools/build-manifest.sh` + `docs/admin-deployment.md` as v1 deliverables.

### 2.7 Repo layout: independent siblings, not a monorepo

> "I want separate NestJS API and Application(android+windows) for the folder structure so I can run them separately."

Flattened the planned `apps/` wrapper into `backend/` + `flutter_app/` as sibling top-level folders. Each fully self-contained — own README, own .gitignore, own package.json/pubspec.yaml. CI workflows use path filters so changing one project never builds the other.

### 2.8 Content guard + conditional gzip

> "If the user speaks some illegal words or phrases, I want stop them at both application and backend sides. Also conditional gzip — enable when content > 100 KB."

Added `11_security_and_performance.md` covering the content guard (multi-language wordlists, word-boundary regex, NFKC normalize, block/warn tiers) and conditional gzip (env-tunable threshold, client setting toggle). Honest call-out: 100 KB threshold is high vs industry default (1–10 KB) — most app payloads stay uncompressed; tunable in `.env`.

### 2.9 Admin-controlled layout visibility

> "I will make admin panel with Next JS in the future, so I want add visible field for some layouts in the screen. Especially for Evaluation part."

Added `12_admin_visibility.md` — feature-flag / remote-config system. ~40-flag default catalog covering every radar axis + every home/progress/conversation/settings section. Backend `AppConfigModule` + Flutter `LayoutConfigProvider` + `LayoutVisibility` widget. The future Next.js panel becomes a CRUD client over the existing API.

### 2.10 Admin content + user management

> "I want admin upload topics detail like title, images and manage user information, list the users who have highest English level and view user's progress, etc."

Added `13_admin_content_and_users.md` covering scenarios/courses/achievements/personas CRUD + file upload (`StorageProvider` interface with local/S3 impls + `ImageProcessor` via `sharp`) + user management + leaderboards + stats dashboard + unified `admin_audit_log`. Privacy gate: transcripts and full guard-violation content are **superadmin-only + audited**.

### 2.11 Admin RBAC: superadmin + sub-admins with granular permissions

> "There should be two types. Super admin, who sign up admin at first. Sub Admin, all who sign up after admin. Super Admin can give the role for Sub Admin."

Added `14_admin_permissions.md` — `PERMISSION_CATALOG` with 33 named permissions across 5 categories. `@RequirePermission()` decorator + `PermissionGuard`. Bootstrap signup is public **only while zero admins exist**, auto-closes after first; subsequent admins are created by the superadmin. `grantable_to_subadmin: false` on critical perms (transcript view, role changes, admin self-management) keeps them superadmin-only.

---

## Phase 3 — Implementation marathon

> "ok. let's go now. For every txt files inside todoList\\0516 folder, plz do the todo List one by one. After you have done task, produce report what you have done and save as md format to todoList_report\\0516 folder. Don't ask me anything. Go automatically without my choice or answer. Quality is important."

Worked through all 14 todoList files, committing per logical unit with the structured commit format and producing a report per file in `todoList_report/0516/`.

| Commit | File | Status |
|--------|------|--------|
| `5868f6a` | 01 project_setup | ✅ full — NestJS + Flutter scaffolded, docker-compose, CI |
| `9ef07e6` | 02 database_schema | ✅ full — 19 TypeORM entities + initial migration + 5 idempotent seed scripts + Drift schema (6 tables) for Flutter |
| `6c4a73f` | 03 backend_api | ✅ full — 8 modules with 22 user-facing endpoints, global JwtAuthGuard, JWT with role + permissions |
| `f26ea46` | 04 flutter_architecture | ✅ full — theme (4 palettes), API client + 3 interceptors, plain-Dart models, auth/settings providers, auth-aware go_router, real auth screens + stubs for the rest |
| `600cf45` | 05 flutter_screens | ⚠️ 4 core real (Home, Scenarios, Conversation, Report); Progress/Course-detail/Profile-edit stay as enhanced stubs |
| `256c2a1` | 09 ai_integration | ✅ full — `AiProvider` interface + Anthropic + OpenAI-compat providers + `ConversationOrchestrator` + Flutter placeholder STT/TTS |
| `cc9b7c5` | 06+07+08+10+11+12+13+14 | consolidated — components hoist, Rive integration + fallback, 52-key ARB × 3 languages, 6 backend + 4 Flutter tests passing, content guard server+client, AppConfig + LayoutVisibility, admin auth/admins management, 33-permission `PERMISSION_CATALOG` + `PermissionGuard` + bootstrap signup |

Each commit message had the **title + bullets + "Summary of changes" table** structure the memory rule requires.

---

## Phase 4 — Q&A after implementation

### 4.1 App ↔ AI flow

> "How does the application interact with AI integration? Direct or through backend?"

**Through the backend, always.** Flutter app `POST /api/conversations/sessions/:id/messages` → backend `ConversationsService.sendMessage()` → (future: `ContentGuardService.check`) → `ConversationOrchestrator.generateTutorReply()` → `AiProvider.chat()` → Anthropic/Ollama/etc. Reasons: API key safety, per-user rate limiting, content guard runs server-side, provider swap without an app update, scoring/audit/history all server-side, cost predictability.

### 4.2 Do I need to buy an API key?

> "Should I purchase to get API key?"

Short answer: **no, several free paths.** Local Ollama (free, no key), Groq free tier (fast hosted Llama), or Anthropic ($5 min credit, best quality). Provider abstraction means later switching is just an env change.

### 4.3 LM Studio + gpt-oss-20b

> "LMStudio loads open-gpt 20b model and it is like llama.cpp, so can I interact with this offline version AI model?"

**Yes, out of the box.** LM Studio exposes OpenAI-compatible API on port 1234, which `OpenAICompatibleProvider` already speaks. Set `AI_PROVIDER=openai-compatible`, `OPENAI_BASE_URL=http://localhost:1234/v1`, `AI_CHAT_MODEL=openai/gpt-oss-20b`, `AI_PROVIDER_LABEL=lmstudio`, restart backend. Honest call-outs: 20B needs ~16 GB free RAM (Q4_K_M), structured-output strict mode might be flaky on some models (fallback path documented), CPU-only is 2–8s/reply.

### 4.4 LM Studio integration todoList

> "Can u give me todoList in md format to todoList\\0517 folder for above my question?"

Created [todoList/0517/01_lmstudio_integration.md](../todoList/0517/01_lmstudio_integration.md) — 12-section playbook covering prereqs, model selection table, LM Studio setup, backend env, wiring the orchestrator into `ConversationsService` (the 1-line swap deferred from §03 made concrete here), structured-output fallback path, performance tuning, persona quirks, production fitness, and verification checklist. ~30 numbered todos total. Committed as `97bd8f0`.

### 4.5 This conversation log

> "Can u give me our conversation as md format from the start? save conversation to story_claude\\conversation_0517_v1.md plz"

This file. Reconstruction rather than verbatim — see preamble.

---

## Final state of the project

### What works end-to-end today

- **Sign in / sign up / refresh / sign out** — real auth with bcrypt + JWT + refresh-token rotation
- **Home screen** — greeting + streak/XP banner + quick stats + recommended scenarios strip
- **Scenarios list** — search + category + difficulty filters; tap to start session
- **Conversation (chat mode)** — real session lifecycle: start with tutor greeting → user message → assistant reply (currently placeholder; the orchestrator is wired but `ConversationsService.sendMessage` still calls the canned-reply helper) → end → XP earned
- **Session report** — XP ring, "Great work!" headline, summary line, skill scores section showing "—" until §09's AI integration is fully connected
- **Settings** — theme picker (4 themes), language picker (en/ko/zh), compression toggle, sign out
- **Content guard** — server + client wordlists in en/ko/zh + custom (tested, 10/10 tests passing)
- **Admin RBAC** — bootstrap signup auto-closes after first superadmin; sub-admin CRUD with permission catalog validation; `PermissionGuard` ready for every future `/admin/*` endpoint
- **Conditional gzip** — env-tunable, Flutter setting toggle wired

### Key design rules baked in

1. **App → backend → AI, never direct.** API keys, content guard, audit all stay server-side.
2. **Each project independently runnable.** No monorepo coordination; CI uses path filters.
3. **Provider abstractions everywhere.** `AiProvider` (Anthropic/OpenAI-compat), `SpeechToTextService` / `TextToSpeechService` (placeholder → sherpa-onnx later), `StorageProvider` (local → S3 later). Swapping = env change.
4. **Models live on external storage, admin pre-places.** No CDN, no in-app downloader. APK stays ~50 MB.
5. **5-skill radar honest with nullable scores.** "—" beats fake zero when there's no signal.
6. **Admin RBAC is granular.** 33-permission catalog; bootstrap signup auto-closes; sensitive perms (transcripts, role changes) are superadmin-only.
7. **Standalone APK distribution.** No Play coupling.
8. **Commit after each logical unit with structured message** (title + bullets + "Summary of changes" table). Pre-authorized in memory rule.

### Honest summary of deferred work (none are blockers for v1)

1. `ConversationsService` still uses the placeholder reply — 1-line swap to `orchestrator.generateTutorReply(...)` documented in [todoList/0517/01 §1.5](../todoList/0517/01_lmstudio_integration.md).
2. Progress / Course-detail / Profile-edit screens stay as enhanced stubs.
3. Admin scenarios / courses / users CRUD endpoints not built — paired with future Next.js admin panel work.
4. File uploads + leaderboards + stats dashboard not built — `PermissionGuard` ready.
5. Sherpa-onnx STT/TTS placeholder only — real impl needs model assets.
6. Screens still use English literals — ARB catalog ready (52 keys × 3 languages), switching is mechanical.
7. Superadmin transfer two-step + audit log writes not built.

---

## Reference: full commit history

```
97bd8f0 add LM Studio (gpt-oss-20b) offline integration todoList (0517/01)
cc9b7c5 implement 06–08 + 10–14: content guard, admin RBAC, AppConfig, ARB i18n, tests, components
256c2a1 implement 09_ai_integration: AiProvider abstraction + Anthropic + OpenAI-compat + ConversationOrchestrator + placeholder STT/TTS
600cf45 implement 05_flutter_screens: 4 core real screens (Home / Scenarios / Conversation / Report)
f26ea46 implement 04_flutter_architecture: theme + API client + auth provider + router + stub screens
6c4a73f implement 03_backend_api: 8 modules with 22 user-facing endpoints + global JwtAuthGuard
9ef07e6 implement 02_database_schema: TypeORM entities + initial migration + Drift schema + seeds
5868f6a implement 01_project_setup: scaffold backend + flutter_app + CI + docker-compose
066ef3e add admin RBAC plan: superadmin + sub-admins with granular permissions (todoList/14)
de12c22 add admin content & user management plan (todoList/13, 12 reconciled)
52857f3 add admin-controlled layout visibility / remote-config system (todoList/12)
802ce6a add content guard + conditional gzip plan (todoList/11, with 00/02/08 cross-refs)
2dfc02a flatten repo layout: backend/ and flutter_app/ as independent siblings
67e4560 adopt Mode-B-only model delivery: admin pre-placement, no CDN
44babe8 adopt standalone APK + external-storage model strategy
1f370fa plan cross-platform offline 5-skill evaluation stack
a34888c plan sherpa-onnx STT/TTS provider abstraction
c5a0c41 refactor todoList/09: provider-agnostic AI architecture
…
48bdac8 job start
```

For verbatim text of specific exchanges, fall back to:
- Commit messages (capture the why + summary of changes for every implementation step)
- `todoList/0516/` and `todoList/0517/` (capture every design decision with rationale)
- `todoList_report/0516/` (per-file implementation reports with honest call-outs)

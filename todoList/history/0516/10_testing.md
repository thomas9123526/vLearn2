# 10 – Testing Strategy

## 10.1 Backend Tests (NestJS)

### Unit Tests

- [ ] **10.1.1** `AuthService` — signup, signin, JWT generation, refresh rotation
- [ ] **10.1.2** `ScoreService` — fluency/vocabulary/engagement calculations with known inputs
- [ ] **10.1.3** `PromptBuilderService` — correct system prompt for each persona × scenario × level
- [ ] **10.1.4** `ProgressService` — level calculation, XP thresholds, streak logic
- [ ] **10.1.5** `AnthropicService` — mocked Anthropic client, error/retry behavior

### Integration Tests (supertest)

- [ ] **10.1.6** `POST /auth/signup` → 201 + token pair
- [ ] **10.1.7** `POST /auth/signup` → 409 if email exists
- [ ] **10.1.8** `POST /auth/signin` → 200 + tokens
- [ ] **10.1.9** `POST /auth/signin` → 401 wrong password
- [ ] **10.1.10** `POST /auth/refresh` → 200 + new token pair
- [ ] **10.1.11** `GET /auth/me` → 200 with valid token
- [ ] **10.1.12** `GET /auth/me` → 401 without token
- [ ] **10.1.13** `GET /scenarios` → 200 list with filters
- [ ] **10.1.14** `POST /conversations/sessions` → 201 new session
- [ ] **10.1.15** `POST /conversations/sessions/:id/messages` → 200 with AI reply (mocked)
- [ ] **10.1.16** `POST /conversations/sessions/:id/end` → 200 with scores
- [ ] **10.1.17** `GET /progress` → 200 with computed stats

### Test Setup
```typescript
// Use in-memory SQLite for test DB (TypeORM)
// Mock AnthropicService for all conversation tests
// Use JWT_ACCESS_SECRET=test_secret in test env
```

---

## 10.2 Flutter Tests

### Unit Tests

- [ ] **10.2.1** `ScoreRing` painter: verify arc angle calculation
- [ ] **10.2.2** `AnimatedNumber`: verify final value reached
- [ ] **10.2.3** Auth token: refresh logic, expiry check
- [ ] **10.2.4** Level calculation: XP → level mapping
- [ ] **10.2.5** Date utils: streak calculation, time-of-day greeting

### Widget Tests

- [ ] **10.2.6** `AppButton`: loading state, disabled state, tap handler
- [ ] **10.2.7** `AppChip`: selected/unselected appearance
- [ ] **10.2.8** `ScoreRing`: renders with correct score
- [ ] **10.2.9** `AnimatedBar`: label and value display
- [ ] **10.2.10** `VoiceBubble`: user vs tutor alignment
- [ ] **10.2.11** Sign In screen: form validation errors shown
- [ ] **10.2.12** Sign Up screen: password strength meter updates
- [ ] **10.2.13** Conversation screen: message sends, typing indicator shows

### Integration Tests (flutter_test with mocked providers)

- [ ] **10.2.14** Auth flow: signup → onboarding → home navigation
- [ ] **10.2.15** Scenario flow: browse → brief → conversation → report
- [ ] **10.2.16** Settings: theme change updates UI immediately
- [ ] **10.2.17** Settings: locale change updates all strings

---

## 10.3 Platform Build Verification

- [ ] **10.3.1** Android: `flutter build apk --release` — build success
- [ ] **10.3.2** Android: install on emulator API 30+ — launch test
- [ ] **10.3.3** Windows: `flutter build windows --release` — build success
- [ ] **10.3.4** Windows: launch on Windows 10/11 — smoke test

---

## 10.4 Manual QA Checklist

### Auth
- [ ] Sign up with new email → lands on onboarding
- [ ] Sign up with existing email → shows error
- [ ] Sign in → lands on home
- [ ] Wrong password → shows error, no crash
- [ ] Token expiry → auto-refresh works silently
- [ ] Sign out → clears state, lands on sign in

### Home
- [ ] Stats show correct values
- [ ] Streak updates after session
- [ ] Notification bell works
- [ ] Continue course card shows when enrolled

### Conversation (Chat Mode)
- [ ] Start session → tutor sends greeting
- [ ] Send message → get AI reply
- [ ] Typing indicator shows while waiting
- [ ] Avatar state changes correctly
- [ ] End conversation → navigate to report

### Conversation (Face Mode)
- [ ] Toggle to face mode → character appears
- [ ] Rive animation plays correct states
- [ ] Caption shows tutor's message
- [ ] Toggle back to chat mode

### Report
- [ ] Scores display correctly
- [ ] Confetti fires when score > 60
- [ ] XP shows on home after return
- [ ] Try Again → starts new session with same scenario

### Progress
- [ ] All stats correct
- [ ] Radar chart renders
- [ ] Weekly bar chart renders
- [ ] Achievements display correctly

### Settings
- [ ] Theme change applies immediately everywhere
- [ ] Language change updates all UI strings
- [ ] Persona selection updates conversation header
- [ ] Edit profile saves and reflects changes
- [ ] Sign out clears all cached data

### i18n
- [ ] Switch to Korean → all UI in Korean
- [ ] Switch to Chinese → all UI in Chinese + correct font
- [ ] Missing translations fall back to English

### Responsive
- [ ] Android phone (360-412 dp): bottom nav visible, all content accessible
- [ ] Windows desktop: sidebar visible, content max-width respected
- [ ] Long content doesn't overflow
- [ ] Keyboard does not cover input in conversation

---

## 10.5 Performance Targets

### MVP (no STT/TTS — placeholder services)
| Metric | Target |
|--------|--------|
| App cold start (Android) | < 3 seconds |
| Screen navigation | < 300ms |
| API response (conversation) | < 3 seconds (P90) |
| SQLite read | < 50ms |
| Rive animation FPS | 60 FPS |
| **APK size** | **< 50 MB** |
| **Windows installer** | **< 80 MB** |

### Post-STT/TTS (sherpa-onnx + offline evaluation models)
**Distribution: standalone APK; models are admin-pre-placed (Mode B only — no CDN, no in-app downloader).** All models live on **external storage**, not internal app storage. See [todoList/09 §9.15.6](09_ai_integration.md).

| Metric | Target | Notes |
|--------|--------|-------|
| APK size | < 50 MB | Code + UI + CEFR-J wordlist only; no models bundled |
| Windows installer | < 80 MB | Same rationale — models live on external storage |
| First-launch model verification time (1 lang, full stack) | < 6s on mid-range Android | SHA-256 verify ~420 MB of files; runs in isolate so UI shows progress |
| First-launch model verification time (3 langs en/ko/zh) | < 10s | ~620 MB of files |
| Subsequent launches (manifest mtime unchanged) | < 200 ms | Skip hash verify if manifest mtime + size match cached state |
| External storage footprint (1 lang) | ~420 MB | Under `/sdcard/Android/data/<pkg>/files/models/` |
| External storage footprint (3 langs en/ko/zh) | ~620 MB | Shared STT/grammar/MiniLM models + 3 TTS voice packs |
| STT latency (transcribe 5s clip) | < 1.5s on mid-range Android | Whisper-tiny int8 |
| STT streaming partial latency | < 300ms | Zipformer streaming |
| TTS first-audio latency | < 800ms | VITS-medium |
| TTS RTF (real-time factor) | < 0.5 | i.e. 1s of audio synthesized in < 500ms |
| Grammar inference (single sentence) | < 600ms | flan-T5-small int8 |
| Semantic similarity (MiniLM) | < 200ms | for listening comprehension scoring |

### Deployment & verification strategy
- [ ] **10.5.1** Admin pre-places models via one of 4 methods (ADB push / SAF folder pick / MDM / Windows manual copy) — see §9.15.6
- [ ] **10.5.2** `manifest.json` is the source of truth: lists every file + SHA-256 + size; app verifies on every launch (cached fast-path after first verify)
- [ ] **10.5.3** "Models not installed" boot screen: friendly admin-help message, SAF picker, allows continuing in text-only mode
- [ ] **10.5.4** Settings → Storage section: shows model root path, per-bundle integrity status, "Re-verify all" button, "Locate models folder" button, "Export manifest" button — **no download / delete buttons**
- [ ] **10.5.5** Graceful degradation: missing or corrupt model file → feature returns "model not available" error, never crashes; user shown admin-help text
- [ ] **10.5.6** `docs/admin-deployment.md` shipped with v1: manifest format, all 4 deployment methods with copy-paste commands, troubleshooting, hash-generation script
- [ ] **10.5.7** `tools/build-manifest.sh` (+ Node/Python equivalent) included in repo for admins to generate `manifest.json` from a models directory
- [ ] **10.5.8** In-app **APK** update checker: daily ping to `version.json`, non-blocking banner when newer APK available (no model network calls)

### Cross-platform smoke tests (release builds)
- [ ] **10.5.9** Android release APK install on a **fresh device with no models** → boots to "Models not installed" screen (no crash, friendly UI)
- [ ] **10.5.10** Android: `adb push` models to `/sdcard/Android/data/<pkg>/files/models/` → app launches → integrity verify passes → STT + TTS smoke calls succeed
- [ ] **10.5.11** Android: copy models to `/sdcard/vLearn2-models/` via file manager → first-launch SAF picker resolves them → boot succeeds → models survive app uninstall + reinstall (SAF URI re-prompt or persist as designed)
- [ ] **10.5.12** Android: corrupt one model file (truncate by 1 byte) → app detects hash mismatch → shows "Models corrupt" screen → admin re-pushes → recovery works
- [ ] **10.5.13** Windows: place models at `%APPDATA%\vLearn2\models\` → app launches → verify passes → STT + TTS smoke calls succeed
- [ ] **10.5.14** Windows: launch with no models → "Models not installed" screen → file dialog → user picks `C:\vLearn2-models\` → boot succeeds
- [ ] **10.5.15** Performance: cold start with pre-verified models < 1s on mid-range Android (cached fast-path)
- [ ] **10.5.16** Manifest-builder tool: run on a models directory → produces a valid `manifest.json` → app accepts it

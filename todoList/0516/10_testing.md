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

### Post-STT/TTS (sherpa-onnx on-device models)
Model assets are **downloaded on first launch**, not bundled in the binary. The installer stays small; the device's app data directory grows as models are fetched.

| Metric | Target | Notes |
|--------|--------|-------|
| APK size | < 50 MB | unchanged — models downloaded post-install |
| Windows installer | < 80 MB | unchanged — models downloaded post-install |
| First-launch model download | < 5 min on 20 Mbps | Whisper-tiny (~40 MB) + 1 VITS voice (~80 MB) per language |
| On-device storage after full setup (1 lang) | ~150 MB | ASR + TTS models in app document dir |
| On-device storage after full setup (3 langs en/ko/zh) | ~400 MB | shared ASR + 3 voice packs |
| STT latency (transcribe 5s clip) | < 1.5s on mid-range Android | Whisper-tiny int8 |
| STT streaming partial latency | < 300ms | Zipformer streaming |
| TTS first-audio latency | < 800ms | VITS-medium |
| TTS RTF (real-time factor) | < 0.5 | i.e. 1s of audio synthesized in < 500ms |

### App-size strategy
- [ ] **10.5.1** Models hosted on CDN (or Hugging Face mirror) — not in app bundle
- [ ] **10.5.2** Download screen shown on first launch *after* sign-in: progress bar per model, retry on failure, resumable
- [ ] **10.5.3** Models versioned and stored under `<app-docs>/speech-models/v1/`; old versions purged on upgrade
- [ ] **10.5.4** "Manage downloads" section in Settings — let user delete unused language packs to free space
- [ ] **10.5.5** Graceful degradation: if a model is missing, fall back to text-only conversation with a soft prompt to download

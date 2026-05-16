# 03 – Backend API (NestJS)

**Cross-cutting concerns spec'd in separate files** (modules / interceptors / endpoints documented there are still implemented inside `backend/src/`):
- Content guard + gzip compression — [11_security_and_performance.md](11_security_and_performance.md)
- Layout visibility + admin-config endpoints — [12_admin_visibility.md](12_admin_visibility.md) (adds `AppConfigModule` with `/app-config` and `/admin/config/*`)
- Admin content + user management — [13_admin_content_and_users.md](13_admin_content_and_users.md) (adds `AdminScenariosModule`, `AdminCoursesModule`, `AdminAchievementsModule`, `AdminPersonasModule`, `AdminUsersModule`, `AdminLeaderboardModule`, `AdminStatsModule`, `AdminAuditModule`, `StorageProvider`, `ImageProcessor`)

The JWT payload extends to include `role` (see [12 §12.4](12_admin_visibility.md)). All `/admin/*` endpoints are guarded by `AdminGuard` which checks `user.role IN ('admin','superadmin')`. The most privacy-sensitive endpoints (transcript view, full guard-violation content) require `superadmin` and are audited per [13 §13.8](13_admin_content_and_users.md).

## 3.1 Auth Module (`/auth`)

### Endpoints
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/signup | Public | Register new user |
| POST | /auth/signin | Public | Login, returns JWT pair |
| POST | /auth/refresh | Public (refresh token) | Rotate access + refresh tokens |
| POST | /auth/signout | Bearer | Revoke refresh token |
| GET | /auth/me | Bearer | Get current user profile |

### DTOs & Validation
- [ ] **3.1.1** `SignUpDto`: email (IsEmail), password (MinLength 8, regex strength), displayName (MinLength 2)
- [ ] **3.1.2** `SignInDto`: email, password
- [ ] **3.1.3** Password strength validation: uppercase + digit required
- [ ] **3.1.4** Response: `{ accessToken, refreshToken, user: UserProfile }`

### Business Logic
- [ ] **3.1.5** Bcrypt password hashing (rounds: 12)
- [ ] **3.1.6** JWT access token (15m) + refresh token (7d, stored hashed in DB)
- [ ] **3.1.7** Refresh token rotation on every `/refresh` call
- [ ] **3.1.8** JwtAuthGuard (global default) + Public() decorator for open routes

---

## 3.2 Users Module (`/users`)

### Endpoints
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /users/profile | Bearer | Full profile with progress summary |
| PATCH | /users/profile | Bearer | Update display name, avatar, native language |
| PATCH | /users/settings | Bearer | Update ui_language, theme, active_persona_id |
| GET | /users/streak | Bearer | Current streak + calendar heatmap data |
| DELETE | /users/account | Bearer | Soft-delete user account |

### Business Logic
- [ ] **3.2.1** `GET /users/profile` returns:
  ```json
  {
    "user": { ...UserProfile },
    "progress": {
      "sessionsTotal": 42,
      "minutesSpokenTotal": 310,
      "currentStreak": 5,
      "xpTotal": 1250,
      "level": 2,
      "levelProgress": 0.67,
      "nextLevelXp": 500
    },
    "recentAchievements": [...],
    "activePersona": { ...Persona }
  }
  ```
- [ ] **3.2.2** Level calculation function:
  ```
  Level 1 (A1): 0–499 XP
  Level 2 (A2): 500–1499 XP
  Level 3 (B1): 1500–3499 XP
  Level 4 (B2): 3500–6999 XP
  Level 5 (C1): 7000–12999 XP
  Level 6 (C2): 13000+ XP
  ```
- [ ] **3.2.3** Streak logic: auto-update `streak_days` on session completion, reset if last_active_date > 1 day ago
- [ ] **3.2.4** `GET /users/streak` returns 30-day activity calendar (boolean array)

---

## 3.3 Personas Module (`/personas`)

### Endpoints
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /personas | Bearer | List all active personas |
| GET | /personas/:id | Bearer | Single persona detail |

### Response
```json
{
  "id": "uuid",
  "key": "maya",
  "name": "Maya",
  "accent": "american",
  "style": "encouraging and warm",
  "specialties": ["daily life", "travel"],
  "accentColor": "#E8956D",
  "gradientFrom": "#E8956D",
  "gradientTo": "#F2C4A0",
  "riveAsset": "assets/rive/maya.riv"
}
```

- [ ] **3.3.1** Seed data for Maya, Leo, Sofia, Theo from tokens.json colors
- [ ] **3.3.2** System prompt builder per persona (personality + speaking style injected into AI context)

---

## 3.4 Scenarios Module (`/scenarios`)

### Endpoints
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /scenarios | Bearer | List scenarios with filters |
| GET | /scenarios/:id | Bearer | Scenario detail + user progress |
| GET | /scenarios/categories | Bearer | Category list with counts |

### Query Parameters (`GET /scenarios`)
- `category` — filter by category
- `difficulty` — 1-6
- `level` — alias for difficulty filter by user level ±1
- `completed` — true/false, filter by user completion
- `page`, `limit` — pagination

### Response (`GET /scenarios/:id`)
```json
{
  "scenario": { ...ScenarioDetail },
  "userCompletion": {
    "attempted": true,
    "bestScore": 78,
    "attemptCount": 2,
    "lastCompletedAt": "2026-05-10T..."
  },
  "estimatedMinutes": 5,
  "xpReward": 50
}
```

- [ ] **3.4.1** Filter scenarios by user's current level ±1 for "recommended" list
- [ ] **3.4.2** Return localized strings based on `Accept-Language` header or `lang` query param

---

## 3.5 Conversations Module (`/conversations`)

### Endpoints
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /conversations/sessions | Bearer | Start new session |
| GET | /conversations/sessions/:id | Bearer | Get session + messages |
| POST | /conversations/sessions/:id/messages | Bearer | Send message, get AI reply |
| POST | /conversations/sessions/:id/end | Bearer | End session, trigger scoring |
| GET | /conversations/sessions | Bearer | User session history |
| GET | /conversations/sessions/:id/report | Bearer | Full report for ended session |

### Start Session DTO
```typescript
{
  scenarioId?: string;    // null = free talk
  personaId: string;
  mode: 'chat' | 'face';
}
```

### Send Message DTO
```typescript
{
  content: string;        // user utterance
}
```

### Send Message Response
```typescript
{
  userMessage: Message;
  assistantMessage: Message;
  sessionStats: {
    turnCount: number;
    elapsedSeconds: number;
  };
}
```

### Business Logic
- [ ] **3.5.1** Session start: create session record, build initial AI system prompt
- [ ] **3.5.2** System prompt construction:
  ```
  You are {persona.name}, an English tutor with a {persona.style} teaching style.
  
  SCENARIO: {scenario.title} - {scenario.scene_description}
  YOUR ROLE: {scenario.tutor_role}
  USER'S ROLE: {scenario.user_role}
  OBJECTIVES: {scenario.objectives}
  USER'S LEVEL: {level_label} ({level_number}/6)
  
  INSTRUCTIONS:
  - Respond naturally in character
  - Correct grammar errors gently, embedded in your response
  - Encourage vocabulary from the scenario's key phrases
  - Keep responses conversational (2-4 sentences usually)
  - Adjust complexity to the user's level
  - Do not break character
  ```
- [ ] **3.5.3** Message send: append to conversation history, call Claude API with full history, save response
- [ ] **3.5.4** Claude API call with streaming support (Server-Sent Events optional)
- [ ] **3.5.5** Word count computation for user messages
- [ ] **3.5.6** Session end: compute duration, update turn_count, word_count, trigger scoring

### Scoring Logic (`/conversations/sessions/:id/end`)
- [ ] **3.5.7** Trigger `ScoreService.computeScore(sessionId)`:
  ```
  Fluency Score:
    = min(100, (avg_words_per_turn / target_wpt) * 100)
    target_wpt by level: [5, 8, 12, 18, 25, 35]

  Vocabulary Score:
    = (unique_words / total_words) * 100, capped at 100
    bonus if key_phrases used (+10 per phrase, max +20)

  Grammar Score:
    = Claude AI assessment (0-100) via separate analysis call
    Prompt: "Rate the grammar quality of these user messages 0-100..."

  Engagement Score:
    = min(100, (turn_count / expected_turns) * 100)
    expected_turns = estimated_minutes * 2

  Overall Score:
    = (fluency * 0.25) + (vocabulary * 0.25) + (grammar * 0.35) + (engagement * 0.15)
  ```
- [ ] **3.5.8** AI Feedback generation: separate Claude call for paragraph feedback
- [ ] **3.5.9** XP award: `base_xp + score_bonus + streak_bonus`
  ```
  base_xp = scenario.xp_reward (50 default)
  score_bonus = floor(overall_score / 10) * 5   // max +50
  streak_bonus = min(streak_days, 7) * 2          // max +14
  ```
- [ ] **3.5.10** Update user_progress after session ends
- [ ] **3.5.11** Check and award achievements after session ends
- [ ] **3.5.12** Save weekly skill snapshot (upsert by user_id + current week Monday date)

---

## 3.6 Progress Module (`/progress`)

### Endpoints
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /progress | Bearer | Full progress dashboard data |
| GET | /progress/skills | Bearer | Skill radar chart data (history) |
| GET | /progress/activity | Bearer | Daily activity for heatmap |
| GET | /progress/achievements | Bearer | All achievements + earned status |

### `GET /progress` Response
```json
{
  "summary": {
    "sessionsTotal": 42,
    "sessionsThisWeek": 3,
    "minutesSpokenTotal": 310,
    "minutesSpokenThisWeek": 45,
    "wordsSpokenTotal": 12400,
    "scenariosCompleted": 18,
    "currentStreak": 5,
    "longestStreak": 12,
    "xpTotal": 1250,
    "level": 2,
    "levelLabel": "A2",
    "levelProgress": 0.67,
    "xpToNextLevel": 250
  },
  "weeklyActivity": [3, 0, 1, 2, 0, 1, 0],
  "skillRadar": {
    "pronunciation": 65,
    "fluency": 72,
    "vocabulary": 68,
    "grammar": 74,
    "listening": 60
  },
  "recentSessions": [...],
  "topScenarios": [...]
}
```

- [ ] **3.6.1** Compute all progress values from session data on-demand (cached in user_progress)
- [ ] **3.6.2** `GET /progress/skills` returns last 8 weekly snapshots for trend chart
- [ ] **3.6.3** Level label mapping: 1→A1, 2→A2, 3→B1, 4→B2, 5→C1, 6→C2
- [ ] **3.6.4** Minutes spoken = sum of session duration_seconds / 60

---

## 3.7 Courses Module (`/courses`)

### Endpoints
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /courses | Bearer | List all active courses |
| GET | /courses/:id | Bearer | Course detail + user completion % |
| GET | /courses/:id/next | Bearer | Next incomplete scenario in course |

### `GET /courses/:id` Response
```json
{
  "course": { ...CourseDetail },
  "scenarios": [...],
  "userProgress": {
    "completedCount": 3,
    "totalCount": 10,
    "completionPercent": 30,
    "nextScenarioId": "uuid"
  }
}
```

---

## 3.8 AI Module (internal)

- [ ] **3.8.1** `AnthropicService` wrapping `@anthropic-ai/sdk`
- [ ] **3.8.2** `buildConversationMessages()` — convert DB messages to Anthropic format
- [ ] **3.8.3** `generateTutorReply(systemPrompt, messages)` — main conversation call
  - Model: `claude-sonnet-4-6`
  - max_tokens: 300 (conversational responses)
  - temperature: 0.8
- [ ] **3.8.4** `generateSessionScore(messages, level)` — scoring analysis call
  - Model: `claude-haiku-4-5-20251001` (cheaper for analysis)
  - Structured JSON response for grammar score + feedback bullets
- [ ] **3.8.5** `generateSessionFeedback(sessionData)` — paragraph feedback
- [ ] **3.8.6** Rate limiting: max 50 messages/session, max 10 active sessions/user/day
- [ ] **3.8.7** Error handling: retry on 529 (overloaded), fail gracefully on 5xx

---

## 3.9 Common Infrastructure

- [ ] **3.9.1** `JwtAuthGuard` (global, applied by default)
- [ ] **3.9.2** `@Public()` decorator to bypass JWT guard
- [ ] **3.9.3** `CurrentUser` decorator to extract user from JWT payload
- [ ] **3.9.4** Global `ValidationPipe` with `transform: true, whitelist: true`
- [ ] **3.9.5** Global `HttpExceptionFilter` — standard error response format
  ```json
  { "statusCode": 400, "message": "...", "error": "Bad Request" }
  ```
- [ ] **3.9.6** Global `TransformInterceptor` — wrap all responses in `{ data: ..., timestamp }`
- [ ] **3.9.7** Request logging middleware
- [ ] **3.9.8** Swagger decorators on all controllers/DTOs
- [ ] **3.9.9** CORS configuration (allow Flutter app origins)
- [ ] **3.9.10** Helmet.js for security headers
- [ ] **3.9.11** `ThrottlerModule` — 100 req/min per IP, 10 req/min for AI endpoints

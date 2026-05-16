# 02 – Database Schema Design

## 2.1 PostgreSQL Schema (Backend)

### Table: users
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK, default gen_random_uuid() | |
| email | VARCHAR(255) | UNIQUE, NOT NULL | |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt |
| display_name | VARCHAR(100) | NOT NULL | |
| avatar_emoji | VARCHAR(10) | default '🐣' | |
| native_language | VARCHAR(10) | default 'en' | BCP-47 code |
| ui_language | VARCHAR(10) | default 'en' | en/ko/zh |
| current_level | SMALLINT | default 1 | 1-6 (A1-C2) |
| xp_total | INTEGER | default 0 | |
| streak_days | SMALLINT | default 0 | |
| last_active_date | DATE | nullable | |
| active_persona_id | UUID | FK → personas.id | selected tutor |
| active_theme | VARCHAR(20) | default 'apricot' | apricot/sage/iris/obsidian |
| onboarding_done | BOOLEAN | default false | |
| created_at | TIMESTAMPTZ | default now() | |
| updated_at | TIMESTAMPTZ | default now() | |

### Table: refresh_tokens
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users.id, ON DELETE CASCADE |
| token_hash | VARCHAR(255) | NOT NULL |
| expires_at | TIMESTAMPTZ | NOT NULL |
| created_at | TIMESTAMPTZ | default now() |

### Table: personas
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| key | VARCHAR(20) | UNIQUE | maya/leo/sofia/theo |
| name | VARCHAR(50) | NOT NULL | |
| accent | VARCHAR(30) | | e.g. 'american', 'british' |
| style | VARCHAR(50) | | e.g. 'encouraging tutor' |
| specialties | TEXT[] | | e.g. ['business','travel'] |
| accent_color | VARCHAR(7) | | hex |
| gradient_from | VARCHAR(7) | | hex |
| gradient_to | VARCHAR(7) | | hex |
| rive_asset | VARCHAR(100) | | asset path for animation |
| is_active | BOOLEAN | default true | |

### Table: scenarios
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| slug | VARCHAR(100) | UNIQUE | url-safe identifier |
| category | VARCHAR(50) | | travel/business/social/daily |
| difficulty | SMALLINT | | 1(A1)–6(C2) |
| title | JSONB | | {en, ko, zh} |
| description | JSONB | | {en, ko, zh} |
| scene_description | JSONB | | {en, ko, zh} |
| user_role | JSONB | | {en, ko, zh} |
| tutor_role | JSONB | | {en, ko, zh} |
| objectives | JSONB | | [{en, ko, zh}] array |
| key_phrases | JSONB | | [{phrase, translation}] |
| estimated_minutes | SMALLINT | default 5 | |
| xp_reward | SMALLINT | default 50 | |
| order_index | SMALLINT | default 0 | |
| is_active | BOOLEAN | default true | |
| created_at | TIMESTAMPTZ | default now() | |

### Table: courses
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| title | JSONB | {en, ko, zh} |
| description | JSONB | {en, ko, zh} |
| level | SMALLINT | 1–6 |
| total_scenarios | SMALLINT | |
| is_active | BOOLEAN | default true |

### Table: course_scenarios
| Column | Type | Constraints |
|--------|------|-------------|
| course_id | UUID | FK → courses.id |
| scenario_id | UUID | FK → scenarios.id |
| order_index | SMALLINT | |
| PRIMARY KEY | (course_id, scenario_id) | |

### Table: conversation_sessions
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| user_id | UUID | FK → users.id | |
| scenario_id | UUID | FK → scenarios.id, nullable | null = free talk |
| persona_id | UUID | FK → personas.id | |
| mode | VARCHAR(20) | | chat/face |
| status | VARCHAR(20) | default 'active' | active/completed/abandoned |
| started_at | TIMESTAMPTZ | default now() | |
| ended_at | TIMESTAMPTZ | nullable | |
| duration_seconds | INTEGER | nullable | computed on end |
| turn_count | SMALLINT | default 0 | |
| word_count | INTEGER | default 0 | user words total |
| xp_earned | SMALLINT | default 0 | |

### Table: conversation_messages
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| session_id | UUID | FK → conversation_sessions.id, ON DELETE CASCADE | |
| role | VARCHAR(10) | NOT NULL | user/assistant |
| content | TEXT | NOT NULL | |
| word_count | SMALLINT | | computed for user messages |
| timestamp | TIMESTAMPTZ | default now() | |
| sequence | SMALLINT | | ordering |

### Table: session_scores
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| session_id | UUID | FK → conversation_sessions.id, UNIQUE | |
| overall_score | SMALLINT | 0–100, nullable | weighted average; null until all sub-scores computed |
| pronunciation_score | SMALLINT | 0–100, nullable | from sherpa-onnx GOP (Phase 3+); null when audio unavailable |
| fluency_score | SMALLINT | 0–100, nullable | text-proxy in MVP; audio-based from Phase 2+ |
| vocabulary_score | SMALLINT | 0–100 | CEFR-J coverage + MTLD + key-phrase bonus |
| grammar_score | SMALLINT | 0–100 | ONNX model offline OR Claude online |
| engagement_score | SMALLINT | 0–100 | turn count / time |
| listening_score | SMALLINT | 0–100, nullable | only set when session contains a listening task |
| pronunciation_metrics | JSONB | nullable | `{phoneme_avg, confidence_avg, mispronounced_phonemes:[{phoneme,word,score}]}` |
| fluency_metrics | JSONB | nullable | `{wpm, pause_rate, articulation_rate, filler_count, voiced_seconds}` |
| vocabulary_metrics | JSONB | | `{cefr_distribution:{A1,A2,B1,B2,C1,C2,unknown}, ttr, mtld, unique_words, total_words, keyphrases_used}` |
| grammar_metrics | JSONB | | `{error_count, error_types:[...], scorer_used:'onnx'\|'claude'}` |
| listening_metrics | JSONB | nullable | `{task_type:'dictation'\|'comprehension', similarity_score, dictation_accuracy, expected, actual}` |
| strengths | TEXT[] | | e.g. ['Good use of tense'] |
| improvements | TEXT[] | | e.g. ['Try longer sentences'] |
| ai_feedback | TEXT | nullable | paragraph from Claude/AI provider (null in fully-offline mode) |
| evaluator_versions | JSONB | | `{sherpa_onnx:'1.10.0', cefr_wordlist:'v3', grammar_model:'flan-t5-small-q8'}` — for reproducibility across upgrades |
| computed_at | TIMESTAMPTZ | default now() | |

### Table: skill_snapshots
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| user_id | UUID | FK → users.id | |
| snapshot_date | DATE | | weekly snapshot (Monday) |
| pronunciation | SMALLINT | 0–100, nullable | null when no audio data in week |
| fluency | SMALLINT | 0–100, nullable | |
| vocabulary | SMALLINT | 0–100 | |
| grammar | SMALLINT | 0–100 | |
| listening | SMALLINT | 0–100, nullable | null when no listening tasks in week |
| sessions_in_window | SMALLINT | default 0 | how many sessions contributed |
| confidence | SMALLINT | 0–100, default 50 | how reliable this snapshot is (more sessions = higher confidence) |
| UNIQUE | (user_id, snapshot_date) | | |

**Computation:** weighted average of `session_scores` for sessions in the ISO week. Nullable columns reflect "we have no signal yet" — better than showing 0 in the radar chart.

### Table: user_progress
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| user_id | UUID | FK → users.id, UNIQUE | |
| sessions_total | INTEGER | default 0 | |
| sessions_this_week | SMALLINT | default 0 | reset weekly |
| minutes_spoken_total | INTEGER | default 0 | |
| minutes_spoken_this_week | SMALLINT | default 0 | reset weekly |
| words_spoken_total | INTEGER | default 0 | |
| scenarios_completed | INTEGER | default 0 | |
| current_streak | SMALLINT | default 0 | |
| longest_streak | SMALLINT | default 0 | |
| level_history | JSONB | default '[]' | [{level, date}] |
| updated_at | TIMESTAMPTZ | | |

### Table: user_scenario_completions
| Column | Type | Constraints |
|--------|------|-------------|
| user_id | UUID | FK → users.id |
| scenario_id | UUID | FK → scenarios.id |
| best_score | SMALLINT | 0–100 |
| attempt_count | SMALLINT | default 1 |
| first_completed_at | TIMESTAMPTZ | |
| last_completed_at | TIMESTAMPTZ | |
| PRIMARY KEY | (user_id, scenario_id) | |

### Table: achievements
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| key | VARCHAR(50) | UNIQUE |
| title | JSONB | {en, ko, zh} |
| description | JSONB | {en, ko, zh} |
| icon | VARCHAR(10) | emoji |
| xp_reward | SMALLINT | |
| condition_type | VARCHAR(50) | streak/sessions/score/level/etc |
| condition_value | INTEGER | threshold |

### Table: user_achievements
| Column | Type | Constraints |
|--------|------|-------------|
| user_id | UUID | FK → users.id |
| achievement_id | UUID | FK → achievements.id |
| earned_at | TIMESTAMPTZ | default now() |
| PRIMARY KEY | (user_id, achievement_id) | |

### Table: guard_violations
Records content-guard rejections and warnings for moderation review. See [11_security_and_performance.md §11.1](11_security_and_performance.md).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| user_id | UUID | FK → users.id, ON DELETE CASCADE | |
| session_id | UUID | FK → conversation_sessions.id ON DELETE SET NULL, nullable | null if not in a session |
| attempted_content | TEXT | NOT NULL | original user input (truncated to 2000 chars) |
| matched_terms | TEXT[] | | which wordlist terms matched |
| severity | VARCHAR(10) | | block / warn |
| language | VARCHAR(10) | | wordlist language that matched (en/ko/zh) |
| source | VARCHAR(10) | | client / server (server is authoritative; client value indicates client also flagged it) |
| user_acknowledged_warn | BOOLEAN | default false | only true when severity=warn AND user clicked "Continue anyway" |
| created_at | TIMESTAMPTZ | default now() | |

### Indexes
```sql
CREATE INDEX idx_sessions_user_id ON conversation_sessions(user_id);
CREATE INDEX idx_sessions_started_at ON conversation_sessions(started_at);
CREATE INDEX idx_messages_session_id ON conversation_messages(session_id);
CREATE INDEX idx_skill_snapshots_user_date ON skill_snapshots(user_id, snapshot_date);
CREATE INDEX idx_scenarios_difficulty ON scenarios(difficulty);
CREATE INDEX idx_scenarios_category ON scenarios(category);
CREATE INDEX idx_guard_violations_user_id ON guard_violations(user_id, created_at DESC);
CREATE INDEX idx_guard_violations_severity ON guard_violations(severity, created_at DESC);
```

---

## 2.2 SQLite Schema (Flutter App — Drift)

The app caches data locally for offline support and stores auth tokens.

### Drift Tables

```dart
// auth_cache table
class AuthCache extends Table {
  TextColumn get userId => text()();
  TextColumn get accessToken => text()();
  TextColumn get refreshToken => text()();
  DateTimeColumn get accessTokenExpiry => dateTime()();
  TextColumn get userJson => text()(); // serialized UserProfile
  @override
  Set<Column> get primaryKey => {userId};
}

// user_profile_cache table
class UserProfileCache extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarEmoji => text().withDefault(const Constant('🐣'))();
  TextColumn get uiLanguage => text().withDefault(const Constant('en'))();
  IntColumn get currentLevel => integer().withDefault(const Constant(1))();
  IntColumn get xpTotal => integer().withDefault(const Constant(0))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  TextColumn get activePersonaKey => text().withDefault(const Constant('maya'))();
  TextColumn get activeTheme => text().withDefault(const Constant('apricot'))();
  BoolColumn get onboardingDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

// scenarios_cache table
class ScenariosCache extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get category => text()();
  IntColumn get difficulty => integer()();
  TextColumn get titleJson => text()(); // {en, ko, zh}
  TextColumn get descriptionJson => text()();
  TextColumn get contentJson => text()(); // full scenario data
  IntColumn get xpReward => integer()();
  IntColumn get estimatedMinutes => integer()();
  DateTimeColumn get cachedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

// local_sessions table — sessions started offline
class LocalSessions extends Table {
  TextColumn get id => text()(); // local UUID
  TextColumn get serverId => text().nullable()(); // null until synced
  TextColumn get scenarioId => text().nullable()();
  TextColumn get personaKey => text()();
  TextColumn get mode => text().withDefault(const Constant('chat'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get turnCount => integer().withDefault(const Constant(0))();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

// local_messages table
class LocalMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get role => text()(); // user/assistant
  TextColumn get content => text()();
  IntColumn get sequence => integer()();
  DateTimeColumn get timestamp => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

// progress_cache table
class ProgressCache extends Table {
  TextColumn get userId => text()();
  IntColumn get sessionsTotal => integer().withDefault(const Constant(0))();
  IntColumn get minutesSpokenTotal => integer().withDefault(const Constant(0))();
  IntColumn get wordsSpokenTotal => integer().withDefault(const Constant(0))();
  IntColumn get scenariosCompleted => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  TextColumn get skillJson => text().nullable()(); // latest skill snapshot
  DateTimeColumn get cachedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {userId};
}

// app_settings table (device-local, not synced)
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}
```

### Settings Keys (AppSettings)
| Key | Values | Default | Notes |
|-----|--------|---------|-------|
| theme | apricot/sage/iris/obsidian | apricot | |
| ui_language | en/ko/zh | en (device locale) | |
| conversation_mode | chat/face | chat | |
| notifications_enabled | true/false | true | |
| font_size_scale | 0.9/1.0/1.1/1.2 | 1.0 | |
| compression_enabled | true/false | true | gzip toggle, see [11_security_and_performance §11.2](11_security_and_performance.md) |
| guard_warn_acknowledged_at | ISO timestamp | unset | last time user clicked "Continue anyway" on a warn-tier guard match (per-session state lives in memory, not here) |

---

## 2.3 Seed Data

- [ ] **2.3.1** Seed 4 personas (Maya, Leo, Sofia, Theo) with colors from tokens.json
- [ ] **2.3.2** Seed 20 starter scenarios across 4 categories
  - Travel (5): airport, hotel, restaurant, shopping, taxi
  - Business (5): meeting, email, presentation, negotiation, networking
  - Social (5): greeting, party, dating, sports, hobby
  - Daily Life (5): grocery, doctor, bank, directions, phone call
- [ ] **2.3.3** Seed 2 starter courses (Beginner A1-A2, Intermediate B1-B2)
- [ ] **2.3.4** Seed 15 achievements (streak-based, session-based, score-based)
- [ ] **2.3.5** Write TypeORM migration files for all tables

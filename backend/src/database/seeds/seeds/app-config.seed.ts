import { DataSource } from 'typeorm';
import { AppConfigEntity } from '../../entities/app-config.entity';

/**
 * Default catalog of remote-config flags (see todoList/12 §12.6).
 * The deploy reconciler inserts any keys missing from the DB without
 * overwriting admin edits to existing keys.
 */
interface ConfigSeed {
  key: string;
  value: unknown;
  value_type: 'boolean' | 'string' | 'number' | 'object' | 'array';
  category:
    | 'home'
    | 'evaluation'
    | 'progress'
    | 'conversation'
    | 'scenarios'
    | 'settings'
    | 'prompts'
    | 'system';
  description: string;
  is_visible_to_app?: boolean;
}

const CATALOG: ConfigSeed[] = [
  // ── Evaluation ───────────────────────────────────────────
  {
    key: 'evaluation.radar.skills.pronunciation',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Pronunciation axis on the radar chart',
  },
  {
    key: 'evaluation.radar.skills.fluency',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Fluency axis on the radar chart',
  },
  {
    key: 'evaluation.radar.skills.vocabulary',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Vocabulary axis on the radar chart',
  },
  {
    key: 'evaluation.radar.skills.grammar',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Grammar axis on the radar chart',
  },
  {
    key: 'evaluation.radar.skills.listening',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Listening axis on the radar chart',
  },
  {
    key: 'evaluation.report.overall_score_ring',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Large overall-score ring at top of report',
  },
  {
    key: 'evaluation.report.score_breakdown',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Animated bars for fluency/vocab/grammar/engagement',
  },
  {
    key: 'evaluation.report.xp_earned',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'XP count-up section',
  },
  {
    key: 'evaluation.report.ai_feedback',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'AI-generated feedback paragraph',
  },
  {
    key: 'evaluation.report.strengths',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Strengths list',
  },
  {
    key: 'evaluation.report.improvements',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Improvements list',
  },
  {
    key: 'evaluation.report.confetti',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Confetti burst on high score',
  },
  {
    key: 'evaluation.report.share_button',
    value: true,
    value_type: 'boolean',
    category: 'evaluation',
    description: 'Share to clipboard',
  },

  // ── Home ─────────────────────────────────────────────────
  {
    key: 'home.greeting',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'Greeting header',
  },
  {
    key: 'home.streak_banner',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'Streak banner',
  },
  {
    key: 'home.xp_progress',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'XP progress bar',
  },
  {
    key: 'home.continue_course',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'Course continuation card',
  },
  {
    key: 'home.quick_stats',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'Sessions / Minutes / Scenarios row',
  },
  {
    key: 'home.recommended_scenarios',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'Recommended scenarios scroller',
  },
  {
    key: 'home.recommended_scenarios.max_count',
    value: 4,
    value_type: 'number',
    category: 'home',
    description: 'Max recommendations shown',
  },
  {
    key: 'home.recent_activity',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'Recent activity list',
  },
  {
    key: 'home.notification_bell',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'Notification bell icon',
  },
  {
    key: 'home.news_strip',
    value: true,
    value_type: 'boolean',
    category: 'home',
    description: 'Horizontal news strip on the home screen',
  },

  // ── Progress ─────────────────────────────────────────────
  {
    key: 'progress.level_badge',
    value: true,
    value_type: 'boolean',
    category: 'progress',
    description: 'Level badge with XP bar',
  },
  {
    key: 'progress.stats_grid',
    value: true,
    value_type: 'boolean',
    category: 'progress',
    description: '2×2 stats cards',
  },
  {
    key: 'progress.streak_section',
    value: true,
    value_type: 'boolean',
    category: 'progress',
    description: 'Streak day count',
  },
  {
    key: 'progress.weekly_chart',
    value: true,
    value_type: 'boolean',
    category: 'progress',
    description: 'Minutes-spoken bar chart',
  },
  {
    key: 'progress.weekly_chart.weeks_shown',
    value: 8,
    value_type: 'number',
    category: 'progress',
    description: 'Number of weeks in the chart',
  },
  {
    key: 'progress.skill_radar',
    value: true,
    value_type: 'boolean',
    category: 'progress',
    description: 'Skill radar chart container',
  },
  {
    key: 'progress.achievements',
    value: true,
    value_type: 'boolean',
    category: 'progress',
    description: 'Achievements scroll',
  },

  // ── Scenarios ────────────────────────────────────────────
  {
    key: 'scenarios.search',
    value: true,
    value_type: 'boolean',
    category: 'scenarios',
    description: 'Search bar',
  },
  {
    key: 'scenarios.category_filter',
    value: true,
    value_type: 'boolean',
    category: 'scenarios',
    description: 'Category filter chips',
  },
  {
    key: 'scenarios.difficulty_filter',
    value: true,
    value_type: 'boolean',
    category: 'scenarios',
    description: 'Difficulty filter row',
  },

  // ── Conversation ─────────────────────────────────────────
  {
    key: 'conversation.mode',
    value: 'both',
    value_type: 'string',
    category: 'conversation',
    description: 'Conversation mode: tutor | message | both',
    is_visible_to_app: true,
  },
  {
    key: 'conversation.mode_toggle',
    value: true,
    value_type: 'boolean',
    category: 'conversation',
    description: 'Chat / Face mode toggle',
  },
  {
    key: 'conversation.face_mode_available',
    value: true,
    value_type: 'boolean',
    category: 'conversation',
    description: 'Face mode reachable at all',
  },
  {
    key: 'conversation.mic_button',
    value: true,
    value_type: 'boolean',
    category: 'conversation',
    description: 'Mic button (also gated by STT availability)',
  },
  {
    key: 'conversation.live_caption',
    value: true,
    value_type: 'boolean',
    category: 'conversation',
    description: 'Live caption on Face mode',
  },

  // ── Settings ─────────────────────────────────────────────
  {
    key: 'settings.profile_section',
    value: true,
    value_type: 'boolean',
    category: 'settings',
    description: 'Profile section (avatar + name)',
  },
  {
    key: 'settings.tutor_carousel',
    value: true,
    value_type: 'boolean',
    category: 'settings',
    description: 'Persona switcher carousel',
  },
  {
    key: 'settings.language_selector',
    value: true,
    value_type: 'boolean',
    category: 'settings',
    description: 'UI language switcher',
  },
  {
    key: 'settings.theme_selector',
    value: true,
    value_type: 'boolean',
    category: 'settings',
    description: 'Theme swatches',
  },
  {
    key: 'settings.learning_section',
    value: true,
    value_type: 'boolean',
    category: 'settings',
    description: 'Daily goal etc',
  },
  {
    key: 'settings.network_section',
    value: true,
    value_type: 'boolean',
    category: 'settings',
    description: 'Compression toggle',
  },
  {
    key: 'settings.storage_section',
    value: true,
    value_type: 'boolean',
    category: 'settings',
    description: 'Model storage status',
  },
  {
    key: 'settings.about_section',
    value: true,
    value_type: 'boolean',
    category: 'settings',
    description: 'About / Terms / Privacy',
  },

  // ── Navigation tabs ──────────────────────────────────────
  {
    key: 'tabs.home',
    value: true,
    value_type: 'boolean',
    category: 'system',
    description: 'Show Home tab in the bottom nav bar / sidebar',
    is_visible_to_app: true,
  },
  {
    key: 'tabs.scenarios',
    value: true,
    value_type: 'boolean',
    category: 'system',
    description: 'Show Scenarios tab in the bottom nav bar / sidebar',
    is_visible_to_app: true,
  },
  {
    key: 'tabs.history',
    value: true,
    value_type: 'boolean',
    category: 'system',
    description:
      'Show Conversation history tab in the bottom nav bar / sidebar',
    is_visible_to_app: true,
  },
  {
    key: 'tabs.progress',
    value: true,
    value_type: 'boolean',
    category: 'system',
    description: 'Show Progress tab in the bottom nav bar / sidebar',
    is_visible_to_app: true,
  },
  {
    key: 'tabs.settings',
    value: true,
    value_type: 'boolean',
    category: 'system',
    description: 'Show Settings tab in the bottom nav bar / sidebar',
    is_visible_to_app: true,
  },

  // ── Prompt sections ──────────────────────────────────────
  // Section toggles — turn a section off to drop it from the system prompt
  // sent to the AI provider. Default on. Restart not required; applied on
  // the next conversation turn.
  { key: 'prompt.section.role',           value: true, value_type: 'boolean', category: 'prompts', description: 'Include [role] section (persona identity + tutor role)' },
  { key: 'prompt.section.learner',        value: true, value_type: 'boolean', category: 'prompts', description: 'Include [learner] section (user role description)' },
  { key: 'prompt.section.topic',          value: true, value_type: 'boolean', category: 'prompts', description: 'Include [topic] section (scenario title)' },
  { key: 'prompt.section.subtopics',      value: true, value_type: 'boolean', category: 'prompts', description: 'Include [subtopics] section (objectives + key phrases)' },
  { key: 'prompt.section.cefr_level',     value: true, value_type: 'boolean', category: 'prompts', description: 'Include [cefr_level] section (learner level)' },
  { key: 'prompt.section.locale',         value: true, value_type: 'boolean', category: 'prompts', description: 'Include [locale] section (country / audience context)' },
  { key: 'prompt.section.avoided_topics', value: true, value_type: 'boolean', category: 'prompts', description: 'Include [avoided_topics] section' },
  { key: 'prompt.section.guidelines',     value: true, value_type: 'boolean', category: 'prompts', description: 'Include [guidelines] section (behavior rules)' },

  // Locale values — used when prompt.section.locale is on
  { key: 'prompt.locale.country',          value: 'China',                          value_type: 'string', category: 'prompts', description: 'Country name for locale context' },
  { key: 'prompt.locale.country_adjective',value: 'Chinese',                        value_type: 'string', category: 'prompts', description: 'Adjective form of country (e.g. Chinese)' },
  { key: 'prompt.locale.learner_audience', value: 'adult learners of English',       value_type: 'string', category: 'prompts', description: 'Description of the target learner audience' },
  { key: 'prompt.locale.avoid_cultures',   value: 'American or European',           value_type: 'string', category: 'prompts', description: 'Default cultures to avoid in examples' },

  // Avoided topics — used when prompt.section.avoided_topics is on
  {
    key: 'prompt.avoided_topics',
    value: 'Stay clear of politics, religion, alcohol, dating, partisan history, violence, harm, and distress.',
    value_type: 'string',
    category: 'prompts',
    description: 'Topics the tutor must not discuss',
  },

  // ── User reports & usage analytics ──────────────────────
  {
    key: 'system.user_report_enabled',
    value: true,
    value_type: 'boolean',
    category: 'system',
    description: 'Show the "Send feedback / report a bug" button in the app settings screen',
    is_visible_to_app: true,
  },
  {
    key: 'system.usage_analytics_enabled',
    value: true,
    value_type: 'boolean',
    category: 'system',
    description: 'Track per-platform session counts and network bytes (stored in vl_user_network_stats)',
  },

  // ── App defaults (sent to app on every launch) ──────────
  {
    key: 'app.default_language',
    value: 'en',
    value_type: 'string',
    category: 'system',
    description: 'Default UI language shown on first launch before the user picks one (en | zh | ru | ko)',
    is_visible_to_app: true,
  },

  // ── System ───────────────────────────────────────────────
  {
    key: 'system.maintenance_banner',
    value: { enabled: false, message_i18n_key: null },
    value_type: 'object',
    category: 'system',
    description: 'App-wide maintenance banner',
  },
  {
    key: 'system.min_app_version',
    value: '1.0.0',
    value_type: 'string',
    category: 'system',
    description: 'Minimum app version (forces upgrade if older)',
  },
  {
    key: 'system.gzip_enabled',
    value: true,
    value_type: 'boolean',
    category: 'system',
    description: 'Server compresses responses larger than the threshold',
    is_visible_to_app: true,
  },
  {
    key: 'tts.voice_ids',
    value: [
      'en_VCTK-amy', 'en_VCTK-james',
      'en_VCTK-p227-m', 'en_VCTK-p228-f', 'en_VCTK-p229-f', 'en_VCTK-p230-f',
      'en_VCTK-p231-m', 'en_VCTK-p232-m', 'en_VCTK-p233-f', 'en_VCTK-p234-f',
      'en_VCTK-p235-m', 'en_VCTK-p236-f', 'en_VCTK-p237-m', 'en_VCTK-p238-f',
      'en_VCTK-p239-f', 'en_VCTK-p240-f', 'en_VCTK-p241-m', 'en_VCTK-p242-f',
      'en_VCTK-p243-m', 'en_VCTK-p244-f', 'en_VCTK-p245-m', 'en_VCTK-p246-m',
      'en_VCTK-p247-m', 'en_VCTK-p248-f', 'en_VCTK-p249-f', 'en_VCTK-p250-m',
      'en_VCTK-p251-f', 'en_VCTK-p252-m', 'en_VCTK-p253-m', 'en_VCTK-p254-m',
      'en_VCTK-p255-m', 'en_VCTK-p256-m', 'en_VCTK-p257-f', 'en_VCTK-p258-m',
      'en_VCTK-p259-m', 'en_VCTK-p260-m', 'en_VCTK-p261-f', 'en_VCTK-p262-m',
      'en_VCTK-p263-m', 'en_VCTK-p264-m', 'en_VCTK-p265-f', 'en_VCTK-p266-f',
      'en_VCTK-p267-m', 'en_VCTK-p268-f', 'en_VCTK-p269-f', 'en_VCTK-p270-m',
      'en_VCTK-p271-m', 'en_VCTK-p272-m', 'en_VCTK-p273-m', 'en_VCTK-p274-m',
      'en_VCTK-p275-m', 'en_VCTK-p276-f', 'en_VCTK-p277-m', 'en_VCTK-p278-f',
      'en_VCTK-p279-f', 'en_VCTK-p280-f', 'en_VCTK-p281-m', 'en_VCTK-p282-f',
      'en_VCTK-p283-m', 'en_VCTK-p284-m', 'en_VCTK-p285-m', 'en_VCTK-p286-m',
      'en_VCTK-p287-f', 'en_VCTK-p288-f', 'en_VCTK-p292-m', 'en_VCTK-p293-m',
      'en_VCTK-p294-f', 'en_VCTK-p295-f', 'en_VCTK-p297-m', 'en_VCTK-p298-m',
      'en_VCTK-p299-m', 'en_VCTK-p300-f', 'en_VCTK-p301-f', 'en_VCTK-p302-m',
      'en_VCTK-p303-f', 'en_VCTK-p304-m', 'en_VCTK-p305-f', 'en_VCTK-p306-f',
      'en_VCTK-p307-m', 'en_VCTK-p308-f', 'en_VCTK-p310-f', 'en_VCTK-p311-m',
      'en_VCTK-p312-m', 'en_VCTK-p313-m', 'en_VCTK-p314-m', 'en_VCTK-p316-m',
      'en_VCTK-p317-m', 'en_VCTK-p318-f', 'en_VCTK-p323-m', 'en_VCTK-p326-m',
      'en_VCTK-p329-f', 'en_VCTK-p330-m', 'en_VCTK-p333-m', 'en_VCTK-p334-m',
      'en_VCTK-p335-m', 'en_VCTK-p336-m', 'en_VCTK-p339-f', 'en_VCTK-p340-m',
      'en_VCTK-p341-m', 'en_VCTK-p343-f', 'en_VCTK-p345-m', 'en_VCTK-p347-f',
      'en_VCTK-p351-f', 'en_VCTK-p360-m', 'en_VCTK-p361-m', 'en_VCTK-p362-m',
      'en_VCTK-p363-m', 'en_VCTK-p364-m', 'en_VCTK-p374-f',
    ],
    value_type: 'array',
    category: 'system',
    description:
      'Available TTS voice IDs shown in the admin tutor edit dropdown. ' +
      'Must match the voices list in manifest.json (same names, same order = same speaker SIDs).',
    is_visible_to_app: false,
  },
];

export async function seedAppConfig(ds: DataSource): Promise<void> {
  const repo = ds.getRepository(AppConfigEntity);
  for (const c of CATALOG) {
    const existing = await repo.findOne({ where: { key: c.key } });
    if (existing) {
      // Only update description / default_value / category / value_type / is_visible_to_app.
      // Preserve admin-edited value.
      existing.value_type = c.value_type;
      existing.category = c.category;
      existing.description = c.description;
      existing.default_value = c.value;
      existing.is_visible_to_app = c.is_visible_to_app ?? true;
      await repo.save(existing);
    } else {
      await repo.save(
        repo.create({
          key: c.key,
          value: c.value,
          value_type: c.value_type,
          category: c.category,
          description: c.description,
          default_value: c.value,
          is_visible_to_app: c.is_visible_to_app ?? true,
        }),
      );
    }
  }
}

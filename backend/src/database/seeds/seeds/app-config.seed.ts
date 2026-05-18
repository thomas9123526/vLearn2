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
  category: 'home' | 'evaluation' | 'progress' | 'conversation' | 'scenarios' | 'settings' | 'system';
  description: string;
  is_visible_to_app?: boolean;
}

const CATALOG: ConfigSeed[] = [
  // ── Evaluation ───────────────────────────────────────────
  { key: 'evaluation.radar.skills.pronunciation', value: true, value_type: 'boolean', category: 'evaluation', description: 'Pronunciation axis on the radar chart' },
  { key: 'evaluation.radar.skills.fluency',       value: true, value_type: 'boolean', category: 'evaluation', description: 'Fluency axis on the radar chart' },
  { key: 'evaluation.radar.skills.vocabulary',    value: true, value_type: 'boolean', category: 'evaluation', description: 'Vocabulary axis on the radar chart' },
  { key: 'evaluation.radar.skills.grammar',       value: true, value_type: 'boolean', category: 'evaluation', description: 'Grammar axis on the radar chart' },
  { key: 'evaluation.radar.skills.listening',     value: true, value_type: 'boolean', category: 'evaluation', description: 'Listening axis on the radar chart' },
  { key: 'evaluation.report.overall_score_ring',  value: true, value_type: 'boolean', category: 'evaluation', description: 'Large overall-score ring at top of report' },
  { key: 'evaluation.report.score_breakdown',     value: true, value_type: 'boolean', category: 'evaluation', description: 'Animated bars for fluency/vocab/grammar/engagement' },
  { key: 'evaluation.report.xp_earned',           value: true, value_type: 'boolean', category: 'evaluation', description: 'XP count-up section' },
  { key: 'evaluation.report.ai_feedback',         value: true, value_type: 'boolean', category: 'evaluation', description: 'AI-generated feedback paragraph' },
  { key: 'evaluation.report.strengths',           value: true, value_type: 'boolean', category: 'evaluation', description: 'Strengths list' },
  { key: 'evaluation.report.improvements',        value: true, value_type: 'boolean', category: 'evaluation', description: 'Improvements list' },
  { key: 'evaluation.report.confetti',            value: true, value_type: 'boolean', category: 'evaluation', description: 'Confetti burst on high score' },
  { key: 'evaluation.report.share_button',        value: true, value_type: 'boolean', category: 'evaluation', description: 'Share to clipboard' },

  // ── Home ─────────────────────────────────────────────────
  { key: 'home.greeting',                value: true, value_type: 'boolean', category: 'home', description: 'Greeting header' },
  { key: 'home.streak_banner',           value: true, value_type: 'boolean', category: 'home', description: 'Streak banner' },
  { key: 'home.xp_progress',             value: true, value_type: 'boolean', category: 'home', description: 'XP progress bar' },
  { key: 'home.continue_course',         value: true, value_type: 'boolean', category: 'home', description: 'Course continuation card' },
  { key: 'home.quick_stats',             value: true, value_type: 'boolean', category: 'home', description: 'Sessions / Minutes / Scenarios row' },
  { key: 'home.recommended_scenarios',   value: true, value_type: 'boolean', category: 'home', description: 'Recommended scenarios scroller' },
  { key: 'home.recommended_scenarios.max_count', value: 4, value_type: 'number', category: 'home', description: 'Max recommendations shown' },
  { key: 'home.recent_activity',         value: true, value_type: 'boolean', category: 'home', description: 'Recent activity list' },
  { key: 'home.notification_bell',       value: true, value_type: 'boolean', category: 'home', description: 'Notification bell icon' },
  { key: 'home.news_strip',              value: true, value_type: 'boolean', category: 'home', description: 'Horizontal news strip on the home screen' },

  // ── Progress ─────────────────────────────────────────────
  { key: 'progress.level_badge',         value: true, value_type: 'boolean', category: 'progress', description: 'Level badge with XP bar' },
  { key: 'progress.stats_grid',          value: true, value_type: 'boolean', category: 'progress', description: '2×2 stats cards' },
  { key: 'progress.streak_section',      value: true, value_type: 'boolean', category: 'progress', description: 'Streak day count' },
  { key: 'progress.weekly_chart',        value: true, value_type: 'boolean', category: 'progress', description: 'Minutes-spoken bar chart' },
  { key: 'progress.weekly_chart.weeks_shown', value: 8, value_type: 'number', category: 'progress', description: 'Number of weeks in the chart' },
  { key: 'progress.skill_radar',         value: true, value_type: 'boolean', category: 'progress', description: 'Skill radar chart container' },
  { key: 'progress.achievements',        value: true, value_type: 'boolean', category: 'progress', description: 'Achievements scroll' },

  // ── Scenarios ────────────────────────────────────────────
  { key: 'scenarios.search',             value: true, value_type: 'boolean', category: 'scenarios', description: 'Search bar' },
  { key: 'scenarios.category_filter',    value: true, value_type: 'boolean', category: 'scenarios', description: 'Category filter chips' },
  { key: 'scenarios.difficulty_filter',  value: true, value_type: 'boolean', category: 'scenarios', description: 'Difficulty filter row' },

  // ── Conversation ─────────────────────────────────────────
  { key: 'conversation.mode_toggle',          value: true, value_type: 'boolean', category: 'conversation', description: 'Chat / Face mode toggle' },
  { key: 'conversation.face_mode_available',  value: true, value_type: 'boolean', category: 'conversation', description: 'Face mode reachable at all' },
  { key: 'conversation.mic_button',           value: true, value_type: 'boolean', category: 'conversation', description: 'Mic button (also gated by STT availability)' },
  { key: 'conversation.live_caption',         value: true, value_type: 'boolean', category: 'conversation', description: 'Live caption on Face mode' },

  // ── Settings ─────────────────────────────────────────────
  { key: 'settings.profile_section',     value: true, value_type: 'boolean', category: 'settings', description: 'Profile section (avatar + name)' },
  { key: 'settings.tutor_carousel',      value: true, value_type: 'boolean', category: 'settings', description: 'Persona switcher carousel' },
  { key: 'settings.language_selector',   value: true, value_type: 'boolean', category: 'settings', description: 'UI language switcher' },
  { key: 'settings.theme_selector',      value: true, value_type: 'boolean', category: 'settings', description: 'Theme swatches' },
  { key: 'settings.learning_section',    value: true, value_type: 'boolean', category: 'settings', description: 'Daily goal etc' },
  { key: 'settings.network_section',     value: true, value_type: 'boolean', category: 'settings', description: 'Compression toggle' },
  { key: 'settings.storage_section',     value: true, value_type: 'boolean', category: 'settings', description: 'Model storage status' },
  { key: 'settings.about_section',       value: true, value_type: 'boolean', category: 'settings', description: 'About / Terms / Privacy' },

  // ── Navigation tabs ──────────────────────────────────────
  { key: 'tabs.home',      value: true, value_type: 'boolean', category: 'system', description: 'Show Home tab in the bottom nav bar', is_visible_to_app: true },
  { key: 'tabs.scenarios', value: true, value_type: 'boolean', category: 'system', description: 'Show Scenarios tab in the bottom nav bar', is_visible_to_app: true },
  { key: 'tabs.progress',  value: true, value_type: 'boolean', category: 'system', description: 'Show Progress tab in the bottom nav bar', is_visible_to_app: true },
  { key: 'tabs.settings',  value: true, value_type: 'boolean', category: 'system', description: 'Show Settings tab in the bottom nav bar', is_visible_to_app: true },

  // ── System ───────────────────────────────────────────────
  { key: 'system.maintenance_banner',    value: { enabled: false, message_i18n_key: null }, value_type: 'object', category: 'system', description: 'App-wide maintenance banner' },
  { key: 'system.min_app_version',       value: '1.0.0', value_type: 'string', category: 'system', description: 'Minimum app version (forces upgrade if older)' },
  { key: 'system.gzip_enabled',          value: true,    value_type: 'boolean', category: 'system', description: 'Server compresses responses larger than the threshold', is_visible_to_app: true },
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
      await repo.save(repo.create({
        key: c.key,
        value: c.value,
        value_type: c.value_type,
        category: c.category,
        description: c.description,
        default_value: c.value,
        is_visible_to_app: c.is_visible_to_app ?? true,
      }));
    }
  }
}

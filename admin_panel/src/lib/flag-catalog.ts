// Catalog of visibility flags grouped by app tab, with "big layout" entries
// separated from fine-grained sub-knobs. The admin Config page reads this to
// render one tab per app screen, with big toggles up top and an Advanced
// expander for the rest.
//
// Keep keys in sync with `flutter_app/lib/core/config/layout_config_provider.dart`
// and `backend/src/database/seeds/seeds/app-config.seed.ts`.

export type AppTab =
  | 'home'
  | 'scenarios'
  | 'conversation'
  | 'progress'
  | 'settings'
  | 'report'
  | 'navigation'
  | 'system';

export interface FlagDescriptor {
  key: string;
  label: string;
  tier: 'big' | 'fine';
  tab: AppTab;
}

export const APP_TABS: { id: AppTab; label: string; hint: string }[] = [
  { id: 'home', label: 'Home', hint: 'Daily dashboard — what the user sees on launch.' },
  { id: 'scenarios', label: 'Scenarios', hint: 'Topic picker and category filters.' },
  { id: 'conversation', label: 'Conversation', hint: 'Live chat and Tutor (face) mode.' },
  { id: 'progress', label: 'Progress', hint: 'CEFR card, weekly chart, skills, completions.' },
  { id: 'settings', label: 'Settings', hint: 'Profile, theme, tutor, network, storage.' },
  { id: 'report', label: 'Report', hint: 'Post-session evaluation screen.' },
  { id: 'navigation', label: 'Navigation', hint: 'Show or hide the bottom navigation tabs.' },
  { id: 'system', label: 'System', hint: 'App-wide overrides (gzip, maintenance banner).' },
];

export const FLAG_CATALOG: FlagDescriptor[] = [
  // ── Home ────────────────────────────────────────────────────────────────
  { key: 'home.greeting', label: 'Greeting header', tier: 'big', tab: 'home' },
  { key: 'home.streak_banner', label: 'Streak banner', tier: 'big', tab: 'home' },
  { key: 'home.news_strip', label: 'News strip', tier: 'big', tab: 'home' },
  { key: 'home.quick_stats', label: 'Quick stats row', tier: 'big', tab: 'home' },
  { key: 'home.recommended_scenarios', label: 'Recommended scenarios', tier: 'big', tab: 'home' },
  { key: 'home.continue_course', label: 'Continue course card', tier: 'fine', tab: 'home' },
  { key: 'home.recent_activity', label: 'Recent activity list', tier: 'fine', tab: 'home' },
  { key: 'home.notification_bell', label: 'Notification bell', tier: 'fine', tab: 'home' },
  { key: 'home.xp_progress', label: 'XP progress bar', tier: 'fine', tab: 'home' },

  // ── Scenarios ───────────────────────────────────────────────────────────
  { key: 'scenarios.search', label: 'Search bar', tier: 'big', tab: 'scenarios' },
  { key: 'scenarios.category_filter', label: 'Category filter chips', tier: 'big', tab: 'scenarios' },
  { key: 'scenarios.difficulty_filter', label: 'Difficulty filter row', tier: 'big', tab: 'scenarios' },

  // ── Conversation ────────────────────────────────────────────────────────
  { key: 'conversation.face_mode_available', label: 'Tutor (face) mode available', tier: 'big', tab: 'conversation' },
  { key: 'conversation.mode_toggle', label: 'Chat / Face mode toggle', tier: 'big', tab: 'conversation' },
  { key: 'conversation.mic_button', label: 'Mic / voice input', tier: 'big', tab: 'conversation' },
  { key: 'conversation.live_caption', label: 'Live caption in Face mode', tier: 'fine', tab: 'conversation' },

  // ── Progress ────────────────────────────────────────────────────────────
  { key: 'progress.level_badge', label: 'CEFR level card', tier: 'big', tab: 'progress' },
  { key: 'progress.weekly_chart', label: 'Activity / weekly chart', tier: 'big', tab: 'progress' },
  { key: 'progress.skill_radar', label: 'Skill breakdown', tier: 'big', tab: 'progress' },
  { key: 'progress.achievements', label: 'Achievements / completions', tier: 'big', tab: 'progress' },
  { key: 'progress.stats_grid', label: '2×2 stats cards', tier: 'fine', tab: 'progress' },
  { key: 'progress.streak_section', label: 'Streak section', tier: 'fine', tab: 'progress' },

  // ── Settings ────────────────────────────────────────────────────────────
  { key: 'settings.profile_section', label: 'Profile card', tier: 'big', tab: 'settings' },
  { key: 'settings.tutor_carousel', label: 'Tutor / persona switcher', tier: 'big', tab: 'settings' },
  { key: 'settings.theme_selector', label: 'Theme swatches', tier: 'big', tab: 'settings' },
  { key: 'settings.language_selector', label: 'Language selector', tier: 'big', tab: 'settings' },
  { key: 'settings.storage_section', label: 'Storage / model bundle', tier: 'big', tab: 'settings' },
  { key: 'settings.learning_section', label: 'Learning preferences', tier: 'fine', tab: 'settings' },
  { key: 'settings.network_section', label: 'Network section', tier: 'fine', tab: 'settings' },
  { key: 'settings.about_section', label: 'About section', tier: 'fine', tab: 'settings' },

  // ── Report (post-session evaluation) ────────────────────────────────────
  { key: 'evaluation.report.overall_score_ring', label: 'Score ring', tier: 'big', tab: 'report' },
  { key: 'evaluation.report.score_breakdown', label: 'Per-skill bars', tier: 'big', tab: 'report' },
  { key: 'evaluation.report.xp_earned', label: 'XP earned section', tier: 'big', tab: 'report' },
  { key: 'evaluation.report.ai_feedback', label: 'AI feedback paragraph', tier: 'big', tab: 'report' },
  { key: 'evaluation.report.strengths', label: 'Strengths list', tier: 'fine', tab: 'report' },
  { key: 'evaluation.report.improvements', label: 'Improvements list', tier: 'fine', tab: 'report' },
  { key: 'evaluation.report.confetti', label: 'Confetti burst', tier: 'fine', tab: 'report' },
  { key: 'evaluation.report.share_button', label: 'Share button', tier: 'fine', tab: 'report' },

  // ── Navigation tabs ─────────────────────────────────────────────────────
  { key: 'tabs.home',      label: 'Home tab',                 tier: 'big', tab: 'navigation' },
  { key: 'tabs.scenarios', label: 'Scenarios tab',            tier: 'big', tab: 'navigation' },
  { key: 'tabs.history',   label: 'Conversation history tab', tier: 'big', tab: 'navigation' },
  { key: 'tabs.progress',  label: 'Progress tab',             tier: 'big', tab: 'navigation' },
  { key: 'tabs.settings',  label: 'Settings tab',             tier: 'big', tab: 'navigation' },

  // ── System (always shown last; advanced-only by default) ───────────────
  { key: 'system.gzip_enabled', label: 'Gzip response compression', tier: 'big', tab: 'system' },
  { key: 'system.maintenance_banner', label: 'Maintenance banner', tier: 'fine', tab: 'system' },
  { key: 'system.min_app_version', label: 'Minimum app version', tier: 'fine', tab: 'system' },
];

export function descriptorFor(key: string): FlagDescriptor | undefined {
  return FLAG_CATALOG.find((d) => d.key === key);
}

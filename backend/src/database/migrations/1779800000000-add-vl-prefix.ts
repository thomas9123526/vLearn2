import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddVlPrefix1779800000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    const renames: [string, string][] = [
      ['achievements',              'vl_achievements'],
      ['user_achievements',         'vl_user_achievements'],
      ['admin_audit_log',           'vl_admin_audit_log'],
      ['admin_permissions',         'vl_admin_permissions'],
      ['admin_refresh_tokens',      'vl_admin_refresh_tokens'],
      ['admins',                    'vl_admins'],
      ['app_config',                'vl_app_config'],
      ['conversation_sessions',     'vl_conversation_sessions'],
      ['conversation_messages',     'vl_conversation_messages'],
      ['session_scores',            'vl_session_scores'],
      ['courses',                   'vl_courses'],
      ['course_scenarios',          'vl_course_scenarios'],
      ['guard_violations',          'vl_guard_violations'],
      ['news_posts',                'vl_news_posts'],
      ['news_read_status',          'vl_news_read_status'],
      ['personas',                  'vl_personas'],
      ['refresh_tokens',            'vl_refresh_tokens'],
      ['scenarios',                 'vl_scenarios'],
      ['skill_snapshots',           'vl_skill_snapshots'],
      ['uploaded_files',            'vl_uploaded_files'],
      ['user_progress',             'vl_user_progress'],
      ['user_scenario_completions', 'vl_user_scenario_completions'],
    ];

    for (const [from, to] of renames) {
      await queryRunner.query(
        `ALTER TABLE IF EXISTS "${from}" RENAME TO "${to}"`,
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const renames: [string, string][] = [
      ['vl_achievements',              'achievements'],
      ['vl_user_achievements',         'user_achievements'],
      ['vl_admin_audit_log',           'admin_audit_log'],
      ['vl_admin_permissions',         'admin_permissions'],
      ['vl_admin_refresh_tokens',      'admin_refresh_tokens'],
      ['vl_admins',                    'admins'],
      ['vl_app_config',                'app_config'],
      ['vl_conversation_sessions',     'conversation_sessions'],
      ['vl_conversation_messages',     'conversation_messages'],
      ['vl_session_scores',            'session_scores'],
      ['vl_courses',                   'courses'],
      ['vl_course_scenarios',          'course_scenarios'],
      ['vl_guard_violations',          'guard_violations'],
      ['vl_news_posts',                'news_posts'],
      ['vl_news_read_status',          'news_read_status'],
      ['vl_personas',                  'personas'],
      ['vl_refresh_tokens',            'refresh_tokens'],
      ['vl_scenarios',                 'scenarios'],
      ['vl_skill_snapshots',           'skill_snapshots'],
      ['vl_uploaded_files',            'uploaded_files'],
      ['vl_user_progress',             'user_progress'],
      ['vl_user_scenario_completions', 'user_scenario_completions'],
    ];

    for (const [from, to] of renames) {
      await queryRunner.query(
        `ALTER TABLE IF EXISTS "${from}" RENAME TO "${to}"`,
      );
    }
  }
}

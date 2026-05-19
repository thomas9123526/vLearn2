import { MigrationInterface, QueryRunner } from 'typeorm';

const DEFAULT_TUTOR_SYSTEM = `You are {{persona.name}}, an English language tutor with a {{persona.style}} teaching style.
Your specialties include: {{persona.specialties}}.

CURRENT SCENARIO:
Title: {{scenario.title}}
Setting: {{scenario.setting}}
Your role: {{scenario.tutor_role}}
User's role: {{scenario.user_role}}
Objectives: {{scenario.objectives}}
Key phrases to encourage: {{scenario.key_phrases}}

USER PROFILE:
- English level: {{user.level_label}} ({{user.level}}/6)
- Native language: {{user.native_language}}

INSTRUCTIONS:
1. Stay in character as {{persona.name}} throughout.
2. Adjust vocabulary and sentence complexity to level {{user.level}}/6.
3. Respond naturally and conversationally (2-4 sentences usually).
4. Correct grammar errors GENTLY and IMPLICITLY by modeling correct usage in your reply.
5. Celebrate good English with encouragement appropriate to your personality.
6. If objectives exist, naturally guide conversation toward them.
7. Encourage use of the key phrases when appropriate.
8. Do NOT explicitly state you are an AI unless directly asked.
9. Do NOT break character.
10. If the user writes in their native language, gently encourage English with a translation hint.`;

const DEFAULT_GRAMMAR = `Analyze the grammar quality of these English messages from a level {{user.level}}/6 English learner.

Messages:
{{user.messages}}

Grammar score guidelines:
- 0-30: Many basic errors (wrong tense, subject-verb, articles)
- 31-60: Some errors, mostly understandable
- 61-80: Few errors, good grammatical control
- 81-100: Very few/no errors, sophisticated usage`;

const DEFAULT_FEEDBACK = `Write a 2-3 sentence encouraging feedback paragraph for an English learner.

Session data:
- Scenario: {{session.scenario_title}}
- Overall score: {{session.overall_score}}/100
- Fluency: {{session.fluency_score}}/100
- Vocabulary: {{session.vocabulary_score}}/100
- Grammar: {{session.grammar_score}}/100
- Engagement: {{session.engagement_score}}/100
- User level: {{user.level_label}}
- Strongest area: {{session.strongest_skill}}
- Area to improve: {{session.weakest_skill}}

Write in a warm, motivating tone. Mention 1 specific thing they did well. Keep it concise — max 60 words.`;

export class PromptTemplates1780300000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS vl_prompt_templates (
        id uuid NOT NULL DEFAULT gen_random_uuid(),
        kind character varying(50) NOT NULL,
        label character varying(200) NOT NULL,
        description text,
        template text NOT NULL,
        is_active boolean NOT NULL DEFAULT true,
        updated_at timestamp with time zone NOT NULL DEFAULT now(),
        CONSTRAINT pk_vl_prompt_templates PRIMARY KEY (id)
      )
    `);
    await queryRunner.query(
      `CREATE UNIQUE INDEX IF NOT EXISTS uq_vl_prompt_templates_kind ON vl_prompt_templates (kind)`,
    );

    // Seed the three default templates (idempotent via ON CONFLICT DO NOTHING).
    for (const row of [
      {
        kind: 'tutor_system',
        label: 'Tutor system prompt',
        description:
          'System message sent to the AI at the start of every conversation. Variables: {{persona.*}}, {{scenario.*}}, {{user.*}}.',
        template: DEFAULT_TUTOR_SYSTEM,
      },
      {
        kind: 'grammar',
        label: 'Grammar analysis prompt',
        description:
          'User-side prompt for the grammar scoring pipeline. Variables: {{user.level}}, {{user.messages}}.',
        template: DEFAULT_GRAMMAR,
      },
      {
        kind: 'feedback',
        label: 'Session feedback prompt',
        description:
          'Generates the end-of-session feedback paragraph. Variables: {{user.level_label}}, {{session.*}}.',
        template: DEFAULT_FEEDBACK,
      },
    ]) {
      await queryRunner.query(
        `INSERT INTO vl_prompt_templates (kind, label, description, template)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (kind) DO NOTHING`,
        [row.kind, row.label, row.description, row.template],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS vl_prompt_templates`);
  }
}

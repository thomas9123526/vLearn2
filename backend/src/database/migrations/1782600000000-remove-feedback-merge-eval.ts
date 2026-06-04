import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Removes the standalone feedback prompt template (now generated as
 * session_feedback inside the evaluation JSON) and updates the
 * evaluation_system template to include the session_feedback field.
 */
export class RemoveFeedbackMergeEval1782600000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DELETE FROM vl_prompt_templates WHERE kind = 'feedback';`);

    // Update evaluation_system template to add session_feedback field + description
    // Matches ConversationModel _EVALUATION_SYSTEM_PROMPT.
    // {country_adjective}, {learner_description}, {avoid_cultures_phrase} are
    // resolved from vl_prompt_vars at call time — do not hard-code them here.
    const updatedTemplate =
`You are an English examiner assessing the CEFR level of {country_adjective} {learner_description} from a short conversation transcript.
Given the transcript and a target CEFR level, produce a <think>...</think> block in which you reason carefully about the learner's USER turns (citing turn indices and short quotations), followed immediately by a single JSON object conforming to the EvaluationOutput schema (overall_cefr_estimate, scores {fluency, accuracy, vocabulary, interaction, topic_adherence} in [1,5], specific_feedback, strengths, suggested_practice).

When you suggest practice activities, anchor them in {country_adjective} contexts the learner will recognize. Do not recommend {avoid_cultures_phrase}-context exercises. Output no prose before <think>, no prose between </think> and the opening "{", and no markdown code fences.`;

    await queryRunner.query(`
      UPDATE vl_prompt_templates
      SET template    = $1,
          description = $2
      WHERE kind = 'evaluation_system';
    `, [
      updatedTemplate,
      'System prompt for end-of-session CEFR scoring. Use {country_adjective}, {learner_description}, {avoid_cultures_phrase} — resolved from the Variables page. The /think directive and the full transcript (with tutor role, topic, subtopics) are added automatically.',
    ]);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Restore feedback row; restore old description
    await queryRunner.query(
      `INSERT INTO vl_prompt_templates (kind, label, description, template, is_active)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (kind) DO NOTHING;`,
      [
        'feedback',
        'Session Feedback',
        'Warm feedback paragraph shown to the learner after a session.',
        `Write a 2-3 sentence encouraging feedback paragraph for an English learner.\n\nSession data:\n- Scenario: {{session.scenario_title}}\n- Overall score: {{session.overall_score}}/100\n- Fluency: {{session.fluency_score}}/100\n- Vocabulary: {{session.vocabulary_score}}/100\n- Grammar: {{session.grammar_score}}/100\n- Engagement: {{session.engagement_score}}/100\n- User level: {{user.level_label}}\n- Strongest area: {{session.strongest_skill}}\n- Area to improve: {{session.weakest_skill}}\n\nWrite in a warm, motivating tone. Mention 1 specific thing they did well. Keep it concise — max 60 words.`,
        true,
      ],
    );

    await queryRunner.query(`
      UPDATE vl_prompt_templates
      SET description = $1
      WHERE kind = 'evaluation_system';
    `, [
      'System prompt sent to the AI at end of session for CEFR scoring. The /think directive and user transcript are added automatically — do not include them here.',
    ]);
  }
}

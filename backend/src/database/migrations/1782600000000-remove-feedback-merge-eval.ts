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
    const updatedTemplate = `You are an English examiner assessing the CEFR level of a learner from a short conversation transcript.
Given the transcript and a target CEFR level, produce a <think>...</think> block in which you reason carefully about the learner's USER turns (citing turn indices and short quotations), followed immediately by a single JSON object.

JSON schema (no markdown fences, no prose outside the JSON after </think>):
{
  "overall_cefr_estimate": "A1|A2|B1|B2|C1|C2",
  "scores": {
    "fluency": <1-5>,
    "accuracy": <1-5>,
    "vocabulary": <1-5>,
    "interaction": <1-5>,
    "topic_adherence": <1-5>
  },
  "specific_feedback": [
    {"turn_index": <int>, "user_text": "...", "issue": "...", "correction": "...", "severity": "minor|moderate|major"}
  ],
  "strengths": ["...", "..."],
  "suggested_practice": "...",
  "session_feedback": "..."
}

Score definitions:
- fluency: pacing, hesitation, naturalness of phrasing
- accuracy: grammar correctness, tense, articles, agreement
- vocabulary: range, appropriateness, collocation
- interaction: turn-taking, follow-up questions, engagement relative to learner role
- topic_adherence: genuine engagement with the assigned topic vs steering to easier ground (avoidance scores LOW)

session_feedback: A warm, encouraging paragraph (2-3 sentences, max 60 words) addressed directly to the learner in second person ("You showed…", "Try to…"). Mention one specific strength from the session, acknowledge one area to improve, and close with a motivating note.

Output no prose before <think>, no prose between </think> and the opening "{", and no markdown code fences.`;

    await queryRunner.query(`
      UPDATE vl_prompt_templates
      SET template    = $1,
          description = $2
      WHERE kind = 'evaluation_system';
    `, [
      updatedTemplate,
      'System prompt for end-of-session CEFR scoring. The model returns one JSON object with scores, specific_feedback, strengths, suggested_practice, and session_feedback (the warm paragraph shown to the learner). The /think directive and transcript are added automatically — do not include them here.',
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

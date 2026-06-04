import { MigrationInterface, QueryRunner } from 'typeorm';

const DEFAULT_EVALUATION_SYSTEM = `You are an English examiner assessing the CEFR level of a learner from a short conversation transcript.
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
  "suggested_practice": "..."
}

Score definitions:
- fluency: pacing, hesitation, naturalness of phrasing
- accuracy: grammar correctness, tense, articles, agreement
- vocabulary: range, appropriateness, collocation
- interaction: turn-taking, follow-up questions, engagement relative to learner role
- topic_adherence: genuine engagement with the assigned topic vs steering to easier ground (avoidance scores LOW)

Output no prose before <think>, no prose between </think> and the opening "{", and no markdown code fences.`;

export class EvaluationPromptTemplate1782500000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Remove the unused grammar prompt template
    await queryRunner.query(`
      DELETE FROM vl_prompt_templates WHERE kind = 'grammar';
    `);

    // Insert the editable evaluation system prompt
    await queryRunner.query(
      `
      INSERT INTO vl_prompt_templates (kind, label, description, template, is_active)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (kind) DO UPDATE
        SET label       = EXCLUDED.label,
            description = EXCLUDED.description,
            template    = EXCLUDED.template,
            is_active   = EXCLUDED.is_active;
      `,
      [
        'evaluation_system',
        'CEFR Evaluation System Prompt',
        'System prompt sent to the AI at end of session for CEFR scoring. The /think directive and user transcript are added automatically — do not include them here.',
        DEFAULT_EVALUATION_SYSTEM,
        true,
      ],
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DELETE FROM vl_prompt_templates WHERE kind = 'evaluation_system';`);
  }
}

import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds the five-dimension scoring rubric to the evaluation_system template
 * so admins editing it in the panel see the canonical scoring criteria.
 */
export class EvalScoringRubric1782800000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    const updatedTemplate =
`You are an English examiner assessing the CEFR level of {country_adjective} {learner_description} from a short conversation transcript.
Given the transcript and a target CEFR level, produce a <think>...</think> block in which you reason carefully about the learner's USER turns (citing turn indices and short quotations), followed immediately by a single JSON object conforming to the EvaluationOutput schema (overall_cefr_estimate, scores {fluency, accuracy, vocabulary, interaction, topic_adherence} in [1,5], specific_feedback, strengths, suggested_practice).

Score these five dimensions on a 1-5 scale (5 = best at this CEFR level):
- fluency         : pacing, hesitation, naturalness of phrasing
- accuracy        : grammar correctness, tense, articles, agreement
- vocabulary      : range, appropriateness, collocation
- interaction     : turn-taking, follow-up questions, engagement; judge against what is appropriate for the LEARNER role
- topic_adherence : did the learner actually engage with the assigned topic and subtopics, or steer to easier ground? Use the LEARNER and TUTOR roles to judge whether a pivot is a natural extension within role (high) or true avoidance (low). AVOIDANCE scores low.

When you suggest practice activities, anchor them in {country_adjective} contexts the learner will recognize. Do not recommend {avoid_cultures_phrase}-context exercises. Output no prose before <think>, no prose between </think> and the opening "{", and no markdown code fences.`;

    await queryRunner.query(`
      UPDATE vl_prompt_templates
      SET template = $1
      WHERE kind = 'evaluation_system';
    `, [updatedTemplate]);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const previous =
`You are an English examiner assessing the CEFR level of {country_adjective} {learner_description} from a short conversation transcript.
Given the transcript and a target CEFR level, produce a <think>...</think> block in which you reason carefully about the learner's USER turns (citing turn indices and short quotations), followed immediately by a single JSON object conforming to the EvaluationOutput schema (overall_cefr_estimate, scores {fluency, accuracy, vocabulary, interaction, topic_adherence} in [1,5], specific_feedback, strengths, suggested_practice).

When you suggest practice activities, anchor them in {country_adjective} contexts the learner will recognize. Do not recommend {avoid_cultures_phrase}-context exercises. Output no prose before <think>, no prose between </think> and the opening "{", and no markdown code fences.`;

    await queryRunner.query(`
      UPDATE vl_prompt_templates
      SET template = $1
      WHERE kind = 'evaluation_system';
    `, [previous]);
  }
}

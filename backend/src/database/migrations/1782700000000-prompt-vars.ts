import { MigrationInterface, QueryRunner } from 'typeorm';

export class PromptVars1782700000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS vl_prompt_vars (
        key             varchar(100) PRIMARY KEY,
        label           varchar(200) NOT NULL,
        description     text,
        global_value    text,
        scenario_overridable boolean NOT NULL DEFAULT true,
        sort_order      integer NOT NULL DEFAULT 0
      );
    `);

    await queryRunner.query(`
      INSERT INTO vl_prompt_vars (key, label, description, global_value, scenario_overridable, sort_order) VALUES
        ('country',               'Country',             'Country name for cultural grounding (e.g. China)',                                      'China',              true, 10),
        ('country_adjective',     'Country adjective',   'Adjective form of the country (e.g. Chinese)',                                          'Chinese',            true, 20),
        ('learner_description',   'Learner description', 'Description of the learner audience used in the evaluation prompt (e.g. adult learners of English)', 'adult learners of English', true, 30),
        ('avoid_cultures_phrase', 'Avoid cultures',      'Cultures to avoid defaulting to in names, places, foods or brands (e.g. American and European)', 'American and European', true, 40),
        ('avoided_topics_sentence','Avoided topics',     'Full sentence describing topics the tutor should steer clear of',                       'Stay clear of politics, religion, alcohol dating, partisan history, violence harm, distress self harm, yankee culture, western culture, and law and national economy.', true, 50)
      ON CONFLICT (key) DO NOTHING;
    `);

    // Replace the narrow locale key column with a flexible JSONB overrides map
    await queryRunner.query(
      `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS var_overrides jsonb NOT NULL DEFAULT '{}';`,
    );
    await queryRunner.query(
      `ALTER TABLE vl_scenarios DROP COLUMN IF EXISTS locale;`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS locale varchar(50) NULL;`,
    );
    await queryRunner.query(
      `ALTER TABLE vl_scenarios DROP COLUMN IF EXISTS var_overrides;`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS vl_prompt_vars;`);
  }
}

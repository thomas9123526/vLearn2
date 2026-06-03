import { MigrationInterface, QueryRunner } from 'typeorm';

export class SessionCefrLevel1781500000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE vl_conversation_sessions
        ADD COLUMN IF NOT EXISTS cefr_level smallint NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE vl_conversation_sessions
        DROP COLUMN IF EXISTS cefr_level;
    `);
  }
}

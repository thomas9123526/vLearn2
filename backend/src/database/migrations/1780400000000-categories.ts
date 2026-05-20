import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Promote scenario categories from a hard-coded TS union into a real table.
 *
 *   1. CREATE vl_categories with seed rows for the four current slugs.
 *   2. ADD vl_scenarios.category_id (nullable for backfill).
 *   3. Backfill via JOIN on the existing `category` slug column.
 *   4. ALTER the FK column NOT NULL + add FK constraint.
 *
 * We deliberately KEEP `vl_scenarios.category` (the text slug) as a
 * denormalized cache. The public scenarios endpoint and the Flutter app
 * read `category: <slug>` directly, so dropping it would force a coordinated
 * client release. The admin layer treats `category_id` as the source of
 * truth and refuses slug edits (see CategoryEntity comment), so the denorm
 * can never go stale.
 */
export class Categories1780400000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS vl_categories (
        id uuid NOT NULL DEFAULT gen_random_uuid(),
        slug character varying(50) NOT NULL,
        title jsonb NOT NULL,
        description jsonb,
        order_index smallint NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamp with time zone NOT NULL DEFAULT now(),
        CONSTRAINT pk_vl_categories PRIMARY KEY (id),
        CONSTRAINT uq_vl_categories_slug UNIQUE (slug)
      )
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_vl_categories_active_order ON vl_categories (is_active, order_index)`,
    );

    // Seed the four legacy categories. ON CONFLICT keeps the migration
    // idempotent when reused in fresh-database test setups.
    const seed: Array<{ slug: string; title: Record<string, string>; order: number }> = [
      { slug: 'travel',   title: { en: 'Travel',   ko: '여행',   zh: '旅行' }, order: 10 },
      { slug: 'business', title: { en: 'Business', ko: '비즈니스', zh: '商务' }, order: 20 },
      { slug: 'social',   title: { en: 'Social',   ko: '소셜',   zh: '社交' }, order: 30 },
      { slug: 'daily',    title: { en: 'Daily',    ko: '일상',   zh: '日常' }, order: 40 },
    ];
    for (const c of seed) {
      await queryRunner.query(
        `INSERT INTO vl_categories (slug, title, order_index)
         VALUES ($1, $2::jsonb, $3)
         ON CONFLICT (slug) DO NOTHING`,
        [c.slug, JSON.stringify(c.title), c.order],
      );
    }

    // Add the FK column (nullable for the backfill step).
    await queryRunner.query(
      `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS category_id uuid`,
    );
    await queryRunner.query(
      `UPDATE vl_scenarios s
         SET category_id = c.id
         FROM vl_categories c
        WHERE s.category_id IS NULL
          AND s.category = c.slug`,
    );
    // Any rows whose category text doesn't match a seed slug fall back to
    // 'social' — no scenario should ever exist without a category_id.
    await queryRunner.query(
      `UPDATE vl_scenarios
          SET category_id = (SELECT id FROM vl_categories WHERE slug = 'social')
        WHERE category_id IS NULL`,
    );

    await queryRunner.query(
      `ALTER TABLE vl_scenarios ALTER COLUMN category_id SET NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE vl_scenarios
         ADD CONSTRAINT fk_vl_scenarios_category
         FOREIGN KEY (category_id) REFERENCES vl_categories (id)
         ON DELETE RESTRICT`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_vl_scenarios_category_id ON vl_scenarios (category_id)`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE vl_scenarios DROP CONSTRAINT IF EXISTS fk_vl_scenarios_category`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS idx_vl_scenarios_category_id`,
    );
    await queryRunner.query(
      `ALTER TABLE vl_scenarios DROP COLUMN IF EXISTS category_id`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS vl_categories`);
  }
}

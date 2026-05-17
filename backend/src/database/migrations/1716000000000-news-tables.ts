import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * News feature tables — see todoList/0517_v2/03_news_feature.md §3.2.
 *
 * Two tables:
 *   - news_posts: i18n-aware content authored by sub-admins
 *   - news_read_status: per-(user, post) pair stamped when first opened;
 *                       absence of row = unread. Compound PK keeps the
 *                       table tight (no surrogate row id).
 */
export class NewsTables1716000000000 implements MigrationInterface {
  name = 'NewsTables1716000000000';

  public async up(q: QueryRunner): Promise<void> {
    await q.query(`
      CREATE TABLE "news_posts" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "slug" varchar(150) NOT NULL,
        "title" jsonb NOT NULL,
        "body" jsonb NOT NULL,
        "summary" jsonb NULL,
        "image_url" varchar(500) NULL,
        "image_storage_key" varchar(255) NULL,
        "author_id" uuid NULL,
        "status" varchar(20) NOT NULL DEFAULT 'draft',
        "pinned" boolean NOT NULL DEFAULT false,
        "published_at" timestamptz NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "uniq_news_slug" UNIQUE ("slug"),
        CONSTRAINT "fk_news_author" FOREIGN KEY ("author_id")
          REFERENCES "users"("id") ON DELETE SET NULL
      );
    `);
    await q.query(
      `CREATE INDEX "idx_news_posts_status_published" ON "news_posts" ("status", "published_at" DESC);`,
    );
    await q.query(
      `CREATE INDEX "idx_news_posts_pinned" ON "news_posts" ("pinned", "published_at" DESC) WHERE "status" = 'published';`,
    );

    await q.query(`
      CREATE TABLE "news_read_status" (
        "user_id" uuid NOT NULL,
        "news_post_id" uuid NOT NULL,
        "read_at" timestamptz NOT NULL DEFAULT now(),
        PRIMARY KEY ("user_id", "news_post_id"),
        CONSTRAINT "fk_news_read_user" FOREIGN KEY ("user_id")
          REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "fk_news_read_post" FOREIGN KEY ("news_post_id")
          REFERENCES "news_posts"("id") ON DELETE CASCADE
      );
    `);
    await q.query(
      `CREATE INDEX "idx_news_read_user" ON "news_read_status" ("user_id");`,
    );
  }

  public async down(q: QueryRunner): Promise<void> {
    await q.query(`DROP TABLE IF EXISTS "news_read_status";`);
    await q.query(`DROP TABLE IF EXISTS "news_posts";`);
  }
}

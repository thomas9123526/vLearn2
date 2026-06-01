import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserNetworkStats1781300000000 implements MigrationInterface {
  name = 'UserNetworkStats1781300000000';

  async up(qr: QueryRunner): Promise<void> {
    await qr.query(`
      CREATE TABLE IF NOT EXISTS vl_user_network_stats (
        user_id          uuid        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        platform         varchar(20) NOT NULL,
        bytes_uploaded   bigint      NOT NULL DEFAULT 0,
        bytes_downloaded bigint      NOT NULL DEFAULT 0,
        updated_at       timestamptz NOT NULL DEFAULT now(),
        PRIMARY KEY (user_id, platform)
      )
    `);
    await qr.query(
      `CREATE INDEX IF NOT EXISTS idx_vl_net_stats_user ON vl_user_network_stats(user_id)`,
    );
  }

  async down(qr: QueryRunner): Promise<void> {
    await qr.query(`DROP TABLE IF EXISTS vl_user_network_stats`);
  }
}

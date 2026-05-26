import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Seeds the three license configuration keys into vl_app_config so the
 * admin panel and the Flutter app can read/write them through the
 * existing app-config controllers. No new table — the generic kv store
 * is enough for the enable flag, mode, and the Leaf CA public PEM.
 *
 * Note `license.enabled` is marked visible to the app — the Flutter
 * Settings screen reads it to decide whether to render the License
 * item. The PEM is server-side only.
 */
export class LicenseConfig1780700000000 implements MigrationInterface {
  public async up(qr: QueryRunner): Promise<void> {
    await qr.query(`
      INSERT INTO vl_app_config
        (key, value, value_type, category, description, default_value, is_visible_to_app)
      VALUES
        ('license.enabled', 'false'::jsonb, 'boolean', 'system',
         'When true, the app shows the License item in Settings and gates premium features behind a valid license.',
         'false'::jsonb, true),
        ('license.mode',    '"permanent"'::jsonb, 'string', 'system',
         'Either "period" (license expires) or "permanent" (effectively never expires).',
         '"permanent"'::jsonb, true),
        ('license.public_pem', '""'::jsonb, 'string', 'system',
         'Leaf CA public PEM used to verify license certs. Server-side only.',
         '""'::jsonb, false)
      ON CONFLICT (key) DO NOTHING
    `);
  }

  public async down(qr: QueryRunner): Promise<void> {
    await qr.query(
      `DELETE FROM vl_app_config WHERE key IN ('license.enabled','license.mode','license.public_pem')`,
    );
  }
}

import {
  Column,
  Entity,
  Index,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
} from 'typeorm';
import type { UserRole, UserStatus } from './user.entity';
import { UserEntity } from './user.entity';
import { encryptedFieldTransformer } from '../../common/field-encryption';

@Entity({ name: 'vl_user_info' })
@Index(['xp_total'])
@Index(['streak_days'])
export class UserInfoEntity {
  @PrimaryColumn({ type: 'uuid' })
  user_id!: string;

  @OneToOne(() => UserEntity, (u) => u.info, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 512, transformer: encryptedFieldTransformer })
  email!: string;

  @Column({ type: 'varchar', length: 10, default: '🐣' })
  avatar_emoji!: string;

  /**
   * On-disk relative path of the uploaded photo (e.g.
   * `avatars/<user_id>.jpg`). Nullable when the user never uploaded.
   * The avatar_emoji fallback above is what the UI renders in that case.
   */
  @Column({ type: 'varchar', length: 255, nullable: true })
  avatar_storage_key!: string | null;

  /// Public URL `/uploads/avatars/<file>` — mirrored from
  /// avatar_storage_key on upload so clients don't have to know about
  /// UPLOADS_DIR. Nullable; same fallback as above.
  @Column({ type: 'varchar', length: 500, nullable: true })
  avatar_url!: string | null;

  @Column({ type: 'varchar', length: 10, default: 'en' })
  native_language!: string;

  @Column({ type: 'varchar', length: 10, default: 'en' })
  ui_language!: string;

  @Column({ type: 'smallint', default: 1 })
  current_level!: number;

  @Column({ type: 'int', default: 0 })
  xp_total!: number;

  @Column({ type: 'smallint', default: 0 })
  streak_days!: number;

  @Column({ type: 'date', nullable: true })
  last_active_date!: Date | null;

  @Column({ type: 'uuid', nullable: true })
  active_persona_id!: string | null;

  @Column({ type: 'varchar', length: 20, default: 'apricot' })
  active_theme!: string;

  @Column({ type: 'boolean', default: false })
  onboarding_done!: boolean;

  @Column({ type: 'varchar', length: 20, default: 'user' })
  role!: UserRole;

  @Column({ type: 'varchar', length: 20, default: 'active' })
  status!: UserStatus;

  @Column({ type: 'timestamptz', nullable: true })
  suspended_until!: Date | null;

  @Column({ type: 'text', nullable: true, transformer: encryptedFieldTransformer })
  suspended_reason!: string | null;

  @Column({ type: 'boolean', default: true })
  leaderboard_opt_in!: boolean;

  // ─── License (moved from users table) ──────────────────────────────────────
  // Physical columns on users.license_* are kept for cross-system compatibility
  // but this app reads/writes here exclusively.

  @Column({ type: 'timestamptz', nullable: true })
  license_valid_until!: Date | null;

  @Column({ type: 'text', nullable: true, transformer: encryptedFieldTransformer })
  license_machine_id!: string | null;

  @Column({ type: 'text', nullable: true, transformer: encryptedFieldTransformer })
  license_serial!: string | null;

  /// Platform tag reported by the client at /license/verify time.
  /// Values mirror Flutter's defaultTargetPlatform: 'android', 'windows',
  /// 'ios', 'macos', 'linux', 'fuchsia', 'web'.
  @Column({ type: 'text', nullable: true })
  license_platform!: string | null;
}

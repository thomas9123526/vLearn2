import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type UserRole = 'user' | 'admin' | 'superadmin';
export type UserStatus = 'active' | 'suspended' | 'deleted';

@Entity({ name: 'users' })
@Index(['xp_total'])
@Index(['streak_days'])
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 255 })
  email!: string;

  @Column({ type: 'varchar', length: 255, select: false })
  password_hash!: string;

  @Column({ type: 'varchar', length: 100 })
  display_name!: string;

  @Column({ type: 'varchar', length: 10, default: '🐣' })
  avatar_emoji!: string;

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

  // Status & suspension (see 13 §13.4.4)
  @Column({ type: 'varchar', length: 20, default: 'active' })
  status!: UserStatus;

  @Column({ type: 'timestamptz', nullable: true })
  suspended_until!: Date | null;

  @Column({ type: 'text', nullable: true })
  suspended_reason!: string | null;

  @Column({ type: 'boolean', default: true })
  leaderboard_opt_in!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}

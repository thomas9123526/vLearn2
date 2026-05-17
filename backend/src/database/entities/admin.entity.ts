import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type AdminRole = 'admin' | 'superadmin';
export type AdminStatus = 'active' | 'suspended' | 'deleted';

/**
 * Backend-control accounts (admins + superadmins). Lives in its own table so
 * the application-side `users` table can stay focused on learners — different
 * sign-in flows, different refresh tokens, different sessions.
 *
 * IDs (UUIDs) preserved during the migration from `users.role IN (admin,
 * superadmin)` so existing `admin_permissions` / `admin_audit_log` rows still
 * line up.
 */
@Entity({ name: 'admins' })
export class AdminEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 255 })
  email!: string;

  @Column({ type: 'varchar', length: 255, select: false })
  password_hash!: string;

  @Column({ type: 'varchar', length: 100 })
  display_name!: string;

  @Column({ type: 'varchar', length: 20, default: 'admin' })
  role!: AdminRole;

  @Column({ type: 'varchar', length: 20, default: 'active' })
  status!: AdminStatus;

  @Column({ type: 'timestamptz', nullable: true })
  last_login_at!: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}

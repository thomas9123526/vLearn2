import {
  Column,
  CreateDateColumn,
  Entity,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserInfoEntity } from './user-info.entity';

export type UserRole = 'user' | 'admin' | 'superadmin';
export type UserStatus = 'active' | 'suspended' | 'deleted';

@Entity({ name: 'users' })
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 255, select: false })
  password_hash!: string;

  @Column({ type: 'varchar', length: 100 })
  name!: string;

  @Column({ type: 'varchar', length: 10, nullable: true, unique: true })
  cid!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true, unique: true })
  cid_username!: string | null;

  /// `'male' | 'female' | 'nonbinary' | 'unspecified'`. Surfaced in the
  /// Settings profile-edit dialog.
  @Column({ type: 'varchar', length: 20, default: 'unspecified' })
  gender!: string;

  @OneToOne(() => UserInfoEntity, (i) => i.user, { eager: true, cascade: ['insert', 'update'] })
  info!: UserInfoEntity;

  @Column({ type: 'timestamptz', nullable: true })
  license_valid_until!: Date | null;

  @Column({ type: 'text', nullable: true })
  license_machine_id!: string | null;

  @Column({ type: 'text', nullable: true })
  license_serial!: string | null;

  /// Platform tag reported by the client at /license/verify time.
  /// Values are the canonical Flutter ones: 'android', 'windows',
  /// 'ios', 'macos', 'linux', 'fuchsia', 'web'. Trust-on-write —
  /// for the admin Users list, not for security decisions.
  @Column({ type: 'text', nullable: true })
  license_platform!: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}

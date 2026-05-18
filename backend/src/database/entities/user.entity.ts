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

  @Column({ type: 'varchar', length: 10, nullable: true })
  cid!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  cid_username!: string | null;

  /// `'male' | 'female' | 'nonbinary' | 'unspecified'`. Surfaced in the
  /// Settings profile-edit dialog.
  @Column({ type: 'varchar', length: 20, default: 'unspecified' })
  gender!: string;

  @OneToOne(() => UserInfoEntity, (i) => i.user, { eager: true, cascade: ['insert', 'update'] })
  info!: UserInfoEntity;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}

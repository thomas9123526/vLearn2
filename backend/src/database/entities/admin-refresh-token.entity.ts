import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

/**
 * Admin-side refresh tokens. Separate from `refresh_tokens` (users) so admin
 * sessions can be revoked independently of user sessions.
 */
@Entity({ name: 'vl_admin_refresh_tokens' })
@Index(['admin_id'])
export class AdminRefreshTokenEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  admin_id!: string;

  @Column({ type: 'varchar', length: 255 })
  token_hash!: string;

  @Column({ type: 'timestamptz' })
  expires_at!: Date;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}

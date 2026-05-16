import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity({ name: 'admin_audit_log' })
@Index(['user_id', 'created_at'])
@Index(['target_type', 'target_id', 'created_at'])
@Index(['action', 'created_at'])
export class AdminAuditLogEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', nullable: true })
  user_id!: string | null;

  @Column({ type: 'varchar', length: 50 })
  action!: string;

  @Column({ type: 'varchar', length: 20 })
  target_type!: string;

  @Column({ type: 'varchar', length: 100 })
  target_id!: string;

  @Column({ type: 'jsonb', nullable: true })
  old_value!: unknown;

  @Column({ type: 'jsonb', nullable: true })
  new_value!: unknown;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}

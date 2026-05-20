import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

export type GuardSeverity = 'block' | 'warn';
export type GuardSource = 'client' | 'server';

@Entity({ name: 'vl_guard_violations' })
@Index(['user_id', 'created_at'])
@Index(['severity', 'created_at'])
export class GuardViolationEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  user_id!: string;

  @Column({ type: 'uuid', nullable: true })
  session_id!: string | null;

  @Column({ type: 'text' })
  attempted_content!: string;

  @Column({ type: 'text', array: true, default: () => 'ARRAY[]::text[]' })
  matched_terms!: string[];

  @Column({ type: 'varchar', length: 10 })
  severity!: GuardSeverity;

  @Column({ type: 'varchar', length: 10 })
  language!: string;

  @Column({ type: 'varchar', length: 10 })
  source!: GuardSource;

  @Column({ type: 'boolean', default: false })
  user_acknowledged_warn!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}

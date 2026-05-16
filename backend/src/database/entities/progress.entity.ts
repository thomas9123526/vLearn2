import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
  Unique,
} from 'typeorm';

@Entity({ name: 'skill_snapshots' })
@Unique(['user_id', 'snapshot_date'])
@Index(['user_id', 'snapshot_date'])
export class SkillSnapshotEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  user_id!: string;

  @Column({ type: 'date' })
  snapshot_date!: Date;

  @Column({ type: 'smallint', nullable: true })
  pronunciation!: number | null;

  @Column({ type: 'smallint', nullable: true })
  fluency!: number | null;

  @Column({ type: 'smallint', default: 0 })
  vocabulary!: number;

  @Column({ type: 'smallint', default: 0 })
  grammar!: number;

  @Column({ type: 'smallint', nullable: true })
  listening!: number | null;

  @Column({ type: 'smallint', default: 0 })
  sessions_in_window!: number;

  @Column({ type: 'smallint', default: 50 })
  confidence!: number;
}

@Entity({ name: 'user_progress' })
export class UserProgressEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', unique: true })
  user_id!: string;

  @Column({ type: 'int', default: 0 })
  sessions_total!: number;

  @Column({ type: 'smallint', default: 0 })
  sessions_this_week!: number;

  @Column({ type: 'int', default: 0 })
  minutes_spoken_total!: number;

  @Column({ type: 'smallint', default: 0 })
  minutes_spoken_this_week!: number;

  @Column({ type: 'int', default: 0 })
  words_spoken_total!: number;

  @Column({ type: 'int', default: 0 })
  scenarios_completed!: number;

  @Column({ type: 'smallint', default: 0 })
  current_streak!: number;

  @Column({ type: 'smallint', default: 0 })
  longest_streak!: number;

  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" })
  level_history!: Array<{ level: number; date: string }>;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}

@Entity({ name: 'user_scenario_completions' })
@Index(['user_id'])
export class UserScenarioCompletionEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  user_id!: string;

  @Column({ type: 'uuid' })
  scenario_id!: string;

  @Column({ type: 'smallint', nullable: true })
  best_score!: number | null;

  @Column({ type: 'smallint', default: 1 })
  completion_count!: number;

  @CreateDateColumn({ type: 'timestamptz' })
  first_completed_at!: Date;

  @Column({ type: 'timestamptz', nullable: true })
  last_completed_at!: Date | null;
}

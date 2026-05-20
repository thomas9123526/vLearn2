import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

export type ConversationMode = 'chat' | 'face';
export type SessionStatus = 'active' | 'completed' | 'abandoned';
export type MessageRole = 'user' | 'assistant';

@Entity({ name: 'vl_conversation_sessions' })
@Index(['user_id'])
@Index(['started_at'])
export class ConversationSessionEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  user_id!: string;

  @Column({ type: 'uuid', nullable: true })
  scenario_id!: string | null;

  @Column({ type: 'uuid' })
  persona_id!: string;

  @Column({ type: 'varchar', length: 20 })
  mode!: ConversationMode;

  @Column({ type: 'varchar', length: 20, default: 'active' })
  status!: SessionStatus;

  @CreateDateColumn({ type: 'timestamptz' })
  started_at!: Date;

  @Column({ type: 'timestamptz', nullable: true })
  ended_at!: Date | null;

  @Column({ type: 'int', nullable: true })
  duration_seconds!: number | null;

  @Column({ type: 'smallint', default: 0 })
  turn_count!: number;

  @Column({ type: 'int', default: 0 })
  word_count!: number;

  @Column({ type: 'smallint', default: 0 })
  xp_earned!: number;
}

@Entity({ name: 'vl_conversation_messages' })
@Index(['session_id'])
export class ConversationMessageEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  session_id!: string;

  @Column({ type: 'varchar', length: 10 })
  role!: MessageRole;

  @Column({ type: 'text' })
  content!: string;

  @Column({ type: 'int', default: 0 })
  sequence!: number;

  @Column({ type: 'varchar', length: 500, nullable: true })
  audio_url!: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}

@Entity({ name: 'vl_session_scores' })
export class SessionScoreEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', unique: true })
  session_id!: string;

  @Column({ type: 'smallint', nullable: true })
  overall_score!: number | null;

  @Column({ type: 'smallint', nullable: true })
  pronunciation_score!: number | null;

  @Column({ type: 'smallint', nullable: true })
  fluency_score!: number | null;

  @Column({ type: 'smallint', nullable: true })
  vocabulary_score!: number | null;

  @Column({ type: 'smallint', nullable: true })
  grammar_score!: number | null;

  @Column({ type: 'smallint', nullable: true })
  engagement_score!: number | null;

  @Column({ type: 'smallint', nullable: true })
  listening_score!: number | null;

  @Column({ type: 'jsonb', nullable: true })
  pronunciation_metrics!: Record<string, unknown> | null;

  @Column({ type: 'jsonb', nullable: true })
  fluency_metrics!: Record<string, unknown> | null;

  @Column({ type: 'jsonb', nullable: true })
  vocabulary_metrics!: Record<string, unknown> | null;

  @Column({ type: 'jsonb', nullable: true })
  grammar_metrics!: Record<string, unknown> | null;

  @Column({ type: 'jsonb', nullable: true })
  listening_metrics!: Record<string, unknown> | null;

  @Column({ type: 'text', array: true, default: () => 'ARRAY[]::text[]' })
  strengths!: string[];

  @Column({ type: 'text', array: true, default: () => 'ARRAY[]::text[]' })
  improvements!: string[];

  @Column({ type: 'text', nullable: true })
  ai_feedback!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  evaluator_versions!: Record<string, string> | null;

  @CreateDateColumn({ type: 'timestamptz' })
  computed_at!: Date;
}

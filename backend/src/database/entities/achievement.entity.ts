import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryColumn,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { I18nText } from './scenario.entity';

@Entity({ name: 'achievements' })
export class AchievementEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  key!: string;

  @Column({ type: 'jsonb' })
  title!: I18nText;

  @Column({ type: 'jsonb' })
  description!: I18nText;

  @Column({ type: 'varchar', length: 10 })
  icon!: string;

  @Column({ type: 'smallint', default: 0 })
  xp_reward!: number;

  @Column({ type: 'varchar', length: 50 })
  condition_type!: string;

  @Column({ type: 'int' })
  condition_value!: number;
}

@Entity({ name: 'user_achievements' })
export class UserAchievementEntity {
  @PrimaryColumn({ type: 'uuid' })
  user_id!: string;

  @PrimaryColumn({ type: 'uuid' })
  achievement_id!: string;

  @CreateDateColumn({ type: 'timestamptz' })
  earned_at!: Date;
}

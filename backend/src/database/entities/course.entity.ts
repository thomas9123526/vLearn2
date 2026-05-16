import {
  Column,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { I18nText } from './scenario.entity';

export type CourseStatus = 'draft' | 'published' | 'archived';

@Entity({ name: 'courses' })
@Index(['status'])
export class CourseEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 100, unique: true })
  slug!: string;

  @Column({ type: 'jsonb' })
  title!: I18nText;

  @Column({ type: 'jsonb' })
  description!: I18nText;

  @Column({ type: 'varchar', length: 20 })
  level_range!: string; // e.g. 'A1-A2'

  @Column({ type: 'smallint', default: 0 })
  total_xp!: number;

  @Column({ type: 'smallint', default: 0 })
  order_index!: number;

  @Column({ type: 'varchar', length: 500, nullable: true })
  image_url!: string | null;

  @Column({ type: 'varchar', length: 20, default: 'published' })
  status!: CourseStatus;

  @Column({ type: 'timestamptz', nullable: true })
  published_at!: Date | null;
}

@Entity({ name: 'course_scenarios' })
@Index(['course_id', 'order_index'])
export class CourseScenarioEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  course_id!: string;

  @Column({ type: 'uuid' })
  scenario_id!: string;

  @Column({ type: 'smallint' })
  order_index!: number;
}

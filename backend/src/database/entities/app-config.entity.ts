import {
  Column,
  Entity,
  Index,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';

export type AppConfigCategory =
  | 'home'
  | 'evaluation'
  | 'progress'
  | 'conversation'
  | 'scenarios'
  | 'settings'
  | 'system';

export type AppConfigValueType =
  | 'boolean'
  | 'string'
  | 'number'
  | 'object'
  | 'array';

@Entity({ name: 'vl_app_config' })
@Index(['category'])
export class AppConfigEntity {
  @PrimaryColumn({ type: 'varchar', length: 100 })
  key!: string;

  @Column({ type: 'jsonb' })
  value!: unknown;

  @Column({ type: 'varchar', length: 20 })
  value_type!: AppConfigValueType;

  @Column({ type: 'varchar', length: 50 })
  category!: AppConfigCategory;

  @Column({ type: 'text' })
  description!: string;

  @Column({ type: 'jsonb' })
  default_value!: unknown;

  @Column({ type: 'boolean', default: true })
  is_visible_to_app!: boolean;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;

  @Column({ type: 'uuid', nullable: true })
  updated_by!: string | null;
}

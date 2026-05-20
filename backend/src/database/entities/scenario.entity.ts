import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

export type ScenarioStatus = 'draft' | 'published' | 'archived';
/**
 * @deprecated Categories are now stored in vl_categories. The slug column
 * (`vl_scenarios.category`) holds a denormalized slug for backwards-
 * compatibility with API clients that read `category: <slug>`. Any string
 * referencing an active row in vl_categories is valid.
 */
export type ScenarioCategory = string;

export interface I18nText {
  en: string;
  ko?: string;
  zh?: string;
}

export interface ScenarioObjective {
  en: string;
  ko?: string;
  zh?: string;
}

export interface KeyPhrase {
  phrase: string;
  translation_ko?: string;
  translation_zh?: string;
}

@Entity({ name: 'vl_scenarios' })
@Index(['status'])
@Index(['category'])
@Index(['difficulty'])
@Index(['category_id'])
export class ScenarioEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 100, unique: true })
  slug!: string;

  /**
   * Denormalized category slug. Source of truth is `category_id` →
   * `vl_categories(id)`; this column is kept in sync by the admin
   * controllers so existing API clients can read `category` as a string
   * without an extra join. Never edit slugs directly — see [CategoryEntity].
   */
  @Column({ type: 'varchar', length: 50 })
  category!: ScenarioCategory;

  @Column({ type: 'uuid' })
  category_id!: string;

  @Column({ type: 'smallint' })
  difficulty!: number;

  @Column({ type: 'jsonb' })
  title!: I18nText;

  @Column({ type: 'jsonb' })
  description!: I18nText;

  @Column({ type: 'jsonb' })
  scene_description!: I18nText;

  @Column({ type: 'jsonb' })
  user_role!: I18nText;

  @Column({ type: 'jsonb' })
  tutor_role!: I18nText;

  @Column({ type: 'jsonb' })
  objectives!: ScenarioObjective[];

  @Column({ type: 'jsonb' })
  key_phrases!: KeyPhrase[];

  @Column({ type: 'smallint', default: 5 })
  estimated_minutes!: number;

  @Column({ type: 'smallint', default: 50 })
  xp_reward!: number;

  @Column({ type: 'smallint', default: 0 })
  order_index!: number;

  // Image / authoring (see 13 §13.2.1)
  @Column({ type: 'varchar', length: 500, nullable: true })
  image_url!: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  image_storage_key!: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  image_alt_text!: string | null;

  @Column({ type: 'uuid', nullable: true })
  author_id!: string | null;

  @Column({ type: 'varchar', length: 20, default: 'published' })
  status!: ScenarioStatus;

  @Column({ type: 'timestamptz', nullable: true })
  published_at!: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}

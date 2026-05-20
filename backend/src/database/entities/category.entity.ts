import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { I18nText } from './scenario.entity';

/**
 * Scenario categories.
 *
 * The set used to be a hard-coded TS union (`'travel' | 'business' | ...`).
 * That union lives on in `vl_scenarios.category` as a denormalized slug
 * cache so existing API clients (Flutter app reads `category` as a string)
 * keep working — but the source of truth for *which categories exist* and
 * for their localized titles is now this table.
 *
 * `slug` is immutable once a row is created so the denorm cache on
 * scenarios can never drift. `title` is i18n and freely editable.
 * Soft-delete via `is_active` — scenarios may still reference the row.
 */
@Entity({ name: 'vl_categories' })
@Index(['is_active', 'order_index'])
export class CategoryEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  slug!: string;

  @Column({ type: 'jsonb' })
  title!: I18nText;

  @Column({ type: 'jsonb', nullable: true })
  description!: I18nText | null;

  @Column({ type: 'smallint', default: 0 })
  order_index!: number;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}

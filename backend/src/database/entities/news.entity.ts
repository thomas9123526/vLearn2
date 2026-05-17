import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
  PrimaryColumn,
} from 'typeorm';
import type { I18nText } from './scenario.entity';

export type NewsStatus = 'draft' | 'published' | 'archived';

@Entity({ name: 'news_posts' })
@Index(['status', 'published_at'])
@Index(['pinned', 'published_at'])
export class NewsPostEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 150, unique: true })
  slug!: string;

  @Column({ type: 'jsonb' })
  title!: I18nText;

  @Column({ type: 'jsonb' })
  body!: I18nText;

  @Column({ type: 'jsonb', nullable: true })
  summary!: I18nText | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  image_url!: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  image_storage_key!: string | null;

  @Column({ type: 'uuid', nullable: true })
  author_id!: string | null;

  @Column({ type: 'varchar', length: 20, default: 'draft' })
  status!: NewsStatus;

  @Column({ type: 'boolean', default: false })
  pinned!: boolean;

  @Column({ type: 'timestamptz', nullable: true })
  published_at!: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}

@Entity({ name: 'news_read_status' })
@Index(['user_id'])
export class NewsReadStatusEntity {
  @PrimaryColumn({ type: 'uuid' })
  user_id!: string;

  @PrimaryColumn({ type: 'uuid' })
  news_post_id!: string;

  @CreateDateColumn({ type: 'timestamptz' })
  read_at!: Date;
}

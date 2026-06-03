import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

/** User-submitted feedback / bug report sent from the app. */
@Entity({ name: 'vl_user_reports' })
@Index(['user_id', 'created_at'])
@Index(['type', 'created_at'])
export class UserReportEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  user_id!: string;

  /** 'feedback' | 'bug' | 'other' */
  @Column({ type: 'varchar', length: 20, default: 'feedback' })
  type!: string;

  @Column({ type: 'text' })
  content!: string;

  /** Platform the report was submitted from ('android', 'windows', …). */
  @Column({ type: 'varchar', length: 20, nullable: true })
  platform!: string | null;

  /** App build version string (e.g. '1.2.3+45'). */
  @Column({ type: 'varchar', length: 50, nullable: true })
  app_version!: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}

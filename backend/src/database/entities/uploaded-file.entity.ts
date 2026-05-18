import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity({ name: 'vl_uploaded_files' })
@Index(['content_hash'])
@Index(['uploader_id', 'created_at'])
export class UploadedFileEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 255, unique: true })
  storage_key!: string;

  @Column({ type: 'varchar', length: 500 })
  original_filename!: string;

  @Column({ type: 'varchar', length: 50 })
  mime_type!: string;

  @Column({ type: 'int' })
  size_bytes!: number;

  @Column({ type: 'int', nullable: true })
  width!: number | null;

  @Column({ type: 'int', nullable: true })
  height!: number | null;

  @Column({ type: 'varchar', length: 64 })
  content_hash!: string;

  @Column({ type: 'int', default: 1 })
  reference_count!: number;

  @Column({ type: 'uuid', nullable: true })
  uploader_id!: string | null;

  @Column({ type: 'varchar', length: 50 })
  folder!: string;

  @Column({ type: 'varchar', length: 20 })
  storage_provider!: string;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}

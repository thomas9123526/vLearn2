import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'personas' })
export class PersonaEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  slug!: string;

  @Column({ type: 'varchar', length: 50 })
  name!: string;

  @Column({ type: 'varchar', length: 100 })
  accent!: string;

  @Column({ type: 'varchar', length: 100 })
  style!: string;

  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" })
  specialties!: string[];

  @Column({ type: 'varchar', length: 7 })
  gradient_from!: string;

  @Column({ type: 'varchar', length: 7 })
  gradient_to!: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  rive_asset!: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  image_url!: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  image_storage_key!: string | null;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;
}

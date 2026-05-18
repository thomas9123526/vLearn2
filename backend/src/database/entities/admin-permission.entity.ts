import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryColumn,
} from 'typeorm';

@Entity({ name: 'vl_admin_permissions' })
@Index(['user_id'])
@Index(['permission'])
export class AdminPermissionEntity {
  @PrimaryColumn({ type: 'uuid' })
  user_id!: string;

  @PrimaryColumn({ type: 'varchar', length: 60 })
  permission!: string;

  @Column({ type: 'uuid', nullable: true })
  granted_by!: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  granted_at!: Date;
}

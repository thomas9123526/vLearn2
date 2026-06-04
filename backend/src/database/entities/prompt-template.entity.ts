import {
  Column,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type PromptKind = 'tutor_system' | 'evaluation_system';

/**
 * Editable prompt templates used by the AI orchestration layer.
 * One row per `kind`; admins edit `template` from the admin panel.
 *
 * Variables use `{{group.field}}` syntax (e.g. `{{persona.name}}`). The
 * PromptBuilderService resolves them against a runtime context built from
 * the persona, scenario, and user. Unknown placeholders render as empty.
 */
@Entity({ name: 'vl_prompt_templates' })
export class PromptTemplateEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 50 })
  kind!: PromptKind;

  @Column({ type: 'varchar', length: 200 })
  label!: string;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  @Column({ type: 'text' })
  template!: string;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}

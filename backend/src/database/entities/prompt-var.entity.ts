import { Column, Entity, PrimaryColumn } from 'typeorm';

/**
 * Registry of template variable definitions and their global default values.
 * Per-scenario overrides are stored as `vl_scenarios.var_overrides` (JSONB).
 * Resolution order: scenario.var_overrides[key] → global_value → ''
 */
@Entity({ name: 'vl_prompt_vars' })
export class PromptVarEntity {
  @PrimaryColumn({ type: 'varchar', length: 100 })
  key!: string;

  @Column({ type: 'varchar', length: 200 })
  label!: string;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  @Column({ type: 'text', nullable: true })
  global_value!: string | null;

  @Column({ type: 'boolean', default: true })
  scenario_overridable!: boolean;

  @Column({ type: 'integer', default: 0 })
  sort_order!: number;
}

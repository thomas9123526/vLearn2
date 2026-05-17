import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

/**
 * "Tutor" persona presented to the user in conversation mode. Owned by
 * the admin panel (see AdminPersonasController) but read-only from the
 * mobile client (PersonasController).
 *
 * Mapping into runtime behavior:
 *   * `gender` drives the avatar's body/face Rive state machine so the
 *     animations match the persona's stated identity.
 *   * `voice_id` is the sherpa-onnx TTS voice id used when speaking lines
 *     for this persona. Matches an entry in `manifest.tts.voices`.
 *   * `rive_asset` is the .riv file dropped under assets/animations/ in
 *     the Flutter app (only the filename, not the full path).
 */
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

  /**
   * `'female' | 'male' | 'neutral'`. Drives the Rive avatar's idle/listening
   * animations and acts as a hint to the LLM about how to phrase replies.
   */
  @Column({ type: 'varchar', length: 10, default: 'neutral' })
  gender!: 'female' | 'male' | 'neutral';

  /**
   * Voice id used for TTS playback. Must match an entry under
   * `manifest.tts.voices` in the on-device sherpa-onnx bundle; otherwise
   * the app falls back to voice index 0.
   */
  @Column({ type: 'varchar', length: 100, nullable: true })
  voice_id!: string | null;
}

import { Column, Entity, PrimaryColumn } from 'typeorm';

/**
 * Accumulated network traffic per user per platform.
 * Rows are upserted by NetworkStatsService; one row per (user_id, platform).
 */
@Entity({ name: 'vl_user_network_stats' })
export class UserNetworkStatsEntity {
  @PrimaryColumn({ type: 'uuid', name: 'user_id' })
  user_id!: string;

  /** 'android' | 'windows' (or any other X-Platform value) */
  @PrimaryColumn({ type: 'varchar', length: 20 })
  platform!: string;

  /** Cumulative bytes received from this platform (request bodies). */
  @Column({ type: 'bigint', default: 0 })
  bytes_uploaded!: string; // TypeORM returns bigint columns as strings

  /** Cumulative bytes sent to this platform (response bodies). */
  @Column({ type: 'bigint', default: 0 })
  bytes_downloaded!: string;

  @Column({ type: 'timestamptz', default: () => 'now()' })
  updated_at!: Date;
}

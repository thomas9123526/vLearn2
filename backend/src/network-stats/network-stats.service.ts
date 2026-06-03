import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';

export interface PlatformNetworkStats {
  android_bytes_uploaded: number;
  android_bytes_downloaded: number;
  windows_bytes_uploaded: number;
  windows_bytes_downloaded: number;
}

@Injectable()
export class NetworkStatsService {
  constructor(private readonly ds: DataSource) {}

  /**
   * Atomically increments byte counters for (userId, platform).
   * Uses INSERT … ON CONFLICT DO UPDATE so the first call creates the row
   * and subsequent calls just add to the running totals.
   * Fire-and-forget safe — callers should catch errors themselves.
   */
  async addBytes(
    userId: string,
    platform: string,
    bytesUploaded: number,
    bytesDownloaded: number,
  ): Promise<void> {
    if (!userId || (bytesUploaded === 0 && bytesDownloaded === 0)) return;
    await this.ds.query(
      `INSERT INTO vl_user_network_stats
         (user_id, platform, bytes_uploaded, bytes_downloaded, updated_at)
       VALUES ($1, $2, $3, $4, now())
       ON CONFLICT (user_id, platform) DO UPDATE SET
         bytes_uploaded   = vl_user_network_stats.bytes_uploaded   + EXCLUDED.bytes_uploaded,
         bytes_downloaded = vl_user_network_stats.bytes_downloaded + EXCLUDED.bytes_downloaded,
         updated_at       = now()`,
      [userId, platform, bytesUploaded, bytesDownloaded],
    );
  }

  async getStatsForUser(userId: string): Promise<PlatformNetworkStats> {
    const rows: Array<{
      platform: string;
      bytes_uploaded: string;
      bytes_downloaded: string;
    }> = await this.ds.query(
      `SELECT platform, bytes_uploaded, bytes_downloaded
         FROM vl_user_network_stats
        WHERE user_id = $1 AND platform IN ('android', 'windows')`,
      [userId],
    );

    const out: PlatformNetworkStats = {
      android_bytes_uploaded: 0,
      android_bytes_downloaded: 0,
      windows_bytes_uploaded: 0,
      windows_bytes_downloaded: 0,
    };
    for (const r of rows) {
      if (r.platform === 'android') {
        out.android_bytes_uploaded = Number(r.bytes_uploaded);
        out.android_bytes_downloaded = Number(r.bytes_downloaded);
      } else if (r.platform === 'windows') {
        out.windows_bytes_uploaded = Number(r.bytes_uploaded);
        out.windows_bytes_downloaded = Number(r.bytes_downloaded);
      }
    }
    return out;
  }
}

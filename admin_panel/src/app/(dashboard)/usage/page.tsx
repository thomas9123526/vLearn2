'use client';

import { useQuery } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { api } from '@/lib/api';

interface PlatformSessionRow { platform: string; session_count: number; }
interface PlatformNetworkRow { platform: string; bytes_uploaded: number; bytes_downloaded: number; }
interface UsageResp {
  sessions_by_platform: PlatformSessionRow[];
  network_by_platform: PlatformNetworkRow[];
}

function fmtBytes(n: number | string): string {
  const v = Number(n);
  if (v === 0) return '0 B';
  if (v < 1_024) return `${v} B`;
  if (v < 1_048_576) return `${(v / 1_024).toFixed(1)} KB`;
  if (v < 1_073_741_824) return `${(v / 1_048_576).toFixed(2)} MB`;
  return `${(v / 1_073_741_824).toFixed(2)} GB`;
}

export default function UsagePage() {
  const { data, isLoading } = useQuery<UsageResp>({
    queryKey: ['admin-usage'],
    queryFn: () => api<UsageResp>('/admin/stats/usage'),
  });

  const totalSessions = (data?.sessions_by_platform ?? []).reduce((s, r) => s + r.session_count, 0);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">App Usage</h1>
      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}

      <div className="grid gap-4 md:grid-cols-2">
        {/* Sessions by platform */}
        <Card className="overflow-hidden">
          <div className="border-b border-border px-4 py-3">
            <p className="text-sm font-medium">Sessions by platform</p>
            <p className="text-xs text-muted-foreground">Total: {totalSessions.toLocaleString()}</p>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-muted/50">
              <tr>
                <th className="px-4 py-2 text-left font-medium">Platform</th>
                <th className="px-4 py-2 text-right font-medium">Sessions</th>
                <th className="px-4 py-2 text-right font-medium">Share</th>
              </tr>
            </thead>
            <tbody>
              {(data?.sessions_by_platform ?? []).map((r) => (
                <tr key={r.platform} className="border-t border-border">
                  <td className="px-4 py-2 capitalize">{r.platform}</td>
                  <td className="px-4 py-2 text-right tabular-nums">{r.session_count.toLocaleString()}</td>
                  <td className="px-4 py-2 text-right tabular-nums text-muted-foreground">
                    {totalSessions > 0 ? `${((r.session_count / totalSessions) * 100).toFixed(1)}%` : '—'}
                  </td>
                </tr>
              ))}
              {(data?.sessions_by_platform ?? []).length === 0 && !isLoading && (
                <tr><td colSpan={3} className="px-4 py-4 text-center text-muted-foreground">No data yet.</td></tr>
              )}
            </tbody>
          </table>
        </Card>

        {/* Network bytes by platform */}
        <Card className="overflow-hidden">
          <div className="border-b border-border px-4 py-3">
            <p className="text-sm font-medium">Network traffic by platform</p>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-muted/50">
              <tr>
                <th className="px-4 py-2 text-left font-medium">Platform</th>
                <th className="px-4 py-2 text-right font-medium">Uploaded</th>
                <th className="px-4 py-2 text-right font-medium">Downloaded</th>
              </tr>
            </thead>
            <tbody>
              {(data?.network_by_platform ?? []).map((r) => (
                <tr key={r.platform} className="border-t border-border">
                  <td className="px-4 py-2 capitalize">{r.platform}</td>
                  <td className="px-4 py-2 text-right tabular-nums">{fmtBytes(r.bytes_uploaded)}</td>
                  <td className="px-4 py-2 text-right tabular-nums">{fmtBytes(r.bytes_downloaded)}</td>
                </tr>
              ))}
              {(data?.network_by_platform ?? []).length === 0 && !isLoading && (
                <tr><td colSpan={3} className="px-4 py-4 text-center text-muted-foreground">No data yet.</td></tr>
              )}
            </tbody>
          </table>
        </Card>
      </div>
    </div>
  );
}

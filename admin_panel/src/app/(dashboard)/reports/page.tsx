'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { api } from '@/lib/api';

interface ReportRow {
  id: string;
  user_id: string;
  type: string;
  content: string;
  platform: string | null;
  app_version: string | null;
  created_at: string;
}

interface ReportsResp { items: ReportRow[]; total: number; page: number; limit: number; }

const TYPE_COLORS: Record<string, string> = {
  feedback: 'bg-sky-100 text-sky-800',
  bug:      'bg-red-100 text-red-800',
  other:    'bg-zinc-100 text-zinc-700',
};

export default function ReportsPage() {
  const [type, setType] = useState('');
  const [expanded, setExpanded] = useState<string | null>(null);

  const { data, isLoading } = useQuery<ReportsResp>({
    queryKey: ['admin-reports', type],
    queryFn: () => {
      const p = new URLSearchParams();
      if (type) p.set('type', type);
      return api<ReportsResp>(`/admin/stats/reports?${p.toString()}`);
    },
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">User Reports</h1>
        <select
          className="h-9 rounded-md border border-border bg-background px-2 text-sm"
          value={type}
          onChange={(e) => setType(e.target.value)}
        >
          <option value="">All types</option>
          <option value="feedback">Feedback</option>
          <option value="bug">Bug</option>
          <option value="other">Other</option>
        </select>
      </div>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}

      <Card className="overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="px-4 py-2 text-left font-medium">Type</th>
              <th className="px-4 py-2 text-left font-medium">Message</th>
              <th className="px-4 py-2 text-left font-medium">Platform</th>
              <th className="px-4 py-2 text-left font-medium">Date</th>
            </tr>
          </thead>
          <tbody>
            {(data?.items ?? []).map((r) => (
              <>
                <tr
                  key={r.id}
                  className="border-b border-border last:border-0 cursor-pointer hover:bg-muted/30"
                  onClick={() => setExpanded(expanded === r.id ? null : r.id)}
                >
                  <td className="px-4 py-2">
                    <span className={`rounded px-2 py-0.5 text-xs font-medium capitalize ${TYPE_COLORS[r.type] ?? TYPE_COLORS.other}`}>
                      {r.type}
                    </span>
                  </td>
                  <td className="px-4 py-2 max-w-sm truncate text-muted-foreground">
                    {r.content}
                  </td>
                  <td className="px-4 py-2 capitalize">{r.platform ?? '—'}</td>
                  <td className="px-4 py-2 whitespace-nowrap">
                    {new Date(r.created_at).toLocaleDateString()}
                  </td>
                </tr>
                {expanded === r.id && (
                  <tr key={`${r.id}-expanded`} className="border-b border-border bg-muted/20">
                    <td colSpan={4} className="px-4 py-3">
                      <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Full message</p>
                      <p className="whitespace-pre-wrap text-sm">{r.content}</p>
                      <p className="mt-2 text-xs text-muted-foreground">
                        User: <span className="font-mono">{r.user_id}</span>
                        {r.app_version && <> · v{r.app_version}</>}
                        {' · '}{new Date(r.created_at).toLocaleString()}
                      </p>
                    </td>
                  </tr>
                )}
              </>
            ))}
            {(data?.items ?? []).length === 0 && !isLoading && (
              <tr>
                <td colSpan={4} className="px-4 py-6 text-center text-muted-foreground">No reports yet.</td>
              </tr>
            )}
          </tbody>
        </table>
        {data && data.total > data.limit && (
          <div className="border-t border-border px-4 py-2 text-xs text-muted-foreground">
            Showing {data.items.length} of {data.total} reports
          </div>
        )}
      </Card>
    </div>
  );
}

'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Trophy } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { api } from '@/lib/api';

type Metric = 'xp_total' | 'streak_days' | 'current_level';

interface Row {
  rank: number;
  id: string;
  email: string;
  display_name: string;
  avatar_emoji: string;
  ui_language: string;
  xp_total: number;
  current_level: number;
  streak_days: number;
  score: number;
}

export default function LeaderboardPage() {
  const [metric, setMetric] = useState<Metric>('xp_total');
  const [language, setLanguage] = useState<string>('');
  const [limit, setLimit] = useState<number>(50);

  const { data, isLoading } = useQuery<Row[]>({
    queryKey: ['admin-leaderboard', metric, language, limit],
    queryFn: () => {
      const p = new URLSearchParams({ metric, limit: limit.toString() });
      if (language) p.set('language', language);
      return api<Row[]>(`/admin/leaderboard?${p.toString()}`);
    },
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="flex items-center gap-2 text-2xl font-semibold">
          <Trophy className="h-6 w-6" /> Leaderboard
        </h1>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div>
          <label className="block text-xs text-muted-foreground">Metric</label>
          <select
            className="h-9 rounded-md border border-border bg-background px-2 text-sm"
            value={metric}
            onChange={(e) => setMetric(e.target.value as Metric)}
          >
            <option value="xp_total">XP total</option>
            <option value="streak_days">Streak days</option>
            <option value="current_level">Current level</option>
          </select>
        </div>
        <div>
          <label className="block text-xs text-muted-foreground">UI language</label>
          <select
            className="h-9 rounded-md border border-border bg-background px-2 text-sm"
            value={language}
            onChange={(e) => setLanguage(e.target.value)}
          >
            <option value="">All</option>
            <option value="en">English</option>
            <option value="ko">한국어</option>
            <option value="zh">中文</option>
          </select>
        </div>
        <div>
          <label className="block text-xs text-muted-foreground">Top N</label>
          <select
            className="h-9 rounded-md border border-border bg-background px-2 text-sm"
            value={limit}
            onChange={(e) => setLimit(parseInt(e.target.value, 10))}
          >
            {[10, 25, 50, 100, 200].map((n) => (
              <option key={n} value={n}>{n}</option>
            ))}
          </select>
        </div>
      </div>

      <Card className="overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="px-4 py-2 text-left font-medium">#</th>
              <th className="px-4 py-2 text-left font-medium">User</th>
              <th className="px-4 py-2 text-left font-medium">Language</th>
              <th className="px-4 py-2 text-right font-medium">XP</th>
              <th className="px-4 py-2 text-right font-medium">Level</th>
              <th className="px-4 py-2 text-right font-medium">Streak</th>
              <th className="px-4 py-2 text-right font-medium">Score</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr>
                <td colSpan={7} className="px-4 py-6 text-center text-muted-foreground">
                  Loading…
                </td>
              </tr>
            )}
            {(data ?? []).map((r) => (
              <tr key={r.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2 tabular-nums">{r.rank}</td>
                <td className="px-4 py-2">
                  <span className="mr-2">{r.avatar_emoji}</span>
                  {r.display_name}
                  <span className="ml-2 text-xs text-muted-foreground">{r.email}</span>
                </td>
                <td className="px-4 py-2 uppercase">{r.ui_language}</td>
                <td className="px-4 py-2 text-right tabular-nums">{r.xp_total.toLocaleString()}</td>
                <td className="px-4 py-2 text-right tabular-nums">{r.current_level}</td>
                <td className="px-4 py-2 text-right tabular-nums">{r.streak_days}</td>
                <td className="px-4 py-2 text-right font-semibold tabular-nums">{r.score.toLocaleString()}</td>
              </tr>
            ))}
            {!isLoading && (data ?? []).length === 0 && (
              <tr>
                <td colSpan={7} className="px-4 py-6 text-center text-muted-foreground">
                  No users yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

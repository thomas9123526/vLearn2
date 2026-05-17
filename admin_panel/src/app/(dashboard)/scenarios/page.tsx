'use client';

import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { api } from '@/lib/api';

interface ScenarioRow {
  id: string;
  slug: string;
  category: string;
  difficulty: number;
  title: { en: string; ko?: string; zh?: string };
  status: 'published' | 'draft' | 'archived';
  xp_reward: number;
  estimated_minutes: number;
}

export default function ScenariosPage() {
  // Reads the existing user-facing endpoint, which returns published only.
  // A dedicated admin endpoint that shows drafts + archives is a follow-up.
  const { data, isLoading, error } = useQuery<ScenarioRow[]>({
    queryKey: ['scenarios', 'list'],
    queryFn: () => api<ScenarioRow[]>('/scenarios'),
  });

  if (isLoading) return <p className="text-sm text-muted-foreground">Loading…</p>;
  if (error) {
    return (
      <p className="text-sm text-destructive">
        Could not load scenarios: {error instanceof Error ? error.message : 'unknown error'}
      </p>
    );
  }

  const rows = data ?? [];

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Scenarios</h2>
        <p className="text-sm text-muted-foreground">
          Read-only list of <strong>published</strong> scenarios from the
          user-facing endpoint. A dedicated <code>/admin/scenarios</code>{' '}
          endpoint (with drafts + create/edit/publish actions) is a follow-up.
        </p>
      </div>

      {rows.length === 0 ? (
        <p className="text-sm text-muted-foreground">No published scenarios yet.</p>
      ) : (
        <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
          {rows.map((s) => (
            <Card key={s.id}>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">{s.title.en}</CardTitle>
                <div className="text-xs text-muted-foreground">{s.slug}</div>
              </CardHeader>
              <CardContent className="space-y-1 text-xs">
                <div><span className="text-muted-foreground">Category:</span> {s.category}</div>
                <div><span className="text-muted-foreground">Difficulty:</span> {s.difficulty}</div>
                <div><span className="text-muted-foreground">XP:</span> {s.xp_reward}</div>
                <div><span className="text-muted-foreground">Est. time:</span> {s.estimated_minutes} min</div>
                <div><span className="text-muted-foreground">Status:</span> {s.status}</div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

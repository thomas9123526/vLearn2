'use client';

import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { api } from '@/lib/api';

interface AdminStats {
  users_total: number;
  users_active_30d: number;
  sessions_total: number;
  scenarios_published: number;
}

export default function DashboardPage() {
  const { data, isLoading, error } = useQuery<AdminStats>({
    queryKey: ['admin-stats'],
    queryFn: () => api<AdminStats>('/admin/stats'),
  });

  if (isLoading) return <p className="text-sm text-muted-foreground">Loading…</p>;
  if (error)
    return (
      <p className="text-sm text-destructive">
        Stats endpoint not available yet (see todoList/0516/13 §13.7 for status).
      </p>
    );

  return (
    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
      <StatCard label="Total users" value={data?.users_total ?? 0} />
      <StatCard label="Active (30d)" value={data?.users_active_30d ?? 0} />
      <StatCard label="Sessions" value={data?.sessions_total ?? 0} />
      <StatCard label="Scenarios" value={data?.scenarios_published ?? 0} />
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm text-muted-foreground">{label}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold tabular-nums">{value.toLocaleString()}</div>
      </CardContent>
    </Card>
  );
}

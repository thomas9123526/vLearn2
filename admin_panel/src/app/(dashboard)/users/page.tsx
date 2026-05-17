'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Ban, RotateCcw, Search } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

interface UserRow {
  id: string;
  email: string;
  display_name: string;
  status: 'active' | 'suspended' | 'deleted';
  suspended_until: string | null;
  suspended_reason: string | null;
  xp_total: number;
  current_level: number;
  streak_days: number;
  created_at: string;
}

interface UserListResp {
  items: UserRow[];
  total: number;
  page: number;
  limit: number;
}

export default function UsersPage() {
  const canSuspend = usePermission('users.suspend');
  const qc = useQueryClient();
  const [q, setQ] = useState('');
  const [status, setStatus] = useState<string>('');

  const { data, isLoading } = useQuery<UserListResp>({
    queryKey: ['admin-users', q, status],
    queryFn: () => {
      const params = new URLSearchParams();
      if (q) params.set('q', q);
      if (status) params.set('status', status);
      return api<UserListResp>(`/admin/users?${params.toString()}`);
    },
  });

  const suspend = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      api(`/admin/users/${id}/suspend`, { method: 'POST', body: { reason } }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  });
  const restore = useMutation({
    mutationFn: (id: string) => api(`/admin/users/${id}/restore`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  });

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">Users</h1>
      <div className="flex items-center gap-2">
        <div className="relative max-w-sm flex-1">
          <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search by email or name…"
            className="pl-8"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>
        <select
          className="h-9 rounded-md border border-border bg-background px-2 text-sm"
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="">All statuses</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="deleted">Deleted</option>
        </select>
      </div>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}

      <Card className="overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="px-4 py-2 text-left font-medium">Email</th>
              <th className="px-4 py-2 text-left font-medium">Name</th>
              <th className="px-4 py-2 text-left font-medium">Status</th>
              <th className="px-4 py-2 text-right font-medium">XP</th>
              <th className="px-4 py-2 text-right font-medium">Streak</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(data?.items ?? []).map((u) => (
              <tr key={u.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2">{u.email}</td>
                <td className="px-4 py-2">{u.display_name}</td>
                <td className="px-4 py-2">
                  <StatusPill status={u.status} />
                  {u.suspended_reason && (
                    <span className="ml-2 text-xs text-muted-foreground">{u.suspended_reason}</span>
                  )}
                </td>
                <td className="px-4 py-2 text-right tabular-nums">{u.xp_total}</td>
                <td className="px-4 py-2 text-right tabular-nums">{u.streak_days}</td>
                <td className="px-4 py-2 text-right">
                  {canSuspend && u.status === 'active' && (
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => {
                        const reason = prompt('Reason for suspension?') ?? '';
                        if (reason !== null) suspend.mutate({ id: u.id, reason });
                      }}
                    >
                      <Ban className="h-4 w-4" /> Block
                    </Button>
                  )}
                  {canSuspend && u.status === 'suspended' && (
                    <Button size="sm" variant="outline" onClick={() => restore.mutate(u.id)}>
                      <RotateCcw className="h-4 w-4" /> Restore
                    </Button>
                  )}
                </td>
              </tr>
            ))}
            {(data?.items ?? []).length === 0 && !isLoading && (
              <tr>
                <td colSpan={6} className="px-4 py-6 text-center text-muted-foreground">
                  No users.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

function StatusPill({ status }: { status: UserRow['status'] }) {
  const classes =
    status === 'active'
      ? 'bg-green-100 text-green-800'
      : status === 'suspended'
        ? 'bg-red-100 text-red-800'
        : 'bg-zinc-100 text-zinc-700';
  return (
    <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium ${classes}`}>
      {status}
    </span>
  );
}

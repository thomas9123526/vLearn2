'use client';

import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { api, ApiError } from '@/lib/api';

interface AdminRow {
  id: string;
  email: string;
  displayName: string;
  status: 'active' | 'suspended' | 'deleted';
  permissions: string[];
}

export default function AdminsPage() {
  const { data, isLoading, error } = useQuery<AdminRow[]>({
    queryKey: ['admins', 'list'],
    queryFn: () => api<AdminRow[]>('/admin/admins'),
  });

  if (isLoading) {
    return <p className="text-sm text-muted-foreground">Loading…</p>;
  }
  if (error) {
    const msg = error instanceof ApiError && error.status === 403
      ? 'You do not have the admins.view permission.'
      : `Could not load admins: ${error instanceof Error ? error.message : 'unknown error'}`;
    return <p className="text-sm text-destructive">{msg}</p>;
  }

  const rows = data ?? [];

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Sub-admins</h2>
        <p className="text-sm text-muted-foreground">
          Lists all accounts with <code>role = &apos;admin&apos;</code>. The
          superadmin manages this set; granular create/suspend/permission UI
          is on its way.
        </p>
      </div>

      {rows.length === 0 ? (
        <Card>
          <CardContent className="py-8 text-center text-sm text-muted-foreground">
            No sub-admins yet. Anyone who signs up at <code>/signup</code>{' '}
            after the first superadmin becomes a regular admin automatically.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
          {rows.map((a) => (
            <Card key={a.id}>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">{a.displayName}</CardTitle>
                <div className="text-xs text-muted-foreground">{a.email}</div>
              </CardHeader>
              <CardContent className="space-y-2 text-xs">
                <div className="flex items-center gap-2">
                  <span className="text-muted-foreground">Status:</span>
                  <span className={
                    a.status === 'active'
                      ? 'font-medium text-green-700 dark:text-green-400'
                      : 'font-medium text-amber-700 dark:text-amber-400'
                  }>{a.status}</span>
                </div>
                <div>
                  <div className="text-muted-foreground">Permissions:</div>
                  {a.permissions.length === 0 ? (
                    <div className="italic text-muted-foreground">(none granted)</div>
                  ) : (
                    <ul className="ml-3 list-disc">
                      {a.permissions.map((p) => (
                        <li key={p}><code>{p}</code></li>
                      ))}
                    </ul>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';
import { useCurrentUser } from '@/hooks/use-current-user';

interface ConfigEntry {
  key: string;
  value: unknown;
  value_type: 'boolean' | 'string' | 'number' | 'object' | 'array';
  category: string;
  description: string;
}

/**
 * Admin-panel-wide settings (different from the per-flag config grid).
 *
 * Today it surfaces the gzip toggle (`system.gzip_enabled`). Future tiles
 * land here for things like the AI provider switch, maintenance banner, etc.
 */
export default function SettingsPage() {
  const user = useCurrentUser();
  const canEdit = usePermission('config.edit');
  const qc = useQueryClient();

  const { data: gzip } = useQuery<ConfigEntry>({
    queryKey: ['admin-config', 'system.gzip_enabled'],
    queryFn: () => api<ConfigEntry>('/admin/config/system.gzip_enabled'),
  });

  const update = useMutation({
    mutationFn: ({ key, value }: { key: string; value: unknown }) =>
      api(`/admin/config/${key}`, { method: 'PATCH', body: { value } }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['admin-config', 'system.gzip_enabled'] }),
  });

  return (
    <div className="max-w-2xl space-y-4">
      <h1 className="text-2xl font-semibold">Settings</h1>

      <Card>
        <CardHeader>
          <CardTitle>Network — gzip</CardTitle>
          <CardDescription>
            When enabled, the backend compresses JSON responses larger than the
            threshold (default 100&nbsp;KB) before sending them to the app.
            Disable for local debugging or when proxying through a network that
            already compresses.
          </CardDescription>
        </CardHeader>
        <CardContent className="flex items-center justify-between">
          <div className="text-sm">
            Currently: <span className="font-medium">
              {gzip?.value === true ? 'enabled' : gzip?.value === false ? 'disabled' : '—'}
            </span>
          </div>
          <label className="inline-flex cursor-pointer items-center gap-2">
            <input
              type="checkbox"
              className="h-4 w-4"
              checked={Boolean(gzip?.value)}
              disabled={!canEdit || gzip == null}
              onChange={(e) =>
                update.mutate({ key: 'system.gzip_enabled', value: e.target.checked })
              }
            />
            <span className="text-sm">Enable gzip</span>
          </label>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Session</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-sm">
            Signed in as <span className="font-medium">{user?.email ?? '—'}</span> (
            {user?.role ?? '—'}).
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

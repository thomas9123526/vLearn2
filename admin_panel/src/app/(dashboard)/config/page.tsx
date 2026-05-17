'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

interface ConfigEntry {
  key: string;
  value: unknown;
  value_type: 'boolean' | 'string' | 'number' | 'object' | 'array';
  category: string;
  description: string;
  default_value: unknown;
  is_visible_to_app: boolean;
  updated_at: string;
}

export default function ConfigPage() {
  const canEdit = usePermission('config.edit');
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<ConfigEntry[]>({
    queryKey: ['admin-config'],
    queryFn: () => api<ConfigEntry[]>('/admin/config'),
  });

  const update = useMutation({
    mutationFn: ({ key, value }: { key: string; value: unknown }) =>
      api(`/admin/config/${key}`, { method: 'PATCH', body: { value } }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-config'] }),
  });

  if (isLoading) return <p className="text-sm text-muted-foreground">Loading…</p>;

  const byCategory: Record<string, ConfigEntry[]> = {};
  for (const e of data ?? []) {
    (byCategory[e.category] ??= []).push(e);
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Visibility flags</h1>
      {Object.entries(byCategory).map(([category, entries]) => (
        <Card key={category} className="overflow-hidden">
          <div className="border-b border-border bg-muted/50 px-4 py-2 text-sm font-medium capitalize">
            {category}
          </div>
          <div className="divide-y divide-border">
            {entries.map((e) => (
              <ConfigRow
                key={e.key}
                entry={e}
                canEdit={canEdit}
                onToggle={(v) => update.mutate({ key: e.key, value: v })}
              />
            ))}
          </div>
        </Card>
      ))}
    </div>
  );
}

function ConfigRow({
  entry,
  canEdit,
  onToggle,
}: {
  entry: ConfigEntry;
  canEdit: boolean;
  onToggle: (next: unknown) => void;
}) {
  return (
    <div className="flex items-center gap-3 px-4 py-3">
      <div className="flex-1">
        <div className="font-mono text-sm">{entry.key}</div>
        <div className="text-xs text-muted-foreground">{entry.description}</div>
      </div>
      <div className="w-24 text-right">
        {entry.value_type === 'boolean' ? (
          <input
            type="checkbox"
            checked={Boolean(entry.value)}
            disabled={!canEdit}
            onChange={(e) => onToggle(e.target.checked)}
            className="h-4 w-4"
          />
        ) : (
          <span className="font-mono text-xs">{JSON.stringify(entry.value)}</span>
        )}
      </div>
    </div>
  );
}

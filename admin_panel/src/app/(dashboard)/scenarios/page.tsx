'use client';

import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, CheckCircle2, Archive, Trash2, Edit2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

interface Scenario {
  id: string;
  slug: string;
  category: string;
  difficulty: number;
  status: 'draft' | 'published' | 'archived';
  title: Record<string, string>;
  image_url: string | null;
  background_image_url?: string | null;
  created_at: string;
}

export default function ScenariosPage() {
  const canEdit = usePermission('scenarios.edit');
  const canDelete = usePermission('scenarios.delete');
  const qc = useQueryClient();

  const { data, isLoading, error } = useQuery<Scenario[]>({
    queryKey: ['admin-scenarios'],
    queryFn: () => api<Scenario[]>('/admin/scenarios'),
  });

  const publish = useMutation({
    mutationFn: (id: string) => api(`/admin/scenarios/${id}/publish`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-scenarios'] }),
  });
  const archive = useMutation({
    mutationFn: (id: string) => api(`/admin/scenarios/${id}/archive`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-scenarios'] }),
  });
  const remove = useMutation({
    mutationFn: (id: string) => api(`/admin/scenarios/${id}`, { method: 'DELETE' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-scenarios'] }),
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Scenarios</h1>
        {canEdit && (
          <Link href="/scenarios/new">
            <Button>
              <Plus className="h-4 w-4" />
              New scenario
            </Button>
          </Link>
        )}
      </div>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
      {error && <p className="text-sm text-destructive">{(error as Error).message}</p>}

      <Card className="overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="px-4 py-2 text-left font-medium">Title</th>
              <th className="px-4 py-2 text-left font-medium">Category</th>
              <th className="px-4 py-2 text-left font-medium">Difficulty</th>
              <th className="px-4 py-2 text-left font-medium">Status</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(data ?? []).map((s) => (
              <tr key={s.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2">
                  {/* Scenario edit page is not built yet — render as plain text
                      instead of a link that 404s. Re-enable when the route lands. */}
                  <span>{s.title?.en ?? s.slug}</span>
                </td>
                <td className="px-4 py-2 capitalize">{s.category}</td>
                <td className="px-4 py-2">{'★'.repeat(s.difficulty)}</td>
                <td className="px-4 py-2 capitalize">{s.status}</td>
                <td className="px-4 py-2 text-right space-x-1">
                  {canEdit && s.status === 'draft' && (
                    <Button size="sm" variant="outline" onClick={() => publish.mutate(s.id)}>
                      <CheckCircle2 className="h-4 w-4" /> Publish
                    </Button>
                  )}
                  {canEdit && s.status === 'published' && (
                    <Button size="sm" variant="ghost" onClick={() => archive.mutate(s.id)}>
                      <Archive className="h-4 w-4" /> Archive
                    </Button>
                  )}
                  {canEdit && (
                    <Link href={`/scenarios/${s.id}`}>
                      <Button size="sm" variant="outline">
                        <Edit2 className="h-4 w-4" /> Edit
                      </Button>
                    </Link>
                  )}
                  {canDelete && (
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => {
                        if (confirm(`Delete "${s.title?.en ?? s.slug}"?`)) {
                          remove.mutate(s.id);
                        }
                      }}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  )}
                </td>
              </tr>
            ))}
            {(data ?? []).length === 0 && !isLoading && (
              <tr>
                <td colSpan={5} className="px-4 py-6 text-center text-muted-foreground">
                  No scenarios yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

'use client';

import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Pencil, Plus, Power, RotateCcw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

interface Teacher {
  id: string;
  slug: string;
  name: string;
  accent: string;
  style: string;
  gender: 'female' | 'male' | 'neutral';
  voice_id: string | null;
  rive_asset: string | null;
  image_url: string | null;
  gradient_from: string;
  gradient_to: string;
  is_active: boolean;
}

export default function TeachersPage() {
  const canEdit = usePermission('personas.edit');
  const qc = useQueryClient();

  const { data, isLoading, error } = useQuery<Teacher[]>({
    queryKey: ['admin-teachers'],
    queryFn: () => api<Teacher[]>('/admin/teachers'),
  });

  const deactivate = useMutation({
    mutationFn: (id: string) => api(`/admin/teachers/${id}`, { method: 'DELETE' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-teachers'] }),
  });
  const restore = useMutation({
    mutationFn: (id: string) => api(`/admin/teachers/${id}/restore`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-teachers'] }),
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Teachers</h1>
        {canEdit && (
          <Link href="/teachers/new">
            <Button>
              <Plus className="h-4 w-4" />
              New teacher
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
              <th className="px-4 py-2 text-left font-medium">Name</th>
              <th className="px-4 py-2 text-left font-medium">Accent</th>
              <th className="px-4 py-2 text-left font-medium">Style</th>
              <th className="px-4 py-2 text-left font-medium">Gender</th>
              <th className="px-4 py-2 text-left font-medium">Voice</th>
              <th className="px-4 py-2 text-left font-medium">Status</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(data ?? []).map((p) => (
              <tr key={p.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2">
                  <Link href={`/teachers/${p.id}`} className="flex items-center gap-3 hover:underline">
                    <span
                      className="inline-block h-7 w-7 rounded-full"
                      style={{
                        background: `linear-gradient(135deg, ${p.gradient_from}, ${p.gradient_to})`,
                      }}
                    />
                    <span>{p.name}</span>
                    <span className="text-xs text-muted-foreground">/{p.slug}</span>
                  </Link>
                </td>
                <td className="px-4 py-2">{p.accent}</td>
                <td className="px-4 py-2">{p.style}</td>
                <td className="px-4 py-2 capitalize">{p.gender}</td>
                <td className="px-4 py-2 font-mono text-xs">{p.voice_id ?? '—'}</td>
                <td className="px-4 py-2">
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs ${
                      p.is_active
                        ? 'bg-emerald-100 text-emerald-900'
                        : 'bg-muted text-muted-foreground'
                    }`}
                  >
                    {p.is_active ? 'active' : 'inactive'}
                  </span>
                </td>
                <td className="px-4 py-2 text-right">
                  <div className="flex items-center justify-end gap-1">
                    {canEdit && (
                      <Link href={`/teachers/${p.id}`}>
                        <Button size="sm" variant="ghost">
                          <Pencil className="h-4 w-4" />
                          Edit
                        </Button>
                      </Link>
                    )}
                    {canEdit &&
                      (p.is_active ? (
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => {
                            if (confirm(`Deactivate teacher "${p.name}"? Past sessions stay attributed to them.`)) {
                              deactivate.mutate(p.id);
                            }
                          }}
                        >
                          <Power className="h-4 w-4" />
                          Deactivate
                        </Button>
                      ) : (
                        <Button size="sm" variant="outline" onClick={() => restore.mutate(p.id)}>
                          <RotateCcw className="h-4 w-4" />
                          Restore
                        </Button>
                      ))}
                  </div>
                </td>
              </tr>
            ))}
            {(data ?? []).length === 0 && !isLoading && (
              <tr>
                <td colSpan={7} className="px-4 py-6 text-center text-muted-foreground">
                  No teachers yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

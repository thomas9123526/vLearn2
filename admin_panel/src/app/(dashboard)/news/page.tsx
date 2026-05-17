'use client';

import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Pin, Archive, CheckCircle2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

interface NewsPost {
  id: string;
  slug: string;
  title: Record<string, string>;
  status: 'draft' | 'published' | 'archived';
  pinned: boolean;
  published_at: string | null;
  created_at: string;
}

interface NewsListResponse {
  items: NewsPost[];
  total: number;
  page: number;
  limit: number;
}

export default function NewsListPage() {
  const canEdit = usePermission('news.edit');
  const qc = useQueryClient();

  const { data, isLoading, error } = useQuery<NewsListResponse>({
    queryKey: ['admin-news'],
    queryFn: () => api<NewsListResponse>('/admin/news?limit=50'),
  });

  const publish = useMutation({
    mutationFn: (id: string) =>
      api(`/admin/news/${id}/publish`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-news'] }),
  });

  const archive = useMutation({
    mutationFn: (id: string) =>
      api(`/admin/news/${id}/archive`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-news'] }),
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">News</h1>
        {canEdit && (
          <Link href="/news/new">
            <Button>
              <Plus className="h-4 w-4" />
              New post
            </Button>
          </Link>
        )}
      </div>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
      {error && (
        <p className="text-sm text-destructive">
          {(error as Error).message}
        </p>
      )}

      <Card className="overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="px-4 py-2 text-left font-medium">Title</th>
              <th className="px-4 py-2 text-left font-medium">Status</th>
              <th className="px-4 py-2 text-left font-medium">Pinned</th>
              <th className="px-4 py-2 text-left font-medium">Published</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(data?.items ?? []).map((post) => (
              <tr key={post.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2">
                  <Link href={`/news/${post.id}`} className="hover:underline">
                    {post.title.en ?? post.slug}
                  </Link>
                </td>
                <td className="px-4 py-2">
                  <StatusPill status={post.status} />
                </td>
                <td className="px-4 py-2">
                  {post.pinned && <Pin className="h-4 w-4 text-primary" />}
                </td>
                <td className="px-4 py-2 text-muted-foreground">
                  {post.published_at
                    ? new Date(post.published_at).toLocaleDateString()
                    : '—'}
                </td>
                <td className="px-4 py-2 text-right">
                  {canEdit && post.status === 'draft' && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => publish.mutate(post.id)}
                    >
                      <CheckCircle2 className="h-4 w-4" />
                      Publish
                    </Button>
                  )}
                  {canEdit && post.status === 'published' && (
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => archive.mutate(post.id)}
                    >
                      <Archive className="h-4 w-4" />
                      Archive
                    </Button>
                  )}
                </td>
              </tr>
            ))}
            {(data?.items ?? []).length === 0 && !isLoading && (
              <tr>
                <td colSpan={5} className="px-4 py-6 text-center text-muted-foreground">
                  No news posts yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

function StatusPill({ status }: { status: NewsPost['status'] }) {
  const classes =
    status === 'published'
      ? 'bg-green-100 text-green-800'
      : status === 'archived'
        ? 'bg-zinc-100 text-zinc-700'
        : 'bg-amber-100 text-amber-800';
  return (
    <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium ${classes}`}>
      {status}
    </span>
  );
}

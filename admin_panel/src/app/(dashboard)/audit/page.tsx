'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronLeft, ChevronRight, Search } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';

interface AuditRow {
  id: string;
  user_id: string | null;
  actor_email: string | null;
  actor_display_name: string | null;
  action: string;
  target_type: string;
  target_id: string;
  old_value: unknown;
  new_value: unknown;
  metadata: unknown;
  created_at: string;
}

interface AuditListResponse {
  items: AuditRow[];
  total: number;
  page: number;
  limit: number;
}

interface Filters {
  actor: string;
  action: string;
  target_type: string;
  target_id: string;
  since: string;
  until: string;
}

const EMPTY_FILTERS: Filters = {
  actor: '',
  action: '',
  target_type: '',
  target_id: '',
  since: '',
  until: '',
};

const PAGE_SIZE = 50;

export default function AuditPage() {
  const [filters, setFilters] = useState<Filters>(EMPTY_FILTERS);
  const [draft, setDraft] = useState<Filters>(EMPTY_FILTERS);
  const [page, setPage] = useState(1);

  const { data, isLoading, error, isFetching } = useQuery<AuditListResponse>({
    queryKey: ['admin-audit', filters, page],
    queryFn: () => {
      const params = new URLSearchParams();
      if (filters.actor) params.set('actor', filters.actor);
      if (filters.action) params.set('action', filters.action);
      if (filters.target_type) params.set('target_type', filters.target_type);
      if (filters.target_id) params.set('target_id', filters.target_id);
      if (filters.since) params.set('since', new Date(filters.since).toISOString());
      if (filters.until) params.set('until', new Date(filters.until).toISOString());
      params.set('page', String(page));
      params.set('limit', String(PAGE_SIZE));
      return api<AuditListResponse>(`/admin/audit?${params.toString()}`);
    },
  });

  function applyFilters() {
    setFilters(draft);
    setPage(1);
  }
  function resetFilters() {
    setDraft(EMPTY_FILTERS);
    setFilters(EMPTY_FILTERS);
    setPage(1);
  }

  const totalPages = data ? Math.max(1, Math.ceil(data.total / PAGE_SIZE)) : 1;

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Audit log</h2>
        <p className="text-sm text-muted-foreground">
          Every privileged admin action. Filter by actor, action verb, target,
          or date range. Most-recent first.
        </p>
      </div>

      <Card>
        <CardContent className="space-y-3 py-4">
          <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-6">
            <div className="space-y-1">
              <Label htmlFor="f-actor" className="text-xs">Actor (admin UUID)</Label>
              <Input
                id="f-actor"
                value={draft.actor}
                placeholder="uuid"
                onChange={(e) => setDraft({ ...draft, actor: e.target.value })}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="f-action" className="text-xs">Action</Label>
              <Input
                id="f-action"
                value={draft.action}
                placeholder="e.g. user.suspend"
                onChange={(e) => setDraft({ ...draft, action: e.target.value })}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="f-tt" className="text-xs">Target type</Label>
              <Input
                id="f-tt"
                value={draft.target_type}
                placeholder="e.g. scenario"
                onChange={(e) => setDraft({ ...draft, target_type: e.target.value })}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="f-tid" className="text-xs">Target id</Label>
              <Input
                id="f-tid"
                value={draft.target_id}
                placeholder="uuid or key"
                onChange={(e) => setDraft({ ...draft, target_id: e.target.value })}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="f-since" className="text-xs">Since</Label>
              <Input
                id="f-since"
                type="datetime-local"
                value={draft.since}
                onChange={(e) => setDraft({ ...draft, since: e.target.value })}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="f-until" className="text-xs">Until</Label>
              <Input
                id="f-until"
                type="datetime-local"
                value={draft.until}
                onChange={(e) => setDraft({ ...draft, until: e.target.value })}
              />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button size="sm" onClick={applyFilters}>
              <Search className="h-4 w-4" />
              Apply
            </Button>
            <Button size="sm" variant="outline" onClick={resetFilters}>
              Reset
            </Button>
            {isFetching && (
              <span className="text-xs text-muted-foreground">Loading…</span>
            )}
          </div>
        </CardContent>
      </Card>

      {error && (
        <Card>
          <CardContent className="py-4 text-sm text-destructive">
            {(error as Error).message}
          </CardContent>
        </Card>
      )}

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="border-b border-border bg-muted/50 text-left text-xs uppercase tracking-wide text-muted-foreground">
                <tr>
                  <th className="px-3 py-2">When</th>
                  <th className="px-3 py-2">Actor</th>
                  <th className="px-3 py-2">Action</th>
                  <th className="px-3 py-2">Target</th>
                  <th className="px-3 py-2">Diff</th>
                </tr>
              </thead>
              <tbody>
                {isLoading && (
                  <tr>
                    <td colSpan={5} className="px-3 py-6 text-center text-muted-foreground">
                      Loading…
                    </td>
                  </tr>
                )}
                {!isLoading && (data?.items.length ?? 0) === 0 && (
                  <tr>
                    <td colSpan={5} className="px-3 py-6 text-center text-muted-foreground">
                      No audit entries match these filters.
                    </td>
                  </tr>
                )}
                {(data?.items ?? []).map((row) => (
                  <AuditRowItem key={row.id} row={row} />
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <div className="flex items-center justify-between text-xs text-muted-foreground">
        <span>
          {data ? `${data.total} entries` : '—'}
          {data?.total ? ` · page ${page} of ${totalPages}` : ''}
        </span>
        <div className="flex items-center gap-2">
          <Button
            size="sm"
            variant="outline"
            disabled={page <= 1}
            onClick={() => setPage((p) => Math.max(1, p - 1))}
          >
            <ChevronLeft className="h-4 w-4" />
            Prev
          </Button>
          <Button
            size="sm"
            variant="outline"
            disabled={page >= totalPages}
            onClick={() => setPage((p) => p + 1)}
          >
            Next
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}

function AuditRowItem({ row }: { row: AuditRow }) {
  const [open, setOpen] = useState(false);
  const dt = new Date(row.created_at);
  const actorLabel = row.actor_display_name
    ? `${row.actor_display_name} <${row.actor_email ?? row.user_id ?? 'unknown'}>`
    : row.actor_email ?? row.user_id ?? '(deleted)';
  const hasDiff = row.old_value !== null || row.new_value !== null || row.metadata !== null;

  return (
    <>
      <tr className="border-b border-border align-top">
        <td className="whitespace-nowrap px-3 py-2 font-mono text-xs">
          {dt.toLocaleString()}
        </td>
        <td className="px-3 py-2 text-xs">{actorLabel}</td>
        <td className="px-3 py-2 font-mono text-xs">{row.action}</td>
        <td className="px-3 py-2 font-mono text-xs">
          <div>{row.target_type}</div>
          <div className="text-muted-foreground">{row.target_id}</div>
        </td>
        <td className="px-3 py-2">
          {hasDiff ? (
            <Button size="sm" variant="ghost" onClick={() => setOpen((o) => !o)}>
              {open ? 'Hide' : 'Show'}
            </Button>
          ) : (
            <span className="text-xs text-muted-foreground">—</span>
          )}
        </td>
      </tr>
      {open && hasDiff && (
        <tr className="border-b border-border bg-muted/30">
          <td colSpan={5} className="px-3 py-2">
            <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
              <DiffBlock title="Before" value={row.old_value} />
              <DiffBlock title="After" value={row.new_value} />
              <DiffBlock title="Metadata" value={row.metadata} />
            </div>
          </td>
        </tr>
      )}
    </>
  );
}

function DiffBlock({ title, value }: { title: string; value: unknown }) {
  return (
    <div>
      <div className="mb-1 text-xs font-medium uppercase tracking-wide text-muted-foreground">
        {title}
      </div>
      <pre className="overflow-auto rounded border border-border bg-background p-2 font-mono text-xs">
        {value === null || value === undefined
          ? '—'
          : JSON.stringify(value, null, 2)}
      </pre>
    </div>
  );
}

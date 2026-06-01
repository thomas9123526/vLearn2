'use client';

import { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ChevronDown, ChevronRight } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';
import {
  APP_TABS,
  FLAG_CATALOG,
  type AppTab,
  type FlagDescriptor,
} from '@/lib/flag-catalog';

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
  const [activeTab, setActiveTab] = useState<AppTab>('home');
  const [showAdvanced, setShowAdvanced] = useState(false);

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

  // Index live config entries by key for fast lookup.
  const byKey = new Map<string, ConfigEntry>(
    (data ?? []).map((e) => [e.key, e] as const),
  );

  // For each tab, partition the catalog into big-tier and fine-tier.
  const tabDescriptors = FLAG_CATALOG.filter((d) => d.tab === activeTab);
  const bigFlags = tabDescriptors.filter((d) => d.tier === 'big');
  const fineFlags = tabDescriptors.filter((d) => d.tier === 'fine');

  // Any live config entries the catalog doesn't know about — show them in
  // an "Uncategorized" expander so nothing silently disappears.
  const knownKeys = new Set(FLAG_CATALOG.map((d) => d.key));
  const orphans = (data ?? []).filter((e) => !knownKeys.has(e.key));

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Layout flags</h1>
        <p className="text-sm text-muted-foreground">
          Show or hide big sections of the app, one screen at a time. Changes
          take effect on the user&apos;s next app launch.
        </p>
      </div>

      {/* Tab strip */}
      <div className="flex flex-wrap gap-1 border-b border-border">
        {APP_TABS.map((t) => (
          <button
            key={t.id}
            onClick={() => {
              setActiveTab(t.id);
              setShowAdvanced(false);
            }}
            className={
              'rounded-t-md px-4 py-2 text-sm transition ' +
              (activeTab === t.id
                ? 'bg-primary text-primary-foreground'
                : 'hover:bg-muted')
            }
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Tab hint */}
      <p className="text-xs text-muted-foreground">
        {APP_TABS.find((t) => t.id === activeTab)?.hint}
      </p>

      {/* Big-layout toggles */}
      <Card className="overflow-hidden">
        <div className="border-b border-border bg-muted/50 px-4 py-2 text-sm font-medium">
          Big sections
        </div>
        <div className="divide-y divide-border">
          {bigFlags.length === 0 ? (
            <div className="px-4 py-6 text-center text-sm text-muted-foreground">
              This tab has no big-layout toggles configured.
            </div>
          ) : (
            bigFlags.map((d) => (
              <FlagRow
                key={d.key}
                descriptor={d}
                entry={byKey.get(d.key)}
                canEdit={canEdit}
                onChange={(v) => update.mutate({ key: d.key, value: v })}
              />
            ))
          )}
        </div>
      </Card>

      {/* Advanced expander */}
      {fineFlags.length > 0 && (
        <Card className="overflow-hidden">
          <button
            onClick={() => setShowAdvanced((s) => !s)}
            className="flex w-full items-center justify-between border-b border-border bg-muted/30 px-4 py-2 text-sm font-medium hover:bg-muted"
          >
            <span>Advanced ({fineFlags.length})</span>
            {showAdvanced ? (
              <ChevronDown className="h-4 w-4" />
            ) : (
              <ChevronRight className="h-4 w-4" />
            )}
          </button>
          {showAdvanced && (
            <div className="divide-y divide-border">
              {fineFlags.map((d) => (
                <FlagRow
                  key={d.key}
                  descriptor={d}
                  entry={byKey.get(d.key)}
                  canEdit={canEdit}
                  onChange={(v) => update.mutate({ key: d.key, value: v })}
                />
              ))}
            </div>
          )}
        </Card>
      )}

      {/* Orphans — flags returned by the API that the catalog hasn't
          described yet. Helps surface drift when someone seeds new flags. */}
      {orphans.length > 0 && (
        <Card className="overflow-hidden">
          <div className="border-b border-border bg-amber-50 px-4 py-2 text-sm font-medium text-amber-900">
            Uncategorized flags ({orphans.length})
          </div>
          <div className="divide-y divide-border">
            {orphans.map((e) => (
              <RawConfigRow
                key={e.key}
                entry={e}
                canEdit={canEdit}
                onToggle={(v) => update.mutate({ key: e.key, value: v })}
              />
            ))}
          </div>
          <p className="bg-amber-50/50 px-4 py-2 text-xs text-amber-900/80">
            These keys exist on the backend but aren&apos;t in the admin catalog
            yet. Add them to <code>flag-catalog.ts</code> to give them a label
            and a tab.
          </p>
        </Card>
      )}
    </div>
  );
}

const MODE_LABELS: Record<string, string> = {
  tutor: 'Tutor',
  message: 'Message',
  both: 'Both',
};

function FlagRow({
  descriptor,
  entry,
  canEdit,
  onChange,
}: {
  descriptor: FlagDescriptor;
  entry: ConfigEntry | undefined;
  canEdit: boolean;
  onChange: (next: unknown) => void;
}) {
  const missing = !entry;
  const isSelect = descriptor.type === 'select';
  const isText = descriptor.type === 'text';
  const isTextarea = descriptor.type === 'textarea';
  const isBool = !isSelect && !isText && !isTextarea && entry?.value_type === 'boolean';

  const isTextLike = isText || isTextarea;
  // Local draft for text/textarea fields — saves on blur.
  const [draft, setDraft] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement & HTMLTextAreaElement>(null);
  const displayValue = draft ?? (isTextLike ? String(entry?.value ?? '') : '');

  const textClasses =
    'w-full rounded-md border border-border bg-background px-2 py-1 text-sm ' +
    'focus:outline-none focus:ring-1 focus:ring-primary ' +
    (!canEdit ? 'cursor-not-allowed opacity-50' : '');

  return (
    <div className={`gap-3 px-4 py-3 ${isTextLike ? 'space-y-2' : 'flex items-center'}`}>
      <div className="flex-1">
        <div className="text-sm font-medium">{descriptor.label}</div>
        <div className="font-mono text-xs text-muted-foreground">{descriptor.key}</div>
        {entry?.description && (
          <div className="text-xs text-muted-foreground">{entry.description}</div>
        )}
        {missing && (
          <div className="text-xs text-amber-700">
            Not seeded yet — run <code>npm run db:seed</code>.
          </div>
        )}
      </div>

      {/* Value control */}
      <div className={isTextLike ? '' : 'text-right'}>
        {missing ? (
          <span className="text-xs text-muted-foreground">—</span>
        ) : isSelect ? (
          <div className="flex gap-1">
            {(descriptor.options ?? []).map((opt) => (
              <button
                key={opt}
                disabled={!canEdit}
                onClick={() => onChange(opt)}
                className={
                  'rounded-full border px-3 py-1 text-xs transition ' +
                  (entry!.value === opt
                    ? 'border-primary bg-primary text-primary-foreground'
                    : 'border-border hover:bg-muted') +
                  (!canEdit ? ' cursor-not-allowed opacity-50' : ' cursor-pointer')
                }
              >
                {MODE_LABELS[opt] ?? opt}
              </button>
            ))}
          </div>
        ) : isTextarea ? (
          <textarea
            ref={inputRef as React.Ref<HTMLTextAreaElement>}
            rows={4}
            disabled={!canEdit}
            value={displayValue}
            onChange={(e) => setDraft(e.target.value)}
            onBlur={() => {
              if (draft !== null && draft !== String(entry!.value)) {
                onChange(draft);
              }
              setDraft(null);
            }}
            className={textClasses + ' resize-y'}
          />
        ) : isText ? (
          <input
            ref={inputRef as React.Ref<HTMLInputElement>}
            type="text"
            disabled={!canEdit}
            value={displayValue}
            onChange={(e) => setDraft(e.target.value)}
            onBlur={() => {
              if (draft !== null && draft !== String(entry!.value)) {
                onChange(draft);
              }
              setDraft(null);
            }}
            onKeyDown={(e) => { if (e.key === 'Enter') inputRef.current?.blur(); }}
            className={textClasses}
          />
        ) : isBool ? (
          <input
            type="checkbox"
            checked={Boolean(entry!.value)}
            disabled={!canEdit}
            onChange={(e) => onChange(e.target.checked)}
            className="h-4 w-4 cursor-pointer"
          />
        ) : (
          <span className="font-mono text-xs text-muted-foreground">
            {JSON.stringify(entry!.value)}
          </span>
        )}
      </div>
    </div>
  );
}

function RawConfigRow({
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

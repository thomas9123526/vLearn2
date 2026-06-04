'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2, Variable } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

export interface PromptVar {
  key: string;
  label: string;
  description: string | null;
  global_value: string | null;
  scenario_overridable: boolean;
  sort_order: number;
}

export default function PromptVarsPage() {
  const canEdit = usePermission('prompts.edit');
  const qc = useQueryClient();

  const { data, isLoading, error } = useQuery<PromptVar[]>({
    queryKey: ['admin-prompt-vars'],
    queryFn: () => api<PromptVar[]>('/admin/prompt-vars'),
  });

  const [showAdd, setShowAdd] = useState(false);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="flex items-center gap-2 text-2xl font-semibold">
            <Variable className="h-6 w-6" /> Prompt variables
          </h1>
          <p className="text-sm text-muted-foreground">
            Define <code className="rounded bg-muted px-1 text-xs">{'{key}'}</code> placeholders
            used in the system prompt template. Scenario-level overrides take priority over the
            global value set here.
          </p>
        </div>
        {canEdit && (
          <Button size="sm" onClick={() => setShowAdd(true)} disabled={showAdd}>
            <Plus className="h-4 w-4" /> Add variable
          </Button>
        )}
      </div>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
      {error && <p className="text-sm text-destructive">{(error as Error).message}</p>}

      {showAdd && (
        <AddVarCard
          onDone={() => {
            setShowAdd(false);
            qc.invalidateQueries({ queryKey: ['admin-prompt-vars'] });
          }}
          onCancel={() => setShowAdd(false)}
        />
      )}

      {(data ?? []).map((v) => (
        <VarCard key={v.key} variable={v} canEdit={canEdit} />
      ))}
    </div>
  );
}

function VarCard({ variable, canEdit }: { variable: PromptVar; canEdit: boolean }) {
  const qc = useQueryClient();
  const [value, setValue] = useState(variable.global_value ?? '');
  const [savedAt, setSavedAt] = useState<Date | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const dirty = value !== (variable.global_value ?? '');

  const save = useMutation({
    mutationFn: () =>
      api(`/admin/prompt-vars/${variable.key}`, {
        method: 'PATCH',
        body: { global_value: value || null },
      }),
    onSuccess: () => {
      setSavedAt(new Date());
      setErr(null);
      qc.invalidateQueries({ queryKey: ['admin-prompt-vars'] });
    },
    onError: (e) => setErr(e instanceof Error ? e.message : 'Save failed'),
  });

  const remove = useMutation({
    mutationFn: () =>
      api(`/admin/prompt-vars/${variable.key}`, { method: 'DELETE' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-prompt-vars'] }),
    onError: (e) => setErr(e instanceof Error ? e.message : 'Delete failed'),
  });

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between gap-3">
          <div>
            <CardTitle className="text-base">{variable.label}</CardTitle>
            <CardDescription className="font-mono text-xs">{`{${variable.key}}`}</CardDescription>
            {variable.description && (
              <p className="mt-1 text-sm text-muted-foreground">{variable.description}</p>
            )}
          </div>
          <div className="flex shrink-0 items-center gap-2 text-xs text-muted-foreground">
            {variable.scenario_overridable && (
              <span className="rounded bg-muted px-2 py-0.5">scenario-overridable</span>
            )}
            {canEdit && (
              <button
                type="button"
                onClick={() => {
                  if (confirm(`Delete variable "{${variable.key}}"? Remove it from any templates that use it too.`))
                    remove.mutate();
                }}
                className="rounded p-1 hover:bg-destructive/10 hover:text-destructive"
                title="Delete variable"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-2">
        <div>
          <Label htmlFor={`var-${variable.key}`} className="sr-only">
            Global value
          </Label>
          <Input
            id={`var-${variable.key}`}
            value={value}
            disabled={!canEdit}
            onChange={(e) => setValue(e.target.value)}
            placeholder="Global default (empty = blank in prompt)"
          />
        </div>
        <div className="flex items-center justify-between">
          <span className="text-xs text-muted-foreground">
            {err && <span className="text-destructive">{err}</span>}
            {!err && savedAt && <span>Saved {savedAt.toLocaleTimeString()}.</span>}
          </span>
          <Button
            size="sm"
            disabled={!canEdit || !dirty || save.isPending}
            onClick={() => save.mutate()}
          >
            {save.isPending ? 'Saving…' : 'Save'}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function AddVarCard({ onDone, onCancel }: { onDone: () => void; onCancel: () => void }) {
  const [key, setKey] = useState('');
  const [label, setLabel] = useState('');
  const [description, setDescription] = useState('');
  const [globalValue, setGlobalValue] = useState('');
  const [err, setErr] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: () =>
      api('/admin/prompt-vars', {
        method: 'POST',
        body: {
          key: key.trim(),
          label: label.trim(),
          description: description.trim() || null,
          global_value: globalValue.trim() || null,
          scenario_overridable: true,
        },
      }),
    onSuccess: onDone,
    onError: (e) => setErr(e instanceof Error ? e.message : 'Failed to create'),
  });

  return (
    <Card className="border-primary/40">
      <CardHeader className="pb-2">
        <CardTitle className="text-base">New variable</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-1">
            <Label htmlFor="new-key">Key (placeholder name)</Label>
            <Input
              id="new-key"
              value={key}
              onChange={(e) => setKey(e.target.value.replace(/\s/g, '_').toLowerCase())}
              placeholder="my_variable"
              className="font-mono"
            />
          </div>
          <div className="space-y-1">
            <Label htmlFor="new-label">Label</Label>
            <Input
              id="new-label"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
              placeholder="Human-readable name"
            />
          </div>
        </div>
        <div className="space-y-1">
          <Label htmlFor="new-desc">Description (optional)</Label>
          <Input
            id="new-desc"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="What does this variable do?"
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="new-value">Global default value</Label>
          <Input
            id="new-value"
            value={globalValue}
            onChange={(e) => setGlobalValue(e.target.value)}
            placeholder="Default used when scenario has no override"
          />
        </div>
        {err && <p className="text-xs text-destructive">{err}</p>}
        <div className="flex gap-2">
          <Button
            size="sm"
            disabled={!key.trim() || !label.trim() || create.isPending}
            onClick={() => create.mutate()}
          >
            {create.isPending ? 'Creating…' : 'Create'}
          </Button>
          <Button size="sm" variant="outline" onClick={onCancel}>
            Cancel
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

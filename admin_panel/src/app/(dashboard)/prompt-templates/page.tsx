'use client';

import { useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Save, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

interface PromptTemplate {
  id: string;
  kind: 'tutor_system' | 'grammar' | 'feedback';
  label: string;
  description: string | null;
  template: string;
  is_active: boolean;
  updated_at: string;
}

/**
 * Available placeholders for each template kind. These mirror the keys the
 * backend's PromptBuilderService passes into its renderer. Editors should
 * use `{{group.field}}` syntax — unknown placeholders silently render as
 * empty strings on the server.
 */
const PLACEHOLDERS: Record<PromptTemplate['kind'], string[]> = {
  tutor_system: [
    '{{persona.name}}',
    '{{persona.style}}',
    '{{persona.specialties}}',
    '{{persona.gender}}',
    '{{persona.accent}}',
    '{{scenario.title}}',
    '{{scenario.setting}}',
    '{{scenario.tutor_role}}',
    '{{scenario.user_role}}',
    '{{scenario.objectives}}',
    '{{scenario.key_phrases}}',
    '{{user.level}}',
    '{{user.level_label}}',
    '{{user.native_language}}',
  ],
  grammar: ['{{user.level}}', '{{user.level_label}}', '{{user.messages}}'],
  feedback: [
    '{{session.scenario_title}}',
    '{{session.overall_score}}',
    '{{session.fluency_score}}',
    '{{session.vocabulary_score}}',
    '{{session.grammar_score}}',
    '{{session.engagement_score}}',
    '{{session.strongest_skill}}',
    '{{session.weakest_skill}}',
    '{{user.level_label}}',
  ],
};

export default function PromptTemplatesPage() {
  const canEdit = usePermission('config.edit');

  const { data, isLoading, error } = useQuery<PromptTemplate[]>({
    queryKey: ['admin-prompt-templates'],
    queryFn: () => api<PromptTemplate[]>('/admin/prompt-templates'),
  });

  return (
    <div className="space-y-4">
      <div>
        <h1 className="flex items-center gap-2 text-2xl font-semibold">
          <Sparkles className="h-6 w-6" /> Prompt templates
        </h1>
        <p className="text-sm text-muted-foreground">
          Tune the prompts the AI receives. Changes take effect immediately on
          the next chat turn — no server restart needed. Use{' '}
          <code className="rounded bg-muted px-1 text-xs">{'{{group.field}}'}</code>{' '}
          placeholders; unknown placeholders render as empty.
        </p>
      </div>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
      {error && <p className="text-sm text-destructive">{(error as Error).message}</p>}

      {(data ?? []).map((tpl) => (
        <TemplateCard key={tpl.id} template={tpl} canEdit={canEdit} />
      ))}
    </div>
  );
}

function TemplateCard({
  template,
  canEdit,
}: {
  template: PromptTemplate;
  canEdit: boolean;
}) {
  const qc = useQueryClient();
  const [text, setText] = useState(template.template);
  const [active, setActive] = useState(template.is_active);
  const [savedAt, setSavedAt] = useState<Date | null>(null);
  const [err, setErr] = useState<string | null>(null);

  // Reset local state if the upstream value refetches (e.g. after another
  // tab edited it). We compare by template id so we don't clobber the
  // user's in-progress edits on the same row.
  useEffect(() => {
    setText(template.template);
    setActive(template.is_active);
  }, [template.id, template.template, template.is_active]);

  const dirty = text !== template.template || active !== template.is_active;

  const save = useMutation({
    mutationFn: (patch: { template: string; is_active: boolean }) =>
      api<PromptTemplate>(`/admin/prompt-templates/${template.kind}`, {
        method: 'PATCH',
        body: patch,
      }),
    onSuccess: () => {
      setSavedAt(new Date());
      setErr(null);
      qc.invalidateQueries({ queryKey: ['admin-prompt-templates'] });
    },
    onError: (e) => setErr(e instanceof Error ? e.message : 'Save failed'),
  });

  function insertPlaceholder(p: string) {
    setText((t) => t + p);
  }

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between gap-3">
          <div>
            <CardTitle className="text-base">{template.label}</CardTitle>
            <CardDescription className="font-mono text-xs">{template.kind}</CardDescription>
            {template.description && (
              <p className="mt-1 text-sm text-muted-foreground">{template.description}</p>
            )}
          </div>
          <label className="inline-flex shrink-0 cursor-pointer items-center gap-2 text-sm">
            <input
              type="checkbox"
              className="h-4 w-4"
              checked={active}
              disabled={!canEdit}
              onChange={(e) => setActive(e.target.checked)}
            />
            Active
          </label>
        </div>
      </CardHeader>
      <CardContent className="space-y-2">
        <div className="flex flex-wrap gap-1">
          {PLACEHOLDERS[template.kind].map((p) => (
            <button
              key={p}
              type="button"
              onClick={() => canEdit && insertPlaceholder(p)}
              disabled={!canEdit}
              className="rounded bg-muted px-2 py-0.5 font-mono text-xs hover:bg-muted-foreground/20 disabled:opacity-50"
              title="Click to append at cursor"
            >
              {p}
            </button>
          ))}
        </div>
        <div>
          <Label htmlFor={`tpl-${template.kind}`} className="sr-only">
            Template
          </Label>
          <textarea
            id={`tpl-${template.kind}`}
            value={text}
            disabled={!canEdit}
            onChange={(e) => setText(e.target.value)}
            rows={Math.min(20, Math.max(8, text.split('\n').length + 1))}
            className="w-full rounded-md border border-border bg-background p-3 font-mono text-xs leading-relaxed"
          />
        </div>
        <div className="flex items-center justify-between">
          <div className="text-xs text-muted-foreground">
            {err && <span className="text-destructive">{err}</span>}
            {!err && savedAt && <span>Saved {savedAt.toLocaleTimeString()}.</span>}
            {!err && !savedAt && (
              <span>Last updated {new Date(template.updated_at).toLocaleString()}.</span>
            )}
          </div>
          <Button
            size="sm"
            disabled={!canEdit || !dirty || save.isPending}
            onClick={() => save.mutate({ template: text, is_active: active })}
          >
            <Save className="h-4 w-4" />
            {save.isPending ? 'Saving…' : 'Save'}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

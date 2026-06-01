'use client';

import { useEffect, useState } from 'react';
import {
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query';
import {
  Edit2,
  ListTree,
  Plus,
  ToggleLeft,
  ToggleRight,
  Trash2,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Dialog } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

interface I18nText {
  en: string;
  ko?: string;
  zh?: string;
}

interface Category {
  id: string;
  slug: string;
  title: I18nText;
  description: I18nText | null;
  order_index: number;
  is_active: boolean;
  created_at: string;
}

export default function CategoriesPage() {
  const canView = usePermission('categories.view');
  const canEdit = usePermission('categories.edit');
  const canDelete = usePermission('categories.delete');
  const qc = useQueryClient();

  const { data, isLoading, error } = useQuery<Category[]>({
    queryKey: ['admin-categories'],
    queryFn: () => api<Category[]>('/admin/categories'),
    enabled: canView,
  });

  const [editing, setEditing] = useState<Category | null>(null);
  const [creating, setCreating] = useState(false);
  const [deleteErrors, setDeleteErrors] = useState<Record<string, string>>({});

  const create = useMutation({
    mutationFn: (body: {
      slug: string;
      title: I18nText;
      description?: I18nText;
      order_index?: number;
    }) => api<Category>('/admin/categories', { method: 'POST', body }),
    onSuccess: () => {
      setCreating(false);
      qc.invalidateQueries({ queryKey: ['admin-categories'] });
    },
  });

  const update = useMutation({
    mutationFn: ({
      id,
      patch,
    }: {
      id: string;
      patch: Partial<{
        title: I18nText;
        description: I18nText | null;
        order_index: number;
        is_active: boolean;
      }>;
    }) =>
      api<Category>(`/admin/categories/${id}`, {
        method: 'PATCH',
        body: patch,
      }),
    onSuccess: () => {
      setEditing(null);
      qc.invalidateQueries({ queryKey: ['admin-categories'] });
    },
  });

  const remove = useMutation({
    mutationFn: (id: string) =>
      api(`/admin/categories/${id}`, { method: 'DELETE' }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['admin-categories'] }),
  });

  if (!canView) {
    return (
      <p className="text-sm text-muted-foreground">
        You don&apos;t have permission to view categories.
      </p>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="flex items-center gap-2 text-2xl font-semibold">
          <ListTree className="h-6 w-6" /> Categories
        </h1>
        {canEdit && (
          <Button onClick={() => setCreating(true)}>
            <Plus className="h-4 w-4" /> New category
          </Button>
        )}
      </div>

      <p className="text-sm text-muted-foreground">
        Categories group scenarios. The <code>slug</code> is immutable after
        creation — only the localized title and active flag can change.
      </p>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
      {error && (
        <p className="text-sm text-destructive">
          {(error as Error).message}
        </p>
      )}

      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
        {(data ?? []).map((c) => (
          <CategoryCard
            key={c.id}
            category={c}
            canEdit={canEdit}
            canDelete={canDelete}
            deleteError={deleteErrors[c.id]}
            onEdit={() => setEditing(c)}
            onToggleActive={() =>
              update.mutate({ id: c.id, patch: { is_active: !c.is_active } })
            }
            onDelete={async () => {
              if (
                !confirm(
                  `Delete category "${c.title.en}"? This fails if any scenario still uses it.`,
                )
              )
                return;
              try {
                await remove.mutateAsync(c.id);
                // clear any previous error for this category
                setDeleteErrors((p) => {
                  const copy = { ...p };
                  delete copy[c.id];
                  return copy;
                });
              } catch (err: any) {
                const body = err?.body ?? err?.body?.message ?? err;
                let msg = err?.message ?? String(err);
                if (body?.i18nKey === 'category.in_use' || body?.message?.i18nKey === 'category.in_use') {
                  const count = body.inUseCount ?? body.message?.inUseCount ?? 'unknown';
                  msg = `Cannot delete: ${count} scenario(s) still use this category.`;
                }
                setDeleteErrors((p) => ({ ...p, [c.id]: msg }));
                console.error('Delete category failed', err);
              }
            }}
          />
        ))}
        {data?.length === 0 && (
          <p className="text-sm text-muted-foreground">No categories yet.</p>
        )}
      </div>

      <EditDialog
        category={editing}
        pending={update.isPending}
        onClose={() => setEditing(null)}
        onSave={(patch) => {
          if (!editing) return;
          update.mutate({ id: editing.id, patch });
        }}
      />

      <CreateDialog
        open={creating}
        pending={create.isPending}
        error={create.error instanceof Error ? create.error.message : null}
        onClose={() => setCreating(false)}
        onSave={(body) => create.mutate(body)}
      />
    </div>
  );
}

function CategoryCard({
  category,
  canEdit,
  canDelete,
  onEdit,
  onToggleActive,
  onDelete,
  deleteError,
}: {
  category: Category;
  canEdit: boolean;
  canDelete: boolean;
  onEdit: () => void;
  onToggleActive: () => void;
  onDelete: () => void;
  deleteError?: string;
}) {
  return (
    <Card className="flex h-full flex-col">
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between gap-2">
          <div>
            <CardTitle className="text-base">{category.title.en}</CardTitle>
            <CardDescription className="font-mono text-xs">
              {category.slug}
            </CardDescription>
          </div>
          <span
            className={
              'rounded-full px-2 py-0.5 text-xs ' +
              (category.is_active
                ? 'bg-green-100 text-green-700'
                : 'bg-muted text-muted-foreground')
            }
          >
            {category.is_active ? 'active' : 'inactive'}
          </span>
        </div>
      </CardHeader>
      <CardContent className="flex flex-1 flex-col gap-2 pt-0">
        <dl className="grid grid-cols-2 gap-y-1 text-xs">
          <dt className="text-muted-foreground">Korean</dt>
          <dd>{category.title.ko ?? '—'}</dd>
          <dt className="text-muted-foreground">Chinese</dt>
          <dd>{category.title.zh ?? '—'}</dd>
          <dt className="text-muted-foreground">Order</dt>
          <dd>{category.order_index}</dd>
        </dl>
        <div className="mt-auto flex flex-wrap items-center justify-end gap-2 pt-2">
          {canEdit && (
            <Button size="sm" variant="outline" onClick={onEdit}>
              <Edit2 className="h-4 w-4" /> Edit
            </Button>
          )}
          {canEdit && (
            <Button size="sm" variant="outline" onClick={onToggleActive}>
              {category.is_active ? (
                <ToggleRight className="h-4 w-4" />
              ) : (
                <ToggleLeft className="h-4 w-4" />
              )}
              {category.is_active ? 'Deactivate' : 'Activate'}
            </Button>
          )}
          {canDelete && (
            <Button size="sm" variant="destructive" onClick={onDelete}>
              <Trash2 className="h-4 w-4" /> Delete
            </Button>
          )}
        </div>
        {deleteError && (
          <p className="text-sm text-destructive mt-2">{deleteError}</p>
        )}
      </CardContent>
    </Card>
  );
}

function EditDialog({
  category,
  pending,
  onClose,
  onSave,
}: {
  category: Category | null;
  pending: boolean;
  onClose: () => void;
  onSave: (patch: {
    title: I18nText;
    description: I18nText | null;
    order_index: number;
  }) => void;
}) {
  const [en, setEn] = useState('');
  const [ko, setKo] = useState('');
  const [zh, setZh] = useState('');
  const [descEn, setDescEn] = useState('');
  const [order, setOrder] = useState(0);

  useEffect(() => {
    if (!category) return;
    setEn(category.title.en);
    setKo(category.title.ko ?? '');
    setZh(category.title.zh ?? '');
    setDescEn(category.description?.en ?? '');
    setOrder(category.order_index);
  }, [category]);

  return (
    <Dialog
      open={category !== null}
      onClose={onClose}
      title={category ? `Edit — ${category.slug}` : 'Edit category'}
      size="md"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={pending || !en.trim()}
            onClick={() =>
              onSave({
                title: {
                  en: en.trim(),
                  ko: ko.trim() || undefined,
                  zh: zh.trim() || undefined,
                },
                description: descEn.trim() ? { en: descEn.trim() } : null,
                order_index: order,
              })
            }
          >
            {pending ? 'Saving…' : 'Save'}
          </Button>
        </>
      }
    >
      <div className="space-y-3">
        <I18nField label="Title (English)" value={en} onChange={setEn} required />
        <I18nField label="Title (Korean)" value={ko} onChange={setKo} />
        <I18nField label="Title (Chinese)" value={zh} onChange={setZh} />
        <I18nField
          label="Description (English, optional)"
          value={descEn}
          onChange={setDescEn}
        />
        <div>
          <Label htmlFor="order">Order index</Label>
          <Input
            id="order"
            type="number"
            min={0}
            value={order}
            onChange={(e) => setOrder(parseInt(e.target.value || '0', 10))}
          />
        </div>
      </div>
    </Dialog>
  );
}

function CreateDialog({
  open,
  pending,
  error,
  onClose,
  onSave,
}: {
  open: boolean;
  pending: boolean;
  error: string | null;
  onClose: () => void;
  onSave: (body: {
    slug: string;
    title: I18nText;
    description?: I18nText;
    order_index?: number;
  }) => void;
}) {
  const [slug, setSlug] = useState('');
  const [en, setEn] = useState('');
  const [ko, setKo] = useState('');
  const [zh, setZh] = useState('');
  const [order, setOrder] = useState(0);

  useEffect(() => {
    if (!open) {
      setSlug('');
      setEn('');
      setKo('');
      setZh('');
      setOrder(0);
    }
  }, [open]);

  const slugValid = /^[a-z0-9_-]{2,50}$/.test(slug);

  return (
    <Dialog
      open={open}
      onClose={onClose}
      title="New category"
      description="Slug is permanent — pick carefully."
      size="md"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={pending || !slugValid || !en.trim()}
            onClick={() =>
              onSave({
                slug,
                title: {
                  en: en.trim(),
                  ko: ko.trim() || undefined,
                  zh: zh.trim() || undefined,
                },
                order_index: order,
              })
            }
          >
            {pending ? 'Creating…' : 'Create'}
          </Button>
        </>
      }
    >
      <div className="space-y-3">
        <div>
          <Label htmlFor="slug">Slug</Label>
          <Input
            id="slug"
            placeholder="e.g. healthcare"
            value={slug}
            onChange={(e) => setSlug(e.target.value)}
          />
          <p className="mt-1 text-xs text-muted-foreground">
            Lowercase a–z, 0–9, <code>_</code> or <code>-</code>; length 2–50.
          </p>
        </div>
        <I18nField label="Title (English)" value={en} onChange={setEn} required />
        <I18nField label="Title (Korean)" value={ko} onChange={setKo} />
        <I18nField label="Title (Chinese)" value={zh} onChange={setZh} />
        <div>
          <Label htmlFor="order-new">Order index</Label>
          <Input
            id="order-new"
            type="number"
            min={0}
            value={order}
            onChange={(e) => setOrder(parseInt(e.target.value || '0', 10))}
          />
        </div>
        {error && <p className="text-sm text-destructive">{error}</p>}
      </div>
    </Dialog>
  );
}

function I18nField({
  label,
  value,
  onChange,
  required,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  required?: boolean;
}) {
  const id = `f-${label.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
  return (
    <div>
      <Label htmlFor={id}>{label}</Label>
      <Input
        id={id}
        value={value}
        required={required}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
}

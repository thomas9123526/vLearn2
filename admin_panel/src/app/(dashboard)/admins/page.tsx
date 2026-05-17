'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ShieldCheck, ShieldOff, Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';
import { usePermissionCatalog, type PermissionDef } from '@/lib/permissions';
import { usePermission } from '@/hooks/use-permission';

interface SubAdmin {
  id: string;
  email: string;
  display_name: string;
  role: 'admin' | 'superadmin';
  status: 'active' | 'suspended' | 'deleted';
  permissions: string[];
}

export default function AdminsPage() {
  const canCreate = usePermission('admins.create');
  const canGrant = usePermission('admins.grant_permissions');
  const canSuspend = usePermission('admins.suspend');
  const qc = useQueryClient();
  const { data: catalog } = usePermissionCatalog();

  const { data: admins } = useQuery<SubAdmin[]>({
    queryKey: ['admin-admins'],
    queryFn: () => api<SubAdmin[]>('/admin/admins'),
  });

  const replacePerms = useMutation({
    mutationFn: ({ id, permissions }: { id: string; permissions: string[] }) =>
      api(`/admin/admins/${id}/permissions`, {
        method: 'PUT',
        body: { permissions },
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-admins'] }),
  });

  const suspend = useMutation({
    mutationFn: (id: string) => api(`/admin/admins/${id}/suspend`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-admins'] }),
  });
  const restore = useMutation({
    mutationFn: (id: string) => api(`/admin/admins/${id}/restore`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-admins'] }),
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="flex items-center gap-2 text-2xl font-semibold">
          <ShieldCheck className="h-6 w-6" /> Sub-admins
        </h1>
      </div>

      {canCreate && (
        <CreateSubAdminForm
          catalog={catalog ?? []}
          onCreated={() => qc.invalidateQueries({ queryKey: ['admin-admins'] })}
        />
      )}

      <div className="space-y-3">
        {(admins ?? []).map((a) => (
          <Card key={a.id}>
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-base">{a.display_name}</CardTitle>
                  <CardDescription>
                    {a.email} · {a.role} · {a.status}
                  </CardDescription>
                </div>
                <div className="flex gap-2">
                  {canSuspend && a.role !== 'superadmin' && a.status === 'active' && (
                    <Button size="sm" variant="destructive" onClick={() => suspend.mutate(a.id)}>
                      <ShieldOff className="h-4 w-4" /> Suspend
                    </Button>
                  )}
                  {canSuspend && a.status === 'suspended' && (
                    <Button size="sm" variant="outline" onClick={() => restore.mutate(a.id)}>
                      Restore
                    </Button>
                  )}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {a.role === 'superadmin' ? (
                <p className="text-sm text-muted-foreground">
                  Superadmin has all permissions implicitly.
                </p>
              ) : (
                <PermissionGrid
                  catalog={catalog ?? []}
                  granted={a.permissions ?? []}
                  disabled={!canGrant}
                  onChange={(next) => replacePerms.mutate({ id: a.id, permissions: next })}
                />
              )}
            </CardContent>
          </Card>
        ))}
        {(admins ?? []).length === 0 && (
          <p className="text-sm text-muted-foreground">No sub-admins yet.</p>
        )}
      </div>
    </div>
  );
}

function CreateSubAdminForm({
  catalog,
  onCreated,
}: {
  catalog: PermissionDef[];
  onCreated: () => void;
}) {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [perms, setPerms] = useState<string[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      await api('/admin/admins', {
        method: 'POST',
        body: { email, displayName: name, password, permissions: perms },
      });
      setEmail('');
      setName('');
      setPassword('');
      setPerms([]);
      onCreated();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <Plus className="h-4 w-4" /> Create sub-admin
        </CardTitle>
      </CardHeader>
      <CardContent>
        <form className="space-y-3" onSubmit={submit}>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="name">Display name</Label>
              <Input
                id="name"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="pw">Password (≥12)</Label>
              <Input
                id="pw"
                type="password"
                minLength={12}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>
          <div>
            <Label>Initial permissions</Label>
            <PermissionGrid catalog={catalog} granted={perms} onChange={setPerms} />
          </div>
          {err && <p className="text-sm text-destructive">{err}</p>}
          <Button type="submit" disabled={busy}>
            {busy ? 'Creating…' : 'Create sub-admin'}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

function PermissionGrid({
  catalog,
  granted,
  disabled,
  onChange,
}: {
  catalog: PermissionDef[];
  granted: string[];
  disabled?: boolean;
  onChange: (next: string[]) => void;
}) {
  const grantable = catalog.filter((p) => p.grantable_to_subadmin);
  const byCategory: Record<string, PermissionDef[]> = {};
  for (const p of grantable) (byCategory[p.category] ??= []).push(p);
  const set = new Set(granted);

  function toggle(key: string, checked: boolean) {
    const next = new Set(set);
    if (checked) next.add(key);
    else next.delete(key);
    onChange([...next]);
  }

  return (
    <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
      {Object.entries(byCategory).map(([cat, items]) => (
        <div key={cat} className="rounded-md border border-border p-3">
          <div className="mb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">
            {cat}
          </div>
          <ul className="space-y-1.5">
            {items.map((p) => (
              <li key={p.key} className="flex items-start gap-2">
                <input
                  type="checkbox"
                  className="mt-0.5 h-4 w-4"
                  checked={set.has(p.key)}
                  disabled={disabled}
                  onChange={(e) => toggle(p.key, e.target.checked)}
                />
                <div className="text-xs">
                  <div className="font-mono">{p.key}</div>
                  <div className="text-muted-foreground">{p.description}</div>
                </div>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
}

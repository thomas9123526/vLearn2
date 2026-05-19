'use client';

import { useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { KeyRound, Plus, ShieldCheck, ShieldOff } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog } from '@/components/ui/dialog';
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

  // Which admin is currently having its permissions edited in the modal.
  const [editPermsFor, setEditPermsFor] = useState<SubAdmin | null>(null);

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

      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
        {(admins ?? []).map((a) => (
          <AdminCard
            key={a.id}
            admin={a}
            canGrant={canGrant}
            canSuspend={canSuspend}
            onSuspend={() => suspend.mutate(a.id)}
            onRestore={() => restore.mutate(a.id)}
            onEditPermissions={() => setEditPermsFor(a)}
          />
        ))}
        {(admins ?? []).length === 0 && (
          <p className="text-sm text-muted-foreground">No sub-admins yet.</p>
        )}
      </div>

      <EditPermissionsDialog
        admin={editPermsFor}
        catalog={catalog ?? []}
        disabled={!canGrant}
        pending={replacePerms.isPending}
        onClose={() => setEditPermsFor(null)}
        onSave={(perms) => {
          if (!editPermsFor) return;
          replacePerms.mutate(
            { id: editPermsFor.id, permissions: perms },
            { onSuccess: () => setEditPermsFor(null) },
          );
        }}
      />
    </div>
  );
}

/// Compact card. No permission checkboxes here — the user opens a dialog
/// for those instead. Shows just enough identity / status info to act on.
function AdminCard({
  admin,
  canGrant,
  canSuspend,
  onSuspend,
  onRestore,
  onEditPermissions,
}: {
  admin: SubAdmin;
  canGrant: boolean;
  canSuspend: boolean;
  onSuspend: () => void;
  onRestore: () => void;
  onEditPermissions: () => void;
}) {
  const statusColor =
    admin.status === 'active'
      ? 'text-green-600'
      : admin.status === 'suspended'
        ? 'text-yellow-600'
        : 'text-muted-foreground';

  const roleLabel = admin.role === 'superadmin' ? 'Superadmin' : 'Admin';
  const permCount = admin.permissions?.length ?? 0;

  return (
    <Card className="flex h-full flex-col">
      <CardHeader className="pb-2">
        <CardTitle className="text-base">{admin.display_name}</CardTitle>
        <CardDescription className="break-all">{admin.email}</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-1 flex-col gap-3 pt-0">
        <dl className="grid grid-cols-2 gap-y-1 text-xs">
          <dt className="text-muted-foreground">Role</dt>
          <dd>{roleLabel}</dd>
          <dt className="text-muted-foreground">Status</dt>
          <dd className={statusColor}>{admin.status}</dd>
          <dt className="text-muted-foreground">Permissions</dt>
          <dd>
            {admin.role === 'superadmin' ? (
              <span className="text-muted-foreground">all (implicit)</span>
            ) : (
              <span>{permCount} granted</span>
            )}
          </dd>
        </dl>

        <div className="mt-auto flex flex-wrap items-center justify-end gap-2 pt-2">
          {canGrant && admin.role !== 'superadmin' && (
            <Button size="sm" variant="outline" onClick={onEditPermissions}>
              <KeyRound className="h-4 w-4" />
              Edit Permission
            </Button>
          )}
          {canSuspend &&
            admin.role !== 'superadmin' &&
            admin.status === 'active' && (
              <Button size="sm" variant="destructive" onClick={onSuspend}>
                <ShieldOff className="h-4 w-4" />
                Suspend
              </Button>
            )}
          {canSuspend && admin.status === 'suspended' && (
            <Button size="sm" variant="outline" onClick={onRestore}>
              Restore
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

/// Dialog body. Tracks its own selection while open so cancel-on-dismiss
/// works without re-fetching. Resets when a different admin is targeted.
function EditPermissionsDialog({
  admin,
  catalog,
  disabled,
  pending,
  onClose,
  onSave,
}: {
  admin: SubAdmin | null;
  catalog: PermissionDef[];
  disabled: boolean;
  pending: boolean;
  onClose: () => void;
  onSave: (perms: string[]) => void;
}) {
  const [selection, setSelection] = useState<string[]>([]);

  useEffect(() => {
    if (admin) setSelection(admin.permissions ?? []);
  }, [admin]);

  return (
    <Dialog
      open={admin !== null}
      onClose={onClose}
      title={admin ? `Permissions — ${admin.display_name}` : 'Permissions'}
      description={admin?.email}
      size="lg"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={disabled || pending}
            onClick={() => onSave(selection)}
          >
            {pending ? 'Saving…' : 'Save'}
          </Button>
        </>
      }
    >
      <PermissionGrid
        catalog={catalog}
        granted={selection}
        disabled={disabled}
        onChange={setSelection}
      />
    </Dialog>
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
  const [showPermDialog, setShowPermDialog] = useState(false);

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
          <div className="flex items-center gap-3">
            <span className="text-sm">
              <span className="text-muted-foreground">Initial permissions:</span>{' '}
              <span className="font-medium">{perms.length} selected</span>
            </span>
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={() => setShowPermDialog(true)}
            >
              <KeyRound className="h-4 w-4" />
              Choose permissions
            </Button>
          </div>
          {err && <p className="text-sm text-destructive">{err}</p>}
          <Button type="submit" disabled={busy}>
            {busy ? 'Creating…' : 'Create sub-admin'}
          </Button>
        </form>

        <Dialog
          open={showPermDialog}
          onClose={() => setShowPermDialog(false)}
          title="Initial permissions"
          size="lg"
          footer={
            <Button onClick={() => setShowPermDialog(false)}>Done</Button>
          }
        >
          <PermissionGrid catalog={catalog} granted={perms} onChange={setPerms} />
        </Dialog>
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

  if (grantable.length === 0) {
    return (
      <p className="text-sm text-muted-foreground">
        Permission catalog not loaded yet.
      </p>
    );
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

'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Ban, KeyRound, RotateCcw, Search } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Dialog } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

interface UserRow {
  id: string;
  email: string;
  display_name: string;
  status: 'active' | 'suspended' | 'deleted';
  suspended_until: string | null;
  suspended_reason: string | null;
  xp_total: number;
  current_level: number;
  streak_days: number;
  // Last platform the user activated a license from. Null until they
  // pass through /license/verify on a build that reports it.
  license_platform:
    | 'android'
    | 'windows'
    | 'ios'
    | 'macos'
    | 'linux'
    | 'fuchsia'
    | 'web'
    | null;
  license_valid_until: string | null;
  created_at: string;
}

interface UserListResp {
  items: UserRow[];
  total: number;
  page: number;
  limit: number;
}

export default function UsersPage() {
  const canSuspend = usePermission('users.suspend');
  const canResetPassword = usePermission('users.reset_password');
  const qc = useQueryClient();
  const [q, setQ] = useState('');
  const [status, setStatus] = useState<string>('');
  const [resetTarget, setResetTarget] = useState<UserRow | null>(null);

  const { data, isLoading } = useQuery<UserListResp>({
    queryKey: ['admin-users', q, status],
    queryFn: () => {
      const params = new URLSearchParams();
      if (q) params.set('q', q);
      if (status) params.set('status', status);
      return api<UserListResp>(`/admin/users?${params.toString()}`);
    },
  });

  const suspend = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      api(`/admin/users/${id}/suspend`, { method: 'POST', body: { reason } }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  });
  const restore = useMutation({
    mutationFn: (id: string) => api(`/admin/users/${id}/restore`, { method: 'POST' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  });

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">Users</h1>
      <div className="flex items-center gap-2">
        <div className="relative max-w-sm flex-1">
          <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search by email or name…"
            className="pl-8"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>
        <select
          className="h-9 rounded-md border border-border bg-background px-2 text-sm"
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="">All statuses</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="deleted">Deleted</option>
        </select>
      </div>

      {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}

      <Card className="overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="px-4 py-2 text-left font-medium">Email</th>
              <th className="px-4 py-2 text-left font-medium">Name</th>
              <th className="px-4 py-2 text-left font-medium">Status</th>
              <th className="px-4 py-2 text-left font-medium">Platform</th>
              <th className="px-4 py-2 text-right font-medium">XP</th>
              <th className="px-4 py-2 text-right font-medium">Streak</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(data?.items ?? []).map((u) => (
              <tr key={u.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2">{u.email}</td>
                <td className="px-4 py-2">{u.display_name}</td>
                <td className="px-4 py-2">
                  <StatusPill status={u.status} />
                  {u.suspended_reason && (
                    <span className="ml-2 text-xs text-muted-foreground">{u.suspended_reason}</span>
                  )}
                </td>
                <td className="px-4 py-2">
                  <PlatformPill platform={u.license_platform} />
                </td>
                <td className="px-4 py-2 text-right tabular-nums">{u.xp_total}</td>
                <td className="px-4 py-2 text-right tabular-nums">{u.streak_days}</td>
                <td className="px-4 py-2 text-right">
                  <div className="flex items-center justify-end gap-2">
                    {canResetPassword && u.status !== 'deleted' && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setResetTarget(u)}
                      >
                        <KeyRound className="h-4 w-4" /> Reset Password
                      </Button>
                    )}
                    {canSuspend && u.status === 'active' && (
                      <Button
                        size="sm"
                        variant="destructive"
                        onClick={() => {
                          const reason = prompt('Reason for suspension?') ?? '';
                          if (reason !== null) suspend.mutate({ id: u.id, reason });
                        }}
                      >
                        <Ban className="h-4 w-4" /> Block
                      </Button>
                    )}
                    {canSuspend && u.status === 'suspended' && (
                      <Button size="sm" variant="outline" onClick={() => restore.mutate(u.id)}>
                        <RotateCcw className="h-4 w-4" /> Restore
                      </Button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
            {(data?.items ?? []).length === 0 && !isLoading && (
              <tr>
                <td colSpan={7} className="px-4 py-6 text-center text-muted-foreground">
                  No users.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>

      <ResetPasswordDialog
        target={resetTarget}
        onClose={() => setResetTarget(null)}
      />
    </div>
  );
}

// Default placed in both password inputs when the reset dialog opens.
// The admin is expected to overwrite this with something they will
// actually tell the user; keeping the same string for both fields means
// they can hit Reset immediately to issue a known-good password without
// retyping. Length is fine (10 > 6 min); make sure it ALSO satisfies the
// SignUpDto regex if you ever pivot to letting users reuse it.
const DEFAULT_RESET_PASSWORD = '1234567890';

function ResetPasswordDialog({
  target,
  onClose,
}: {
  target: UserRow | null;
  onClose: () => void;
}) {
  const [password, setPassword] = useState(DEFAULT_RESET_PASSWORD);
  const [confirm, setConfirm] = useState(DEFAULT_RESET_PASSWORD);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  const submit = useMutation({
    mutationFn: ({ id, newPassword }: { id: string; newPassword: string }) =>
      api(`/admin/users/${id}/reset-password`, {
        method: 'POST',
        body: { newPassword },
      }),
    onSuccess: () => setDone(true),
    onError: (e: Error) =>
      setError(e.message || 'Reset failed. Please try again.'),
  });

  // Reset form state whenever a different user is selected (or dialog closes).
  const targetId = target?.id ?? null;
  // useEffect would import another hook; doing it inline via key on Dialog
  // is cleaner — see `key={targetId ?? 'closed'}` below.

  if (!target) return null;

  return (
    <Dialog
      key={targetId ?? 'closed'}
      open={!!target}
      onClose={() => {
        setPassword(DEFAULT_RESET_PASSWORD);
        setConfirm(DEFAULT_RESET_PASSWORD);
        setError(null);
        setDone(false);
        onClose();
      }}
      title="Reset password"
      description={
        done
          ? 'Password has been reset and every active session for this user has been revoked.'
          : `Set a new password for ${target.display_name || target.email}. They will be signed out of all devices.`
      }
      size="sm"
      footer={
        done ? (
          <Button
            onClick={() => {
              setPassword(DEFAULT_RESET_PASSWORD);
              setConfirm(DEFAULT_RESET_PASSWORD);
              setError(null);
              setDone(false);
              onClose();
            }}
          >
            Close
          </Button>
        ) : (
          <>
            <Button
              variant="outline"
              onClick={() => {
                setPassword(DEFAULT_RESET_PASSWORD);
                setConfirm(DEFAULT_RESET_PASSWORD);
                setError(null);
                onClose();
              }}
              disabled={submit.isPending}
            >
              Cancel
            </Button>
            <Button
              onClick={() => {
                setError(null);
                if (password.length < 6) {
                  setError('Password must be at least 6 characters.');
                  return;
                }
                if (password !== confirm) {
                  setError('Passwords do not match.');
                  return;
                }
                submit.mutate({ id: target.id, newPassword: password });
              }}
              disabled={submit.isPending}
            >
              {submit.isPending ? 'Resetting…' : 'Reset password'}
            </Button>
          </>
        )
      }
    >
      {done ? (
        <p className="text-sm">
          Tell the user their new password through a channel they trust
          (phone, in-person, secure messenger). It is <strong>not</strong>{' '}
          shown again here.
        </p>
      ) : (
        <div className="space-y-3">
          <div className="space-y-1">
            <Label htmlFor="reset-pw">New password</Label>
            <Input
              id="reset-pw"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Min 6 characters"
              autoComplete="new-password"
            />
          </div>
          <div className="space-y-1">
            <Label htmlFor="reset-pw2">Confirm</Label>
            <Input
              id="reset-pw2"
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              autoComplete="new-password"
            />
          </div>
          {error && (
            <p className="rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive">
              {error}
            </p>
          )}
        </div>
      )}
    </Dialog>
  );
}

function StatusPill({ status }: { status: UserRow['status'] }) {
  const classes =
    status === 'active'
      ? 'bg-green-100 text-green-800'
      : status === 'suspended'
        ? 'bg-red-100 text-red-800'
        : 'bg-zinc-100 text-zinc-700';
  return (
    <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium ${classes}`}>
      {status}
    </span>
  );
}

function PlatformPill({ platform }: { platform: UserRow['license_platform'] }) {
  if (!platform) {
    return <span className="text-xs text-muted-foreground">—</span>;
  }
  const classes =
    platform === 'android'
      ? 'bg-emerald-100 text-emerald-800'
      : platform === 'windows'
        ? 'bg-sky-100 text-sky-800'
        : platform === 'ios' || platform === 'macos'
          ? 'bg-zinc-100 text-zinc-800'
          : 'bg-amber-100 text-amber-800';
  return (
    <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium capitalize ${classes}`}>
      {platform}
    </span>
  );
}

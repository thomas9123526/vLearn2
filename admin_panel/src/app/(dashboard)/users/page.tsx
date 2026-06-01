'use client';

import { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Ban, ChevronDown, Eye, KeyRound, RotateCcw, Search } from 'lucide-react';
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

interface UserDetail extends UserRow {
  avatar_url: string | null;
  avatar_emoji: string;
  native_language: string;
  ui_language: string;
  active_theme: string;
  onboarding_done: boolean;
  last_active_date: string | null;
  network_stats: {
    android_bytes_uploaded: number;
    android_bytes_downloaded: number;
    windows_bytes_uploaded: number;
    windows_bytes_downloaded: number;
  };
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
  const [detailUserId, setDetailUserId] = useState<string | null>(null);

  const { data, isLoading } = useQuery<UserListResp>({
    queryKey: ['admin-users', q, status],
    queryFn: () => {
      const params = new URLSearchParams();
      if (q) params.set('q', q);
      if (status) params.set('status', status);
      return api<UserListResp>(`/admin/users?${params.toString()}`);
    },
  });

  const { data: licenseEnabled } = useQuery<boolean>({
    queryKey: ['admin-config-license-enabled'],
    queryFn: async () => {
      const all = await api<Array<{ key: string; value: unknown }>>('/admin/config');
      const row = all.find((e) => e.key === 'license.enabled');
      return row?.value === true;
    },
  });
  const showLicense = licenseEnabled ?? false;

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
              <th className="px-4 py-2 text-left font-medium">Name</th>
              <th className="px-4 py-2 text-left font-medium">Status</th>
              {showLicense && (
                <>
                  <th className="px-4 py-2 text-left font-medium">Platform</th>
                  <th className="px-4 py-2 text-left font-medium">License</th>
                </>
              )}
              <th className="px-4 py-2 text-right font-medium">Streak</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(data?.items ?? []).map((u) => (
              <tr key={u.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2">{u.display_name}</td>
                <td className="px-4 py-2">
                  <StatusPill status={u.status} />
                  {u.suspended_reason && (
                    <span className="ml-2 text-xs text-muted-foreground">{u.suspended_reason}</span>
                  )}
                </td>
                {showLicense && (
                  <>
                    <td className="px-4 py-2">
                      <PlatformPill platform={u.license_platform} />
                    </td>
                    <td className="px-4 py-2">
                      <LicensePill validUntil={u.license_valid_until} />
                    </td>
                  </>
                )}
                <td className="px-4 py-2 text-right tabular-nums">{u.streak_days}</td>
                <td className="px-4 py-2 text-right">
                  <ActionsMenu
                    user={u}
                    canSuspend={canSuspend}
                    canResetPassword={canResetPassword}
                    onViewDetails={() => setDetailUserId(u.id)}
                    onResetPassword={() => setResetTarget(u)}
                    suspend={suspend}
                    restore={restore}
                  />
                </td>
              </tr>
            ))}
            {(data?.items ?? []).length === 0 && !isLoading && (
              <tr>
                <td colSpan={showLicense ? 6 : 4} className="px-4 py-6 text-center text-muted-foreground">
                  No users.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>

      <ResetPasswordDialog target={resetTarget} onClose={() => setResetTarget(null)} />
      <UserDetailsModal userId={detailUserId} onClose={() => setDetailUserId(null)} />
    </div>
  );
}

// ─── Actions dropdown ────────────────────────────────────────────────────────

function ActionsMenu({
  user,
  canSuspend,
  canResetPassword,
  onViewDetails,
  onResetPassword,
  suspend,
  restore,
}: {
  user: UserRow;
  canSuspend: boolean;
  canResetPassword: boolean;
  onViewDetails: () => void;
  onResetPassword: () => void;
  suspend: { mutate: (args: { id: string; reason: string }) => void };
  restore: { mutate: (id: string) => void };
}) {
  const [open, setOpen] = useState(false);
  const [pos, setPos] = useState<{ top: number; left: number } | null>(null);
  const btnRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function handler(e: MouseEvent) {
      if (
        menuRef.current && !menuRef.current.contains(e.target as Node) &&
        btnRef.current && !btnRef.current.contains(e.target as Node)
      ) setOpen(false);
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  function handleToggle() {
    if (!open && btnRef.current) {
      const r = btnRef.current.getBoundingClientRect();
      setPos({ top: r.bottom + 4, left: r.right - 176 }); // 176px = w-44
    }
    setOpen((v) => !v);
  }

  return (
    <div className="relative inline-block">
      <Button ref={btnRef} size="sm" variant="outline" onClick={handleToggle}>
        Actions <ChevronDown className="ml-1 h-3 w-3" />
      </Button>
      {open && pos && createPortal(
        <div
          ref={menuRef}
          style={{ position: 'fixed', top: pos.top, left: pos.left, zIndex: 9999 }}
          className="w-44 rounded-md border border-border bg-background shadow-md"
        >
          <MenuItem icon={<Eye className="h-4 w-4" />} onClick={() => { setOpen(false); onViewDetails(); }}>
            View details
          </MenuItem>
          {canResetPassword && user.status !== 'deleted' && (
            <MenuItem icon={<KeyRound className="h-4 w-4" />} onClick={() => { setOpen(false); onResetPassword(); }}>
              Reset password
            </MenuItem>
          )}
          {canSuspend && user.status === 'active' && (
            <MenuItem
              icon={<Ban className="h-4 w-4" />}
              danger
              onClick={() => {
                setOpen(false);
                const reason = prompt('Reason for suspension?') ?? '';
                if (reason !== null) suspend.mutate({ id: user.id, reason });
              }}
            >
              Block
            </MenuItem>
          )}
          {canSuspend && user.status === 'suspended' && (
            <MenuItem icon={<RotateCcw className="h-4 w-4" />} onClick={() => { setOpen(false); restore.mutate(user.id); }}>
              Restore
            </MenuItem>
          )}
        </div>,
        document.body,
      )}
    </div>
  );
}

function MenuItem({
  icon,
  children,
  danger,
  onClick,
}: {
  icon: React.ReactNode;
  children: React.ReactNode;
  danger?: boolean;
  onClick: () => void;
}) {
  return (
    <button
      className={`flex w-full items-center gap-2 px-3 py-2 text-left text-sm hover:bg-muted ${danger ? 'text-destructive' : ''}`}
      onClick={onClick}
    >
      {icon}
      {children}
    </button>
  );
}

// ─── User details modal ──────────────────────────────────────────────────────

function UserDetailsModal({ userId, onClose }: { userId: string | null; onClose: () => void }) {
  const { data, isLoading } = useQuery<UserDetail>({
    queryKey: ['admin-user-detail', userId],
    queryFn: () => api<UserDetail>(`/admin/users/${userId}`),
    enabled: !!userId,
  });

  return (
    <Dialog
      open={!!userId}
      onClose={onClose}
      title="User details"
      size="lg"
      footer={<Button onClick={onClose}>Close</Button>}
    >
      {isLoading || !data ? (
        <p className="text-sm text-muted-foreground">Loading…</p>
      ) : (
        <div className="space-y-5 text-sm">
          {/* ── Avatar ── */}
          <div className="flex items-center gap-3">
            {data.avatar_url ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={data.avatar_url}
                alt={data.display_name}
                className="h-16 w-16 rounded-full object-cover border border-border"
              />
            ) : (
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-muted text-3xl border border-border">
                {data.avatar_emoji}
              </div>
            )}
            <div>
              <p className="font-medium">{data.display_name}</p>
              <p className="text-xs text-muted-foreground">{data.email}</p>
            </div>
          </div>

          {/* ── Identity ── */}
          <Section title="Identity">
            <Row label="ID"         value={data.id} mono />
            <Row label="Email"      value={data.email} />
            <Row label="Name"       value={data.display_name} />
            <Row label="Status"     value={<StatusPill status={data.status} />} />
            {data.suspended_reason && (
              <Row label="Suspend reason" value={data.suspended_reason} />
            )}
            {data.suspended_until && (
              <Row label="Suspended until" value={new Date(data.suspended_until).toLocaleString()} />
            )}
            <Row label="Joined" value={new Date(data.created_at).toLocaleString()} />
            {data.last_active_date && (
              <Row label="Last active" value={new Date(data.last_active_date).toLocaleDateString()} />
            )}
          </Section>

          {/* ── Progress ── */}
          <Section title="Progress">
            <Row label="Level"      value={String(data.current_level)} />
            <Row label="XP total"   value={data.xp_total.toLocaleString()} />
            <Row label="Streak"     value={`${data.streak_days} days`} />
            <Row label="Onboarding" value={data.onboarding_done ? 'Complete' : 'Pending'} />
          </Section>

          {/* ── Preferences ── */}
          <Section title="Preferences">
            <Row label="Native language" value={data.native_language} />
            <Row label="UI language"     value={data.ui_language} />
            <Row label="Theme"           value={data.active_theme} />
          </Section>

          {/* ── License ── */}
          <Section title="License">
            <Row label="Platform"     value={<PlatformPill platform={data.license_platform} />} />
            <Row label="Valid until"  value={data.license_valid_until ? new Date(data.license_valid_until).toLocaleDateString() : '—'} />
          </Section>

          {/* ── Network traffic ── */}
          <Section title="Network traffic">
            <Row label="Bytes uploaded (Android)"   value={fmtBytes(data.network_stats.android_bytes_uploaded)} />
            <Row label="Bytes downloaded (Android)" value={fmtBytes(data.network_stats.android_bytes_downloaded)} />
            <Row label="Bytes uploaded (Windows)"   value={fmtBytes(data.network_stats.windows_bytes_uploaded)} />
            <Row label="Bytes downloaded (Windows)" value={fmtBytes(data.network_stats.windows_bytes_downloaded)} />
          </Section>
        </div>
      )}
    </Dialog>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">{title}</p>
      <div className="rounded-md border border-border divide-y divide-border">{children}</div>
    </div>
  );
}

function Row({ label, value, mono }: { label: string; value: React.ReactNode; mono?: boolean }) {
  return (
    <div className="flex items-start gap-4 px-3 py-2">
      <span className="w-40 shrink-0 text-muted-foreground">{label}</span>
      <span className={mono ? 'font-mono text-xs break-all' : ''}>{value}</span>
    </div>
  );
}

function fmtBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  if (bytes < 1_024) return `${bytes} B`;
  if (bytes < 1_048_576) return `${(bytes / 1_024).toFixed(1)} KB`;
  if (bytes < 1_073_741_824) return `${(bytes / 1_048_576).toFixed(2)} MB`;
  return `${(bytes / 1_073_741_824).toFixed(2)} GB`;
}

// ─── Reset password dialog ───────────────────────────────────────────────────

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
    onError: (e: Error) => setError(e.message || 'Reset failed. Please try again.'),
  });

  const targetId = target?.id ?? null;

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
          <Button onClick={() => { setPassword(DEFAULT_RESET_PASSWORD); setConfirm(DEFAULT_RESET_PASSWORD); setError(null); setDone(false); onClose(); }}>
            Close
          </Button>
        ) : (
          <>
            <Button variant="outline" onClick={() => { setPassword(DEFAULT_RESET_PASSWORD); setConfirm(DEFAULT_RESET_PASSWORD); setError(null); onClose(); }} disabled={submit.isPending}>
              Cancel
            </Button>
            <Button
              onClick={() => {
                setError(null);
                if (password.length < 6) { setError('Password must be at least 6 characters.'); return; }
                if (password !== confirm) { setError('Passwords do not match.'); return; }
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
          Tell the user their new password through a channel they trust (phone, in-person, secure messenger).
          It is <strong>not</strong> shown again here.
        </p>
      ) : (
        <div className="space-y-3">
          <div className="space-y-1">
            <Label htmlFor="reset-pw">New password</Label>
            <Input id="reset-pw" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Min 6 characters" autoComplete="new-password" />
          </div>
          <div className="space-y-1">
            <Label htmlFor="reset-pw2">Confirm</Label>
            <Input id="reset-pw2" type="password" value={confirm} onChange={(e) => setConfirm(e.target.value)} autoComplete="new-password" />
          </div>
          {error && (
            <p className="rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>
          )}
        </div>
      )}
    </Dialog>
  );
}

// ─── Pill components ─────────────────────────────────────────────────────────

function StatusPill({ status }: { status: UserRow['status'] }) {
  const classes =
    status === 'active' ? 'bg-green-100 text-green-800' :
    status === 'suspended' ? 'bg-red-100 text-red-800' :
    'bg-zinc-100 text-zinc-700';
  return <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium ${classes}`}>{status}</span>;
}

function LicensePill({ validUntil }: { validUntil: string | null }) {
  if (!validUntil) return <span className="text-xs text-muted-foreground">Not activated</span>;
  const daysLeft = Math.ceil((new Date(validUntil).getTime() - Date.now()) / 86_400_000);
  if (daysLeft < 0) return <span className="inline-flex rounded px-2 py-0.5 text-xs font-medium bg-red-100 text-red-800">Expired</span>;
  if (daysLeft > 10_000) return <span className="inline-flex rounded px-2 py-0.5 text-xs font-medium bg-violet-100 text-violet-800">Permanent</span>;
  const tone = daysLeft <= 7 ? 'bg-amber-100 text-amber-800' : 'bg-green-100 text-green-800';
  return <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium ${tone}`}>Active · {daysLeft}d</span>;
}

function PlatformPill({ platform }: { platform: UserRow['license_platform'] }) {
  if (!platform) return <span className="text-xs text-muted-foreground">—</span>;
  const classes =
    platform === 'android' ? 'bg-emerald-100 text-emerald-800' :
    platform === 'windows' ? 'bg-sky-100 text-sky-800' :
    platform === 'ios' || platform === 'macos' ? 'bg-zinc-100 text-zinc-800' :
    'bg-amber-100 text-amber-800';
  return <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium capitalize ${classes}`}>{platform}</span>;
}

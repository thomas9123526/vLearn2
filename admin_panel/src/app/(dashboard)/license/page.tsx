'use client';

// Scaffolding for the License feature — full architecture lives in
// docs/0525/17_license_plan.md. This page currently reads/writes the
// three license.* keys from vl_app_config; it does NOT yet generate
// or revoke licenses. The native machine-ID libraries and the
// KeyGenerator GUI are tracked separately.

import { useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { api } from '@/lib/api';
import { usePermission } from '@/hooks/use-permission';

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

const LICENSE_KEYS = ['license.enabled', 'license.mode', 'license.public_pem'] as const;

export default function LicensePage() {
  const canEdit = usePermission('config.edit');
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<ConfigEntry[]>({
    queryKey: ['admin-config-license'],
    queryFn: async () => {
      const all = await api<ConfigEntry[]>('/admin/config');
      return all.filter((e) => LICENSE_KEYS.includes(e.key as typeof LICENSE_KEYS[number]));
    },
  });

  const update = useMutation({
    mutationFn: ({ key, value }: { key: string; value: unknown }) =>
      api(`/admin/config/${key}`, { method: 'PATCH', body: { value } }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-config-license'] }),
  });

  const byKey = new Map<string, ConfigEntry>((data ?? []).map((e) => [e.key, e]));
  const enabled = (byKey.get('license.enabled')?.value as boolean | undefined) ?? false;
  const mode = (byKey.get('license.mode')?.value as string | undefined) ?? 'permanent';
  const pem = (byKey.get('license.public_pem')?.value as string | undefined) ?? '';

  const [pemDraft, setPemDraft] = useState('');
  useEffect(() => setPemDraft(pem), [pem]);

  if (isLoading) return <p className="text-sm text-muted-foreground">Loading…</p>;

  return (
    <div className="space-y-4 max-w-2xl">
      <div>
        <h1 className="text-2xl font-semibold">License</h1>
        <p className="text-sm text-muted-foreground">
          Toggle licensing for the Flutter app and configure the verification chain.
          When disabled, every user is licensed permanently and the License item is
          hidden from the app's Settings screen.
        </p>
      </div>

      <Card className="p-4 space-y-3">
        <label className="flex items-center gap-3 cursor-pointer select-none">
          <input
            type="checkbox"
            checked={enabled}
            disabled={!canEdit || update.isPending}
            onChange={(e) =>
              update.mutate({ key: 'license.enabled', value: e.target.checked })
            }
            className="h-4 w-4"
          />
          <span className="font-medium">Enable License</span>
        </label>
        <p className="text-xs text-muted-foreground pl-7">
          Off &rarr; simple mode: app users are permanently licensed.<br />
          On &rarr; app shows License item in Settings; verifies against the Leaf CA below.
        </p>
      </Card>

      <Card className="p-4 space-y-3" aria-disabled={!enabled}>
        <div className={enabled ? '' : 'opacity-50 pointer-events-none'}>
          <p className="font-medium mb-2">License mode</p>
          <div className="space-y-2">
            {(['period', 'permanent'] as const).map((m) => (
              <label key={m} className="flex items-center gap-3 cursor-pointer">
                <input
                  type="radio"
                  name="license-mode"
                  checked={mode === m}
                  disabled={!canEdit || update.isPending}
                  onChange={() => update.mutate({ key: 'license.mode', value: m })}
                />
                <span className="text-sm">
                  {m === 'period'
                    ? 'Period — license expires after N days (set per cert by KeyGenerator)'
                    : 'Permanent — issued for 100 years; same verification path'}
                </span>
              </label>
            ))}
          </div>
        </div>
      </Card>

      <Card className="p-4 space-y-3" aria-disabled={!enabled}>
        <div className={enabled ? '' : 'opacity-50 pointer-events-none'}>
          <p className="font-medium mb-2">Leaf CA public key (PEM)</p>
          <p className="text-xs text-muted-foreground mb-2">
            Used by the backend to verify license certs uploaded by the app.
            Empty until the Leaf CA is provisioned from the datamanage tool.
          </p>
          <textarea
            value={pemDraft}
            disabled={!canEdit || update.isPending}
            onChange={(e) => setPemDraft(e.target.value)}
            rows={8}
            className="w-full font-mono text-xs p-2 border rounded"
            placeholder="-----BEGIN PUBLIC KEY-----&#10;…&#10;-----END PUBLIC KEY-----"
          />
          <div className="mt-2 flex gap-2">
            <Button
              size="sm"
              disabled={!canEdit || update.isPending || pemDraft === pem}
              onClick={() =>
                update.mutate({ key: 'license.public_pem', value: pemDraft })
              }
            >
              Save PEM
            </Button>
            <Button
              size="sm"
              variant="outline"
              disabled={pemDraft === pem}
              onClick={() => setPemDraft(pem)}
            >
              Reset
            </Button>
          </div>
        </div>
      </Card>

      <Card className="p-4 bg-muted/20">
        <p className="text-xs">
          <strong>Heads up:</strong> license generation, the per-platform machine-ID
          libraries (AndroidDevIDLib.aar, WindowsDevIDLib.dll), and the
          KeyGenerator GUI are tracked under{' '}
          <code>docs/0525/17_license_plan.md</code>. The current verify endpoint
          (POST /license/verify) returns a stub permanent license for any
          well-formed request — replace it with the real X.509 verifier before
          flipping Enable on in production.
        </p>
      </Card>
    </div>
  );
}

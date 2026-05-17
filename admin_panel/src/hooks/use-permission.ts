'use client';

import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';
import { useCurrentUser } from './use-current-user';

/**
 * Returns `true` if the current admin holds the given permission key.
 *
 * Superadmins always return true (their JWT carries `permissions: ['*']`).
 * Sub-admin permissions are fetched from `GET /admin/admins/me/permissions`
 * once per session and cached. Server-side enforcement remains authoritative;
 * this hook only controls UI hiding (UX, not security).
 */
export function usePermission(key: string): boolean {
  const user = useCurrentUser();
  const { data } = useQuery<string[]>({
    queryKey: ['my-permissions', user?.sub],
    queryFn: () => api<string[]>('/admin/admins/me/permissions'),
    enabled: !!user && user.role === 'admin',
    staleTime: 5 * 60_000,
  });

  if (!user) return false;
  if (user.role === 'superadmin') return true;
  if (user.role !== 'admin') return false;
  return data?.includes(key) ?? false;
}

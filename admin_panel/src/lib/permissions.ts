'use client';

import { useQuery } from '@tanstack/react-query';
import { api } from './api';

export interface PermissionDef {
  key: string;
  category: 'content' | 'prompts' | 'users' | 'analytics' | 'system' | 'admin';
  description: string;
  grantable_to_subadmin: boolean;
  implies?: string[];
}

/**
 * Mirrors the backend's PERMISSION_CATALOG. Fetched once at app boot and
 * cached for 5 minutes — it's a stable enum that rarely changes.
 */
export function usePermissionCatalog() {
  return useQuery<PermissionDef[]>({
    queryKey: ['permission-catalog'],
    queryFn: () => api<PermissionDef[]>('/admin/admins/catalog'),
    staleTime: 5 * 60_000,
  });
}

'use client';

const ACCESS_KEY = 'vlearn2.admin.access';
const REFRESH_KEY = 'vlearn2.admin.refresh';

/**
 * Token store. `sessionStorage` is used here as a deliberate trade-off
 * documented in todoList/0517_v2/02_admin_panel_nextjs.md §2.11.2: an
 * admin-only tool with sessionStorage is simpler than the httpOnly-cookie
 * BFF dance and the XSS-risk surface is the same as the rest of the app
 * (no untrusted iframes, no user-generated HTML in the admin panel).
 *
 * Swap to httpOnly cookies later if compliance ever demands it.
 */
export const tokenStore = {
  get access(): string | null {
    if (typeof window === 'undefined') return null;
    return window.sessionStorage.getItem(ACCESS_KEY);
  },
  get refresh(): string | null {
    if (typeof window === 'undefined') return null;
    return window.sessionStorage.getItem(REFRESH_KEY);
  },
  set(access: string, refresh: string) {
    if (typeof window === 'undefined') return;
    window.sessionStorage.setItem(ACCESS_KEY, access);
    window.sessionStorage.setItem(REFRESH_KEY, refresh);
  },
  clear() {
    if (typeof window === 'undefined') return;
    window.sessionStorage.removeItem(ACCESS_KEY);
    window.sessionStorage.removeItem(REFRESH_KEY);
  },
};

export interface JwtClaims {
  sub: string;
  email: string;
  role: 'user' | 'admin' | 'superadmin';
  permissions?: string[];
  exp: number;
}

export function decodeJwt(token: string): JwtClaims | null {
  try {
    const [, payload] = token.split('.');
    if (!payload) return null;
    const padded = payload + '='.repeat((4 - (payload.length % 4)) % 4);
    const json = atob(padded.replace(/-/g, '+').replace(/_/g, '/'));
    return JSON.parse(json) as JwtClaims;
  } catch {
    return null;
  }
}

export function currentClaims(): JwtClaims | null {
  const tok = tokenStore.access;
  return tok ? decodeJwt(tok) : null;
}

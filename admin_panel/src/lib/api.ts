'use client';

import { env } from './env';
import { tokenStore } from './auth';

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public body?: unknown,
  ) {
    super(message);
  }
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';
  body?: unknown;
  headers?: Record<string, string>;
  /** When true (default), retry once with a refreshed token on 401. */
  retryOn401?: boolean;
  /** Send as multipart/form-data. `body` must be a `FormData`. */
  multipart?: boolean;
}

async function refresh(): Promise<boolean> {
  const tok = tokenStore.refresh;
  if (!tok) return false;
  try {
    const res = await fetch(`${env.NEXT_PUBLIC_API_BASE_URL}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: tok }),
    });
    if (!res.ok) return false;
    const data = (await res.json()) as {
      accessToken: string;
      refreshToken: string;
    };
    tokenStore.set(data.accessToken, data.refreshToken);
    return true;
  } catch {
    return false;
  }
}

export async function api<T = unknown>(
  path: string,
  opts: RequestOptions = {},
): Promise<T> {
  const url = `${env.NEXT_PUBLIC_API_BASE_URL}${path}`;
  const headers: Record<string, string> = { ...opts.headers };
  const access = tokenStore.access;
  if (access) headers.Authorization = `Bearer ${access}`;
  if (!opts.multipart) {
    headers['Content-Type'] ??= 'application/json';
  }

  const res = await fetch(url, {
    method: opts.method ?? 'GET',
    headers,
    body: opts.multipart
      ? (opts.body as BodyInit)
      : opts.body !== undefined
        ? JSON.stringify(opts.body)
        : undefined,
  });

  if (res.status === 401 && (opts.retryOn401 ?? true)) {
    const ok = await refresh();
    if (ok) return api<T>(path, { ...opts, retryOn401: false });
    tokenStore.clear();
    throw new ApiError(401, 'Unauthorized');
  }

  if (!res.ok) {
    let body: unknown;
    try {
      body = await res.json();
    } catch {
      // not json
    }
    throw new ApiError(res.status, res.statusText, body);
  }

  if (res.status === 204) return undefined as unknown as T;
  return (await res.json()) as T;
}

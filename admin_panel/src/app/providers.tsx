'use client';

// Top-level client-side provider tree. Currently only React Query, but new
// global contexts (theme, locale, feature flags) should slot in here so the
// whole app — including (auth) and (dashboard) groups — shares them.
//
// useState(() => ...) over a module-scope singleton means HMR replaces the
// QueryClient cleanly during dev; the production build creates a single
// instance per browser session.

import { useState, type ReactNode } from 'react';
import { QueryClientProvider } from '@tanstack/react-query';
import { makeQueryClient } from '@/lib/query-client';

export function Providers({ children }: { children: ReactNode }) {
  const [client] = useState(() => makeQueryClient());
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>;
}

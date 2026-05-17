'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import {
  LayoutDashboard,
  BookOpen,
  Users,
  Newspaper,
  Settings,
  ScrollText,
  ShieldCheck,
  Trophy,
  LogOut,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { tokenStore, currentClaims } from '@/lib/auth';
import { useCurrentUser } from '@/hooks/use-current-user';

const NAV = [
  { href: '/', label: 'Dashboard', icon: LayoutDashboard, perm: null },
  { href: '/scenarios', label: 'Scenarios', icon: BookOpen, perm: 'scenarios.view' },
  { href: '/users', label: 'Users', icon: Users, perm: 'users.view' },
  { href: '/news', label: 'News', icon: Newspaper, perm: 'news.view' },
  { href: '/leaderboard', label: 'Leaderboard', icon: Trophy, perm: 'leaderboard.view' },
  { href: '/audit', label: 'Audit log', icon: ScrollText, perm: 'audit.view' },
  { href: '/admins', label: 'Admins', icon: ShieldCheck, perm: 'admins.view' },
  { href: '/config', label: 'Config flags', icon: Settings, perm: 'config.view' },
  { href: '/settings', label: 'Settings', icon: Settings, perm: null },
] as const;

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const user = useCurrentUser();

  useEffect(() => {
    // Hydration-safe auth gate.
    const claims = currentClaims();
    if (!claims) {
      router.replace('/signin');
      return;
    }
    if (claims.role !== 'admin' && claims.role !== 'superadmin') {
      router.replace('/signin');
    }
  }, [router]);

  function signOut() {
    tokenStore.clear();
    router.replace('/signin');
  }

  if (!user) return null;

  return (
    <div className="flex min-h-screen bg-muted">
      <aside className="hidden w-60 shrink-0 border-r border-border bg-card md:flex md:flex-col">
        <div className="border-b border-border px-5 py-4">
          <div className="text-sm font-semibold">vLearn2 admin</div>
          <div className="text-xs text-muted-foreground">{user.email}</div>
        </div>
        <nav className="flex-1 space-y-1 p-2">
          {NAV.map((item) => {
            const active = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center gap-2 rounded-md px-3 py-2 text-sm transition-colors',
                  active
                    ? 'bg-primary text-primary-foreground'
                    : 'text-foreground hover:bg-muted',
                )}
              >
                <item.icon className="h-4 w-4" />
                {item.label}
              </Link>
            );
          })}
        </nav>
        <div className="border-t border-border p-2">
          <button
            onClick={signOut}
            className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm hover:bg-muted"
          >
            <LogOut className="h-4 w-4" />
            Sign out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-x-hidden">
        <header className="flex h-14 items-center justify-between border-b border-border bg-card px-6">
          <div className="text-sm font-medium capitalize">
            {pathname === '/' ? 'Dashboard' : pathname.slice(1).replaceAll('/', ' / ')}
          </div>
          <div className="text-xs text-muted-foreground">
            Role: <span className="font-medium">{user.role}</span>
          </div>
        </header>
        <div className="p-6">{children}</div>
      </main>
    </div>
  );
}

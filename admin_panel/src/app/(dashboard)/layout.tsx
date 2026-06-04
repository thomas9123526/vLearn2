'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { useTranslations } from 'next-intl';
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
  Sparkles,
  MessageSquareCode,
  ListTree,
  KeyRound,
  BarChart2,
  MessageCircleWarning,
  Variable,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { tokenStore, currentClaims } from '@/lib/auth';
import { useCurrentUser } from '@/hooks/use-current-user';
import { LanguageSwitcher } from '@/components/LanguageSwitcher';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const user = useCurrentUser();
  const t = useTranslations('nav');
  const tAuth = useTranslations('auth');

  const NAV = [
    { href: '/', label: t('dashboard'), icon: LayoutDashboard, perm: null },
    { href: '/teachers', label: t('teachers'), icon: Sparkles, perm: 'personas.edit' },
    { href: '/prompt-templates', label: t('prompts'), icon: MessageSquareCode, perm: 'prompts.view' },
    { href: '/prompt-vars', label: t('variables'), icon: Variable, perm: 'prompts.view' },
    { href: '/scenarios', label: t('scenarios'), icon: BookOpen, perm: 'scenarios.view' },
    { href: '/categories', label: t('categories'), icon: ListTree, perm: 'categories.view' },
    { href: '/users', label: t('users'), icon: Users, perm: 'users.view' },
    { href: '/news', label: t('news'), icon: Newspaper, perm: 'news.view' },
    { href: '/leaderboard', label: t('leaderboard'), icon: Trophy, perm: 'leaderboard.view' },
    { href: '/usage', label: t('usage'), icon: BarChart2, perm: 'analytics.view' },
    { href: '/reports', label: t('reports'), icon: MessageCircleWarning, perm: 'analytics.view' },
    { href: '/audit', label: t('auditLog'), icon: ScrollText, perm: 'audit.view' },
    { href: '/admins', label: t('admins'), icon: ShieldCheck, perm: 'admins.view' },
    { href: '/config', label: t('configFlags'), icon: Settings, perm: 'config.view' },
    { href: '/license', label: t('license'), icon: KeyRound, perm: 'config.view' },
    { href: '/settings', label: t('settings'), icon: Settings, perm: null },
  ] as const;

  useEffect(() => {
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
            {tAuth('signOut')}
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-x-hidden">
        <header className="flex h-14 items-center justify-between border-b border-border bg-card px-6">
          <div className="text-sm font-medium capitalize">
            {pathname === '/' ? t('dashboard') : pathname.slice(1).split('/').join(' / ')}
          </div>
          <div className="flex items-center gap-3">
            <LanguageSwitcher />
            <div className="text-xs text-muted-foreground">
              Role: <span className="font-medium">{user.role}</span>
            </div>
          </div>
        </header>
        <div className="p-6">{children}</div>
      </main>
    </div>
  );
}

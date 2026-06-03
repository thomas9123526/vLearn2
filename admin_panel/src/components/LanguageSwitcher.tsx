'use client';

import { useRouter } from 'next/navigation';
import { useLocale, useTranslations } from 'next-intl';
import { Globe } from 'lucide-react';
import { cn } from '@/lib/utils';

const LOCALES = [
  { code: 'en', label: 'English' },
  { code: 'zh', label: '中文' },
  { code: 'ru', label: 'Русский' },
  { code: 'ko', label: '한국어' },
] as const;

export function LanguageSwitcher({ className }: { className?: string }) {
  const router = useRouter();
  const locale = useLocale();
  const t = useTranslations('common');

  function switchLocale(code: string) {
    document.cookie = `NEXT_LOCALE=${code}; path=/; max-age=31536000; SameSite=Lax`;
    router.refresh();
  }

  return (
    <div className={cn('relative group', className)}>
      <button
        className="flex items-center gap-1.5 rounded-md px-2 py-1.5 text-sm text-foreground hover:bg-muted transition-colors"
        title={t('selectLanguage')}
      >
        <Globe className="h-4 w-4" />
        <span className="hidden sm:inline">{LOCALES.find((l) => l.code === locale)?.label ?? 'EN'}</span>
      </button>
      <div className="absolute right-0 top-full z-50 mt-1 hidden min-w-[120px] rounded-md border border-border bg-card shadow-md group-focus-within:block group-hover:block">
        {LOCALES.map((l) => (
          <button
            key={l.code}
            onClick={() => switchLocale(l.code)}
            className={cn(
              'flex w-full items-center px-3 py-2 text-sm transition-colors hover:bg-muted',
              l.code === locale ? 'font-semibold text-primary' : 'text-foreground',
            )}
          >
            {l.label}
          </button>
        ))}
      </div>
    </div>
  );
}

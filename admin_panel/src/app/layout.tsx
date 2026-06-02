import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { NextIntlClientProvider } from 'next-intl';
import { Providers } from './providers';
import './globals.css';

export const metadata: Metadata = {
  title: 'vLearn2 admin',
  description: 'Manage scenarios, users, leaderboards, and config',
};

const SUPPORTED_LOCALES = ['en', 'zh', 'ru', 'ko'] as const;
type Locale = (typeof SUPPORTED_LOCALES)[number];

async function getMessages(locale: Locale) {
  return (await import(`../../messages/${locale}.json`)).default;
}

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const cookieStore = cookies();
  const raw = cookieStore.get('NEXT_LOCALE')?.value ?? 'en';
  const locale: Locale = (SUPPORTED_LOCALES as readonly string[]).includes(raw)
    ? (raw as Locale)
    : 'en';
  const messages = await getMessages(locale);

  return (
    <html lang={locale}>
      <body>
        <NextIntlClientProvider locale={locale} messages={messages}>
          <Providers>{children}</Providers>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}

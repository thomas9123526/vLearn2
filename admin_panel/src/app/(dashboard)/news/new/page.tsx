'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';

// Slugs are lowercase alphanumerics with dashes; the backend enforces
// uniqueness but won't auto-derive from title.
const i18nText = z.object({
  en: z.string().min(1, 'English version is required'),
  ko: z.string().optional(),
  zh: z.string().optional(),
});

const schema = z.object({
  slug: z
    .string()
    .min(2)
    .max(100)
    .regex(/^[a-z0-9-]+$/, 'lowercase letters, digits, and dashes only'),
  title: i18nText,
  body: i18nText,
  summary: i18nText.partial({ en: true }).optional(),
  pinned: z.boolean().default(false),
});

type FormValues = z.infer<typeof schema>;

export default function NewNewsPostPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const {
    register,
    handleSubmit,
    formState: { isSubmitting, errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { pinned: false },
  });

  async function onSubmit(values: FormValues) {
    setError(null);
    try {
      // Backend wants `body` as an object with at least `en`. Summary is
      // optional — only send it if the user actually filled in any locale.
      const summaryFilled =
        values.summary &&
        (values.summary.en || values.summary.ko || values.summary.zh);
      await api('/admin/news', {
        method: 'POST',
        body: {
          slug: values.slug,
          title: values.title,
          body: values.body,
          summary: summaryFilled ? values.summary : undefined,
          pinned: values.pinned,
        },
      });
      router.push('/news');
    } catch (e) {
      setError((e as Error).message);
    }
  }

  return (
    <div className="mx-auto max-w-3xl space-y-4">
      <h1 className="text-2xl font-semibold">New news post</h1>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Card>
          <CardHeader>
            <CardTitle>Basics</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Field
              label="Slug"
              error={errors.slug?.message}
              hint="lowercase, dashes (e.g. winter-launch)"
            >
              <Input {...register('slug')} placeholder="welcome-update" />
            </Field>
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" {...register('pinned')} />
              Pin to the top of the news list
            </label>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Title</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Field label="English (required)" error={errors.title?.en?.message}>
              <Input {...register('title.en')} placeholder="Welcome to v1.1!" />
            </Field>
            <Field label="조선어">
              <Input {...register('title.ko')} placeholder="v1.1에 오신 것을 환영합니다!" />
            </Field>
            <Field label="中文">
              <Input {...register('title.zh')} placeholder="欢迎使用 v1.1！" />
            </Field>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Body / description</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Field label="English (required)" error={errors.body?.en?.message}>
              <textarea
                {...register('body.en')}
                rows={6}
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                placeholder="What's new, what to try, why it matters."
              />
            </Field>
            <Field label="조선어">
              <textarea
                {...register('body.ko')}
                rows={6}
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              />
            </Field>
            <Field label="中文">
              <textarea
                {...register('body.zh')}
                rows={6}
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              />
            </Field>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Summary (optional)</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <p className="text-xs text-muted-foreground">
              Short hook shown in the home strip and news list. If left blank
              the body&apos;s first line is used.
            </p>
            <Field label="English">
              <Input {...register('summary.en')} />
            </Field>
            <Field label="조선어">
              <Input {...register('summary.ko')} />
            </Field>
            <Field label="中文">
              <Input {...register('summary.zh')} />
            </Field>
          </CardContent>
        </Card>

        {error && (
          <p className="rounded-md border border-destructive bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {error}
          </p>
        )}

        <div className="flex justify-between">
          <Button type="button" variant="ghost" onClick={() => router.push('/news')}>
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Saving…' : 'Save as draft'}
          </Button>
        </div>

        <p className="text-xs text-muted-foreground">
          New posts start as drafts. Use the Publish action on the news list to
          make them visible to the app.
        </p>
      </form>
    </div>
  );
}

function Field({
  label,
  children,
  error,
  hint,
}: {
  label: string;
  children: React.ReactNode;
  error?: string;
  hint?: string;
}) {
  return (
    <div className="space-y-1">
      <Label>{label}</Label>
      {children}
      {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
      {error && <p className="text-xs text-destructive">{error}</p>}
    </div>
  );
}

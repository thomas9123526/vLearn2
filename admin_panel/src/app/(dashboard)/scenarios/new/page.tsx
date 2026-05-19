'use client';

import { useRouter } from 'next/navigation';
import { forwardRef, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';

const i18nText = z.object({
  en: z.string().min(1),
  ko: z.string().optional(),
  zh: z.string().optional(),
});

const schema = z.object({
  slug: z.string().min(2).max(100),
  category: z.enum(['travel', 'business', 'social', 'daily']),
  difficulty: z.coerce.number().int().min(1).max(5),
  title: i18nText,
  description: i18nText,
  scene_description: i18nText,
  user_role: i18nText,
  tutor_role: i18nText,
  estimated_minutes: z.coerce.number().int().min(1).max(60).default(5),
  xp_reward: z.coerce.number().int().min(0).max(1000).default(50),
});

type FormValues = z.infer<typeof schema>;

export default function NewScenarioPage() {
  const router = useRouter();
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);
  const {
    register,
    handleSubmit,
    formState: { isSubmitting, errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { category: 'daily', difficulty: 2, estimated_minutes: 5, xp_reward: 50 },
  });

  async function onSubmit(values: FormValues) {
    setError(null);
    try {
      const created = await api<{ id: string }>('/admin/scenarios', {
        method: 'POST',
        body: {
          ...values,
          objectives: [],
          key_phrases: [],
        },
      });
      if (imageFile) {
        const fd = new FormData();
        fd.append('file', imageFile);
        await api(`/admin/scenarios/${created.id}/image`, {
          method: 'POST',
          body: fd,
          multipart: true,
        });
      }
      router.replace(`/scenarios/${created.id}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create scenario');
    }
  }

  return (
    <Card className="max-w-3xl">
      <CardHeader>
        <CardTitle>New scenario</CardTitle>
      </CardHeader>
      <CardContent>
        <form className="space-y-4" onSubmit={handleSubmit(onSubmit)}>
          <Field id="slug" label="Slug (url-safe)" {...register('slug')} error={errors.slug?.message} />
          <div className="grid grid-cols-3 gap-3">
            <div>
              <Label htmlFor="category">Category</Label>
              <select
                id="category"
                className="h-9 w-full rounded-md border border-border bg-background px-2 text-sm"
                {...register('category')}
              >
                <option>travel</option>
                <option>business</option>
                <option>social</option>
                <option>daily</option>
              </select>
            </div>
            <Field id="difficulty" label="Difficulty (1-5)" type="number" {...register('difficulty')} />
            <Field id="estimated_minutes" label="Estimated minutes" type="number" {...register('estimated_minutes')} />
          </div>
          <Field id="xp_reward" label="XP reward" type="number" {...register('xp_reward')} />

          <Section title="Title">
            <Field id="title.en" label="EN" {...register('title.en')} error={errors.title?.en?.message} />
            <Field id="title.ko" label="KO (optional)" {...register('title.ko')} />
            <Field id="title.zh" label="ZH (optional)" {...register('title.zh')} />
          </Section>
          <Section title="Description">
            <Field id="description.en" label="EN" {...register('description.en')} error={errors.description?.en?.message} />
          </Section>
          <Section title="Scene description">
            <Field id="scene_description.en" label="EN" {...register('scene_description.en')} error={errors.scene_description?.en?.message} />
          </Section>
          <Section title="Roles">
            <Field id="user_role.en" label="User role (EN)" {...register('user_role.en')} error={errors.user_role?.en?.message} />
            <Field id="tutor_role.en" label="Tutor role (EN)" {...register('tutor_role.en')} error={errors.tutor_role?.en?.message} />
          </Section>

          <div>
            <Label htmlFor="image">Hero image (optional)</Label>
            <Input
              id="image"
              type="file"
              accept="image/png,image/jpeg,image/webp"
              onChange={(e) => setImageFile(e.target.files?.[0] ?? null)}
            />
            <p className="mt-1 text-xs text-muted-foreground">
              PNG / JPEG / WEBP, ≤ 5 MB. Uploaded after the scenario is created.
            </p>
          </div>

          {error && <p className="text-sm text-destructive">{error}</p>}
          <div className="flex gap-2">
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Creating…' : 'Create'}
            </Button>
            <Button type="button" variant="outline" onClick={() => router.back()}>
              Cancel
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <fieldset className="space-y-2 rounded-md border border-border p-3">
      <legend className="px-1 text-sm font-medium">{title}</legend>
      {children}
    </fieldset>
  );
}

const Field = forwardRef<
  HTMLInputElement,
  { id: string; label: string; error?: string } & React.InputHTMLAttributes<HTMLInputElement>
>(({ id, label, error, ...rest }, ref) => (
  <div className="space-y-1">
    <Label htmlFor={id}>{label}</Label>
    <Input id={id} ref={ref} {...rest} />
    {error && <p className="text-xs text-destructive">{error}</p>}
  </div>
));
Field.displayName = 'Field';

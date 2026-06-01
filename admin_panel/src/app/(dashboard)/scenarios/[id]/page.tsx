'use client';

import { forwardRef, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { api } from '@/lib/api';
import { env } from '@/lib/env';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

const i18nText = z.object({
  en: z.string().min(1),
  ko: z.string().optional(),
  zh: z.string().optional(),
});

const schema = z.object({
  slug: z.string().min(2).max(100),
  category: z.enum(['travel', 'business', 'social', 'daily']),
  title: i18nText,
  description: i18nText,
  scene_description: i18nText,
  user_role: i18nText,
  tutor_role: i18nText,
  estimated_minutes: z.coerce.number().int().min(1).max(60).default(5),
  xp_reward: z.coerce.number().int().min(0).max(1000).default(50),
});

type FormValues = z.infer<typeof schema>;

interface Scenario extends FormValues {
  id: string;
  image_url: string | null;
  background_image_url: string | null;
  status: 'draft' | 'published' | 'archived';
}

export default function EditScenarioPage({ params }: { params: { id: string } }) {
  const { id } = params;
  const router = useRouter();
  const qc = useQueryClient();
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [backgroundImageFile, setBackgroundImageFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);

  const imagePreviewUrl = useMemo(
    () => (imageFile ? URL.createObjectURL(imageFile) : null),
    [imageFile],
  );
  const backgroundImagePreviewUrl = useMemo(
    () => (backgroundImageFile ? URL.createObjectURL(backgroundImageFile) : null),
    [backgroundImageFile],
  );

  const uploadsOrigin = useMemo(() => {
    const base = env.NEXT_PUBLIC_API_BASE_URL;
    if (base.startsWith('http://') || base.startsWith('https://')) {
      try {
        const url = new URL(base);
        return `${url.origin}${url.pathname.replace(/\/api(?:\/backend)?$/, '')}`;
      } catch {
        return base.replace(/\/api(?:\/backend)?$/, '');
      }
    }
    if (typeof window !== 'undefined') {
      return `${window.location.origin}${base.replace(/\/api(?:\/backend)?$/, '')}`;
    }
    return '';
  }, []);

  const resolveUploadUrl = (url: string | null) => {
    if (!url) return null;
    if (url.startsWith('/uploads')) {
      return `${uploadsOrigin}${url}`;
    }
    return url;
  };

  useEffect(() => {
    return () => {
      if (imagePreviewUrl) URL.revokeObjectURL(imagePreviewUrl);
    };
  }, [imagePreviewUrl]);

  useEffect(() => {
    return () => {
      if (backgroundImagePreviewUrl) URL.revokeObjectURL(backgroundImagePreviewUrl);
    };
  }, [backgroundImagePreviewUrl]);

  const { data: scenario, isLoading } = useQuery<Scenario>({
    queryKey: ['admin-scenario', id],
    queryFn: () => api(`/admin/scenarios/${id}`),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { isSubmitting, errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  useEffect(() => {
    if (!scenario) return;
    reset({
      slug: scenario.slug,
      category: scenario.category,
      title: scenario.title,
      description: scenario.description,
      scene_description: scenario.scene_description,
      user_role: scenario.user_role,
      tutor_role: scenario.tutor_role,
      estimated_minutes: scenario.estimated_minutes,
      xp_reward: scenario.xp_reward,
    });
  }, [scenario, reset]);

  const save = useMutation({
    mutationFn: (values: FormValues) =>
      api(`/admin/scenarios/${id}`, {
        method: 'PATCH',
        body: values,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-scenario', id] }),
  });

  async function onSubmit(values: FormValues) {
    setError(null);
    try {
      await save.mutateAsync(values);

      if (imageFile) {
        const fd = new FormData();
        fd.append('file', imageFile);
        await api(`/admin/scenarios/${id}/image`, {
          method: 'POST',
          body: fd,
          multipart: true,
        });
      }

      if (backgroundImageFile) {
        const fd = new FormData();
        fd.append('file', backgroundImageFile);
        await api(`/admin/scenarios/${id}/background-image`, {
          method: 'POST',
          body: fd,
          multipart: true,
        });
      }

      setImageFile(null);
      setBackgroundImageFile(null);
      qc.invalidateQueries({ queryKey: ['admin-scenarios', 'admin-scenario', id] });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to save scenario');
    }
  }

  if (isLoading) return <p className="text-sm text-muted-foreground">Loading…</p>;
  if (!scenario) return <p className="text-sm text-destructive">Scenario not found.</p>;

  return (
    <div className="grid grid-cols-1 gap-6 xl:grid-cols-[2fr_1fr]">
      <Card>
        <CardHeader>
          <CardTitle>Edit scenario</CardTitle>
        </CardHeader>
        <CardContent>
          <form
            className="space-y-4"
            onSubmit={handleSubmit(onSubmit, (fieldErrors) => {
              const msg = Object.values(fieldErrors)
                .map((e) => e?.message)
                .filter(Boolean)
                .join(' ');
              setError(msg || 'Please fix the highlighted fields.');
            })}
          >
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
              <Field id="estimated_minutes" label="Estimated minutes" type="number" {...register('estimated_minutes')} />
            </div>
            <Field id="xp_reward" label="XP reward" type="number" {...register('xp_reward')} />

            <Section title="Title">
              <Field id="title.en" label="EN" {...register('title.en')} error={errors.title?.en?.message} />
              <Field id="title.ko" label="KO (optional)" {...register('title.ko')} />
              <Field id="title.zh" label="ZH (optional)" {...register('title.zh')} />
            </Section>
            <Section title="Description">
              <Field
                id="description.en"
                label="EN"
                {...register('description.en')}
                error={errors.description?.en?.message}
              />
            </Section>
            <Section title="Scene description">
              <Field
                id="scene_description.en"
                label="EN"
                {...register('scene_description.en')}
                error={errors.scene_description?.en?.message}
              />
            </Section>
            <Section title="Roles">
              <Field
                id="user_role.en"
                label="User role (EN)"
                {...register('user_role.en')}
                error={errors.user_role?.en?.message}
              />
              <Field
                id="tutor_role.en"
                label="Tutor role (EN)"
                {...register('tutor_role.en')}
                error={errors.tutor_role?.en?.message}
              />
            </Section>

            <div>
              <Label htmlFor="background_image">Scene background image (optional)</Label>
              <Input
                id="background_image"
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={(e) => setBackgroundImageFile(e.target.files?.[0] ?? null)}
              />
              <p className="mt-1 text-xs text-muted-foreground">
                Background artwork shown behind the scenario. PNG / JPEG / WEBP, ≤ 5 MB.
              </p>
              {(backgroundImagePreviewUrl || scenario.background_image_url) && (
                <div className="mt-3 rounded-lg border border-border overflow-hidden">
                  <p className="px-3 py-1 text-xs font-medium text-muted-foreground">
                    {backgroundImagePreviewUrl ? 'Selected background preview' : 'Current background image'}
                  </p>
                  <img
                    src={backgroundImagePreviewUrl ?? resolveUploadUrl(scenario.background_image_url) ?? undefined}
                    alt={backgroundImagePreviewUrl ? 'Selected background preview' : 'Current background image'}
                    className="h-40 w-full object-cover"
                  />
                </div>
              )}
            </div>

            <div>
              <Label htmlFor="image">Hero image (optional)</Label>
              <Input
                id="image"
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={(e) => setImageFile(e.target.files?.[0] ?? null)}
              />
              <p className="mt-1 text-xs text-muted-foreground">
                PNG / JPEG / WEBP, ≤ 5 MB. Uploaded after the scenario is saved.
              </p>
              {(imagePreviewUrl || scenario.image_url) && (
                <div className="mt-3 rounded-lg border border-border overflow-hidden">
                  <p className="px-3 py-1 text-xs font-medium text-muted-foreground">
                    {imagePreviewUrl ? 'Selected hero preview' : 'Current hero image'}
                  </p>
                  <img
                    src={imagePreviewUrl ?? resolveUploadUrl(scenario.image_url) ?? undefined}
                    alt={imagePreviewUrl ? 'Selected hero preview' : 'Current hero image'}
                    className="h-40 w-full object-cover"
                  />
                </div>
              )}
            </div>

            {error && <p className="text-sm text-destructive">{error}</p>}
            <div className="flex gap-2">
              <Button type="submit" disabled={isSubmitting || save.isPending}>
                {isSubmitting || save.isPending ? 'Saving…' : 'Save changes'}
              </Button>
              <Button type="button" variant="outline" onClick={() => router.push('/scenarios')}>
                Back
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Preview</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div>
              <p className="text-sm font-medium">Current images</p>
              <div className="grid gap-3 md:grid-cols-1">
                {scenario.background_image_url && (
                  <div>
                    <p className="text-xs text-muted-foreground">Scene background</p>
                    <img
                      src={scenario.background_image_url}
                      alt="Background"
                      className="mt-2 h-40 w-full rounded-lg object-cover border border-border"
                    />
                  </div>
                )}
                {scenario.image_url && (
                  <div>
                    <p className="text-xs text-muted-foreground">Hero image</p>
                    <img
                      src={scenario.image_url}
                      alt="Hero"
                      className="mt-2 h-40 w-full rounded-lg object-cover border border-border"
                    />
                  </div>
                )}
              </div>
            </div>
            <dl className="grid gap-y-2 text-sm">
              <div className="grid grid-cols-[120px_1fr] gap-2">
                <dt className="text-muted-foreground">Slug</dt>
                <dd className="font-mono text-xs">{scenario.slug}</dd>
              </div>
              <div className="grid grid-cols-[120px_1fr] gap-2">
                <dt className="text-muted-foreground">Status</dt>
                <dd className="capitalize">{scenario.status}</dd>
              </div>
            </dl>
          </div>
        </CardContent>
      </Card>
    </div>
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

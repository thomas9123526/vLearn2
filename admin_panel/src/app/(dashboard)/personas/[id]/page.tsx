'use client';

import { use, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';

/**
 * `id` comes from the dynamic route — Next 15 turns it into a Promise so it
 * has to be unwrapped with `use()` inside the client component.
 */
type RouteParams = Promise<{ id: string }>;

const schema = z.object({
  slug: z.string().min(2).max(50),
  name: z.string().min(1).max(50),
  accent: z.string().min(1).max(100),
  style: z.string().min(1).max(100),
  specialties: z.string().min(1),
  gender: z.enum(['female', 'male', 'neutral']),
  voice_id: z.string().optional(),
  rive_asset: z.string().optional(),
  gradient_from: z
    .string()
    .regex(/^#[0-9a-fA-F]{6}$/, 'Must be a 6-digit hex color'),
  gradient_to: z
    .string()
    .regex(/^#[0-9a-fA-F]{6}$/, 'Must be a 6-digit hex color'),
});

type FormValues = z.infer<typeof schema>;

interface Persona extends FormValues {
  id: string;
  image_url: string | null;
  is_active: boolean;
}

export default function EditPersonaPage({ params }: { params: RouteParams }) {
  const { id } = use(params);
  const router = useRouter();
  const qc = useQueryClient();
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);

  const { data: persona, isLoading } = useQuery<
    Persona & { specialties: string[] | string }
  >({
    queryKey: ['admin-persona', id],
    queryFn: () => api(`/admin/personas/${id}`),
  });

  const { register, handleSubmit, reset, formState: { isSubmitting, errors } } =
    useForm<FormValues>({ resolver: zodResolver(schema) });

  // Once the API response lands, reset the form to it so the user sees the
  // current values instead of blank inputs.
  useEffect(() => {
    if (!persona) return;
    reset({
      slug: persona.slug,
      name: persona.name,
      accent: persona.accent,
      style: persona.style,
      specialties: Array.isArray(persona.specialties)
        ? persona.specialties.join(', ')
        : (persona.specialties as string),
      gender: persona.gender,
      voice_id: persona.voice_id ?? '',
      rive_asset: persona.rive_asset ?? '',
      gradient_from: persona.gradient_from,
      gradient_to: persona.gradient_to,
    });
  }, [persona, reset]);

  const save = useMutation({
    mutationFn: (values: FormValues) =>
      api(`/admin/personas/${id}`, {
        method: 'PATCH',
        body: {
          ...values,
          specialties: values.specialties.split(',').map((s) => s.trim()).filter(Boolean),
        },
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-persona', id] }),
  });

  async function onSubmit(values: FormValues) {
    setError(null);
    try {
      await save.mutateAsync(values);
      if (imageFile) {
        const fd = new FormData();
        fd.append('file', imageFile);
        await api(`/admin/personas/${id}/image`, {
          method: 'POST',
          body: fd,
          multipart: true,
        });
        setImageFile(null);
      }
      qc.invalidateQueries({ queryKey: ['admin-personas'] });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to save');
    }
  }

  if (isLoading) return <p className="text-sm text-muted-foreground">Loading…</p>;
  if (!persona) return <p className="text-sm text-destructive">Tutor not found.</p>;

  return (
    <div className="grid grid-cols-1 gap-6 md:grid-cols-[2fr_1fr]">
      <Card>
        <CardHeader>
          <CardTitle>Edit “{persona.name}”</CardTitle>
        </CardHeader>
        <CardContent>
          <form className="space-y-4" onSubmit={handleSubmit(onSubmit)}>
            <div className="grid grid-cols-2 gap-3">
              <Field id="slug" label="Slug" {...register('slug')} error={errors.slug?.message} />
              <Field id="name" label="Display name" {...register('name')} error={errors.name?.message} />
              <Field id="accent" label="Accent" {...register('accent')} error={errors.accent?.message} />
              <Field id="style" label="Style" {...register('style')} error={errors.style?.message} />
            </div>
            <Field
              id="specialties"
              label="Specialties (comma-separated)"
              {...register('specialties')}
              error={errors.specialties?.message}
            />
            <div className="grid grid-cols-3 gap-3">
              <div>
                <Label htmlFor="gender">Gender</Label>
                <select
                  id="gender"
                  className="h-9 w-full rounded-md border border-border bg-background px-2 text-sm"
                  {...register('gender')}
                >
                  <option value="neutral">neutral</option>
                  <option value="female">female</option>
                  <option value="male">male</option>
                </select>
              </div>
              <Field id="voice_id" label="TTS voice id" {...register('voice_id')} />
              <Field id="rive_asset" label="Rive asset" {...register('rive_asset')} />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <Field
                id="gradient_from"
                label="Gradient from"
                {...register('gradient_from')}
                error={errors.gradient_from?.message}
              />
              <Field
                id="gradient_to"
                label="Gradient to"
                {...register('gradient_to')}
                error={errors.gradient_to?.message}
              />
            </div>

            <div>
              <Label htmlFor="image">Replace portrait image</Label>
              <Input
                id="image"
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={(e) => setImageFile(e.target.files?.[0] ?? null)}
              />
            </div>

            {error && <p className="text-sm text-destructive">{error}</p>}
            <div className="flex gap-2">
              <Button type="submit" disabled={isSubmitting || save.isPending}>
                {isSubmitting || save.isPending ? 'Saving…' : 'Save changes'}
              </Button>
              <Button type="button" variant="outline" onClick={() => router.push('/personas')}>
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
          <div
            className="aspect-square w-full rounded-lg"
            style={{
              background: `linear-gradient(135deg, ${persona.gradient_from}, ${persona.gradient_to})`,
            }}
          >
            {persona.image_url && (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={persona.image_url}
                alt={persona.name}
                className="h-full w-full rounded-lg object-cover"
              />
            )}
          </div>
          <dl className="mt-3 grid grid-cols-2 gap-y-1 text-sm">
            <dt className="text-muted-foreground">Slug</dt>
            <dd className="font-mono text-xs">{persona.slug}</dd>
            <dt className="text-muted-foreground">Status</dt>
            <dd>{persona.is_active ? 'active' : 'inactive'}</dd>
            <dt className="text-muted-foreground">Gender</dt>
            <dd className="capitalize">{persona.gender}</dd>
            <dt className="text-muted-foreground">Voice</dt>
            <dd className="font-mono text-xs">{persona.voice_id ?? '—'}</dd>
            <dt className="text-muted-foreground">Rive asset</dt>
            <dd className="font-mono text-xs">{persona.rive_asset ?? '—'}</dd>
          </dl>
        </CardContent>
      </Card>
    </div>
  );
}

const Field = ({
  id,
  label,
  error,
  ...rest
}: { id: string; label: string; error?: string } & React.InputHTMLAttributes<HTMLInputElement>) => (
  <div className="space-y-1">
    <Label htmlFor={id}>{label}</Label>
    <Input id={id} {...rest} />
    {error && <p className="text-xs text-destructive">{error}</p>}
  </div>
);

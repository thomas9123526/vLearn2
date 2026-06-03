'use client';

import { useRouter } from 'next/navigation';
import { forwardRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';

/**
 * Zod schema mirrors AdminPersonasController.CreatePersonaDto on the
 * backend. `specialties` is a comma-separated string in the form for
 * convenience and gets split into `string[]` before submit.
 */
const schema = z.object({
  slug: z.string().min(2).max(50),
  name: z.string().min(1).max(50),
  accent: z.string().min(1).max(100),
  style: z.string().min(1).max(100),
  specialties: z.string().min(1),
  gender: z.enum(['female', 'male', 'neutral']).default('neutral'),
  voice_id: z.string().optional(),
  rive_asset: z.string().optional(),
  tts_age: z.enum(['young', 'adult', 'elder', '']).optional(),
  tts_voice_sid: z.string().optional(),
  gradient_from: z
    .string()
    .regex(/^#[0-9a-fA-F]{6}$/, 'Must be a 6-digit hex color like #FF6B47'),
  gradient_to: z
    .string()
    .regex(/^#[0-9a-fA-F]{6}$/, 'Must be a 6-digit hex color like #FFB997'),
});

type FormValues = z.infer<typeof schema>;

export default function NewTeacherPage() {
  const router = useRouter();
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);

  const { data: voicesData } = useQuery<{ voices: string[] }>({
    queryKey: ['admin-tts-voices'],
    queryFn: () => api('/admin/teachers/tts/voices'),
    staleTime: Infinity,
  });
  const availableVoices = voicesData?.voices ?? [];
  const {
    register,
    handleSubmit,
    formState: { isSubmitting, errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      gender: 'neutral',
      gradient_from: '#FFB997',
      gradient_to: '#FF6B47',
    },
  });

  async function onSubmit(values: FormValues) {
    setError(null);
    try {
      const created = await api<{ id: string }>('/admin/teachers', {
        method: 'POST',
        body: {
          ...values,
          voice_id: values.voice_id?.trim() || null,
          rive_asset: values.rive_asset?.trim() || null,
          tts_age: values.tts_age?.trim() || null,
          tts_voice_sid: values.tts_voice_sid?.trim() ? parseInt(values.tts_voice_sid, 10) : null,
          specialties: values.specialties
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean),
        },
      });
      if (imageFile) {
        const fd = new FormData();
        fd.append('file', imageFile);
        await api(`/admin/teachers/${created.id}/image`, {
          method: 'POST',
          body: fd,
          multipart: true,
        });
      }
      router.replace(`/teachers/${created.id}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create persona');
    }
  }

  return (
    <Card className="max-w-2xl">
      <CardHeader>
        <CardTitle>New teacher</CardTitle>
      </CardHeader>
      <CardContent>
        <form className="space-y-4" onSubmit={handleSubmit(onSubmit)}>
          <div className="grid grid-cols-2 gap-3">
            <Field id="slug" label="Slug" {...register('slug')} error={errors.slug?.message} />
            <Field id="name" label="Display name" {...register('name')} error={errors.name?.message} />
            <Field id="accent" label="Accent" placeholder="Warm American" {...register('accent')} error={errors.accent?.message} />
            <Field id="style" label="Style" placeholder="Encouraging, patient" {...register('style')} error={errors.style?.message} />
          </div>
          <Field
            id="specialties"
            label="Specialties (comma-separated)"
            placeholder="Travel, Daily life, Beginner-friendly"
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
            <div>
              <Label htmlFor="tts_age">Voice age</Label>
              <select
                id="tts_age"
                className="h-9 w-full rounded-md border border-border bg-background px-2 text-sm"
                {...register('tts_age')}
              >
                <option value="">— unset —</option>
                <option value="young">young</option>
                <option value="adult">adult</option>
                <option value="elder">elder</option>
              </select>
            </div>
            <Field
              id="tts_voice_sid"
              label="Voice SID (direct)"
              type="number"
              min={0}
              placeholder="0"
              {...register('tts_voice_sid')}
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="voice_id">TTS voice id</Label>
              {availableVoices.length > 0 ? (
                <select
                  id="voice_id"
                  className="h-9 w-full rounded-md border border-border bg-background px-2 text-sm"
                  {...register('voice_id')}
                >
                  <option value="">— unset (use gender heuristic) —</option>
                  {availableVoices.map((v) => (
                    <option key={v} value={v}>{v}</option>
                  ))}
                </select>
              ) : (
                <Input id="voice_id" placeholder="en_VCTK-amy" {...register('voice_id')} />
              )}
              {availableVoices.length === 0 && (
                <p className="text-xs text-muted-foreground mt-1">
                  Set TTS_VOICE_IDS on the backend to enable dropdown.
                </p>
              )}
            </div>
            <Field
              id="rive_asset"
              label="Rive asset filename"
              placeholder="emo_linear.riv"
              {...register('rive_asset')}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Field
              id="gradient_from"
              label="Gradient from (hex)"
              placeholder="#FFB997"
              {...register('gradient_from')}
              error={errors.gradient_from?.message}
            />
            <Field
              id="gradient_to"
              label="Gradient to (hex)"
              placeholder="#FF6B47"
              {...register('gradient_to')}
              error={errors.gradient_to?.message}
            />
          </div>

          <div>
            <Label htmlFor="image">Portrait image (optional)</Label>
            <Input
              id="image"
              type="file"
              accept="image/png,image/jpeg,image/webp"
              onChange={(e) => setImageFile(e.target.files?.[0] ?? null)}
            />
            <p className="mt-1 text-xs text-muted-foreground">
              PNG / JPEG / WEBP, ≤ 5 MB. Uploaded after the tutor record is created.
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

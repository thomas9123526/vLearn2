'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { api, ApiError } from '@/lib/api';
import { tokenStore, decodeJwt } from '@/lib/auth';

// Mirrors the backend AdminSignupDto in
// backend/src/admin/admins/admin-auth.controller.ts.
const schema = z.object({
  email: z.string().email(),
  displayName: z.string().min(2, 'At least 2 characters').max(100),
  password: z
    .string()
    .min(12, 'At least 12 characters')
    .max(128)
    .regex(/[a-z]/, 'Must contain a lowercase letter')
    .regex(/[A-Z]/, 'Must contain an uppercase letter')
    .regex(/[0-9]/, 'Must contain a digit'),
});

type FormValues = z.infer<typeof schema>;

interface SignUpResponse {
  accessToken: string;
  refreshToken: string;
  role: 'admin' | 'superadmin' | 'user';
}

export default function SignUpPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const {
    register,
    handleSubmit,
    formState: { isSubmitting, errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  async function onSubmit(values: FormValues) {
    setError(null);
    try {
      const data = await api<SignUpResponse>('/admin/auth/signup', {
        method: 'POST',
        body: values,
      });
      const claims = decodeJwt(data.accessToken);
      if (!claims || (claims.role !== 'admin' && claims.role !== 'superadmin')) {
        setError('Signup succeeded but the account is not an admin. Contact a superadmin.');
        return;
      }
      tokenStore.set(data.accessToken, data.refreshToken);
      router.replace('/');
    } catch (e) {
      if (e instanceof ApiError) {
        if (e.status === 409) setError('That email is already registered.');
        else if (e.status === 400) setError('Check the form — one or more fields are invalid.');
        else setError(e.message);
      } else {
        setError('Network error');
      }
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-muted p-6">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>Create admin account</CardTitle>
          <CardDescription>
            The first signup becomes the <strong>superadmin</strong>. Subsequent
            signups become regular admins.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form className="space-y-4" onSubmit={handleSubmit(onSubmit)}>
            <div className="space-y-1">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                {...register('email')}
              />
              {errors.email && (
                <p className="text-xs text-destructive">{errors.email.message}</p>
              )}
            </div>
            <div className="space-y-1">
              <Label htmlFor="displayName">Display name</Label>
              <Input
                id="displayName"
                type="text"
                autoComplete="name"
                {...register('displayName')}
              />
              {errors.displayName && (
                <p className="text-xs text-destructive">{errors.displayName.message}</p>
              )}
            </div>
            <div className="space-y-1">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                autoComplete="new-password"
                {...register('password')}
              />
              <p className="text-xs text-muted-foreground">
                12+ chars, with lowercase, uppercase, and a digit.
              </p>
              {errors.password && (
                <p className="text-xs text-destructive">{errors.password.message}</p>
              )}
            </div>
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" className="w-full" disabled={isSubmitting}>
              {isSubmitting ? 'Creating account…' : 'Create account'}
            </Button>
            <p className="text-center text-sm text-muted-foreground">
              Already have an account?{' '}
              <Link href="/signin" className="font-medium text-primary hover:underline">
                Sign in
              </Link>
            </p>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}

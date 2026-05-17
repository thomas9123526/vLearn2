'use client';

import { useEffect, useState } from 'react';
import { currentClaims, type JwtClaims } from '@/lib/auth';

export function useCurrentUser() {
  const [claims, setClaims] = useState<JwtClaims | null>(null);
  useEffect(() => {
    setClaims(currentClaims());
  }, []);
  return claims;
}

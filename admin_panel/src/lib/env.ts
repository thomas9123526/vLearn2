import { z } from 'zod';

const schema = z.object({
  // Accept an absolute URL (http://host) or an origin-relative path (/vfls)
  // so the same bundle can be served behind nginx without baking the host in.
  NEXT_PUBLIC_API_BASE_URL: z
    .string()
    .refine(
      (v) => /^https?:\/\//.test(v) || v.startsWith('/'),
      'Must be an absolute http(s) URL or a path starting with "/"',
    ),
});

export const env = schema.parse({
  NEXT_PUBLIC_API_BASE_URL:
    process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000/api',
});

// We test the env schema in isolation. The top-level module reads
// process.env at import time, so we re-implement the schema here to drive
// the same validation rules without forcing a real environment.

import { z } from 'zod';

const schema = z.object({
  NEXT_PUBLIC_API_BASE_URL: z
    .string()
    .refine(
      (v) => /^https?:\/\//.test(v) || v.startsWith('/'),
      'Must be an absolute http(s) URL or a path starting with "/"',
    ),
});

describe('env schema', () => {
  it('accepts an absolute http URL', () => {
    expect(() =>
      schema.parse({ NEXT_PUBLIC_API_BASE_URL: 'http://localhost:3000/api' }),
    ).not.toThrow();
  });

  it('accepts an absolute https URL', () => {
    expect(() =>
      schema.parse({ NEXT_PUBLIC_API_BASE_URL: 'https://api.example.com/v1' }),
    ).not.toThrow();
  });

  it('accepts an origin-relative path', () => {
    expect(() =>
      schema.parse({ NEXT_PUBLIC_API_BASE_URL: '/vfls' }),
    ).not.toThrow();
  });

  it('rejects a host without scheme', () => {
    expect(() =>
      schema.parse({ NEXT_PUBLIC_API_BASE_URL: 'example.com/api' }),
    ).toThrow();
  });

  it('rejects an empty string', () => {
    expect(() =>
      schema.parse({ NEXT_PUBLIC_API_BASE_URL: '' }),
    ).toThrow();
  });
});

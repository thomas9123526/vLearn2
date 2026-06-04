/**
 * Creates real admin/user JWT tokens by hitting the actual auth endpoints.
 * Keeps test credentials separate from production data.
 */
import request from 'supertest';
import { INestApplication } from '@nestjs/common';

export const TEST_ADMIN = {
  email: 'testadmin@vlearn2.test',
  password: 'Test1234!',
  displayName: 'Test Admin',
};

export const TEST_USER = {
  email: 'testuser@vlearn2.test',
  password: 'Test1234!',
  nativeLanguage: 'zh',
};

/**
 * Ensures the test admin exists and returns its access token.
 * Safe to call multiple times — idempotent (signup ignores 409 conflicts).
 */
export async function getAdminToken(app: INestApplication): Promise<string> {
  const http = app.getHttpServer();

  // Try signup first (creates admin on first run)
  await request(http).post('/admin/auth/signup').send(TEST_ADMIN);

  // Always sign in to get a fresh token
  const res = await request(http)
    .post('/admin/auth/signin')
    .send({ email: TEST_ADMIN.email, password: TEST_ADMIN.password })
    .expect((r) => {
      if (r.status !== 200 && r.status !== 201) {
        throw new Error(`Admin signin failed: ${r.status} ${JSON.stringify(r.body)}`);
      }
    });

  return res.body.accessToken as string;
}

/**
 * Ensures a test user exists and returns its access token.
 */
export async function getUserToken(app: INestApplication): Promise<string> {
  const http = app.getHttpServer();

  await request(http).post('/auth/register').send(TEST_USER);

  const res = await request(http)
    .post('/auth/login')
    .send({ email: TEST_USER.email, password: TEST_USER.password })
    .expect((r) => {
      if (r.status !== 200 && r.status !== 201) {
        throw new Error(`User login failed: ${r.status} ${JSON.stringify(r.body)}`);
      }
    });

  return res.body.accessToken as string;
}

/** Auth header object ready to spread into supertest .set() */
export function bearer(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}` };
}

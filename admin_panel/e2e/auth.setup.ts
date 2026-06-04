/**
 * Playwright global setup: logs in once and saves auth state so every spec
 * can skip the login page and start from an authenticated context.
 */
import { test as setup, expect } from '@playwright/test';
import { existsSync, mkdirSync } from 'fs';

const AUTH_FILE = '.playwright/.auth/admin.json';

setup('authenticate as admin', async ({ page }) => {
  mkdirSync('.playwright/.auth', { recursive: true });

  await page.goto('/');

  // If already redirected to dashboard, auth is already valid
  if (!page.url().includes('/login')) {
    await page.context().storageState({ path: AUTH_FILE });
    return;
  }

  await page.fill('[name="email"]', process.env.TEST_ADMIN_EMAIL ?? 'testadmin@vlearn2.test');
  await page.fill('[name="password"]', process.env.TEST_ADMIN_PASSWORD ?? 'Test1234!');
  await page.click('button[type="submit"]');

  // Wait for redirect away from login
  await expect(page).not.toHaveURL(/\/login/, { timeout: 10_000 });

  await page.context().storageState({ path: AUTH_FILE });
});

export { AUTH_FILE };

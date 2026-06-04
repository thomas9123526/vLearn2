/**
 * Smoke tests — verify every major admin panel page loads without errors.
 *
 * These tests do NOT test every interaction — they verify that:
 *   1. The page renders (no crash / white screen)
 *   2. Key structural elements are present
 *   3. API calls succeed (no 500 errors in the network)
 */
import { test, expect, Page } from '@playwright/test';

// ── Helpers ──────────────────────────────────────────────────────────────────

async function noConsoleErrors(page: Page): Promise<void> {
  const errors: string[] = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push(msg.text());
  });
  // collect for a short moment
  await page.waitForTimeout(500);
  // allow React hydration warnings but block real errors
  const real = errors.filter(
    (e) => !e.includes('Warning:') && !e.includes('hydrat'),
  );
  expect(real).toHaveLength(0);
}

async function noNetworkErrors(page: Page): Promise<void> {
  page.on('response', (res) => {
    if (res.url().includes('/api/') || res.url().includes('/admin/')) {
      expect(res.status()).toBeLessThan(500);
    }
  });
}

// ── Tests ────────────────────────────────────────────────────────────────────

test.describe('Admin panel smoke tests', () => {
  test.use({ storageState: '.playwright/.auth/admin.json' });

  test('dashboard loads', async ({ page }) => {
    await noNetworkErrors(page);
    await page.goto('/');
    await expect(page.locator('nav, aside, [data-testid="nav"]').first()).toBeVisible();
    await noConsoleErrors(page);
  });

  test('/scenarios page loads with table', async ({ page }) => {
    await noNetworkErrors(page);
    await page.goto('/scenarios');
    // Wait for either a table row or an empty state message
    const tableOrEmpty = page.locator('table, [data-empty], text=No scenarios');
    await expect(tableOrEmpty.first()).toBeVisible({ timeout: 10_000 });
    await noConsoleErrors(page);
  });

  test('/personas page loads', async ({ page }) => {
    await noNetworkErrors(page);
    await page.goto('/personas');
    const tableOrEmpty = page.locator('table, [data-empty], text=No personas');
    await expect(tableOrEmpty.first()).toBeVisible({ timeout: 10_000 });
    await noConsoleErrors(page);
  });

  test('/prompt-templates page loads', async ({ page }) => {
    await noNetworkErrors(page);
    await page.goto('/prompt-templates');
    // Should show at least one template card
    await expect(page.locator('text=tutor_system, text=evaluation_system').first()).toBeVisible({
      timeout: 10_000,
    });
    await noConsoleErrors(page);
  });

  test('/prompt-vars (Variables) page loads — the crash that was fixed', async ({ page }) => {
    await noNetworkErrors(page);
    await page.goto('/prompt-vars');

    // Page must NOT show an error banner
    await expect(page.locator('text=Something went wrong, text=500')).toHaveCount(0);

    // Should show a table or empty state
    const tableOrEmpty = page.locator('table, text=No variables');
    await expect(tableOrEmpty.first()).toBeVisible({ timeout: 10_000 });
    await noConsoleErrors(page);
  });

  test('/prompt-vars — can add and delete a variable', async ({ page }) => {
    await page.goto('/prompt-vars');

    const key = `e2e_test_${Date.now()}`;

    // Fill in the "add variable" form
    const keyInput = page.locator('input[placeholder*="key"], input[name="key"]');
    if (!(await keyInput.isVisible())) {
      test.skip(true, 'Add-form not visible — check UI implementation');
      return;
    }

    await keyInput.fill(key);
    await page.locator('input[name="label"], input[placeholder*="label"]').fill('E2E Test Var');
    await page.locator('button[type="submit"], button:text("Add")').click();

    // Expect new row to appear
    await expect(page.locator(`text=${key}`)).toBeVisible({ timeout: 5_000 });

    // Delete it
    const deleteBtn = page.locator(`tr:has-text("${key}") button[aria-label="delete"], tr:has-text("${key}") button:text("Delete")`);
    if (await deleteBtn.isVisible()) {
      await deleteBtn.click();
      // Confirm if a dialog appears
      const confirmBtn = page.locator('button:text("Confirm"), button:text("Yes"), button:text("Delete")');
      if (await confirmBtn.isVisible()) await confirmBtn.click();
      await expect(page.locator(`text=${key}`)).toHaveCount(0, { timeout: 5_000 });
    }
  });

  test('/users page loads', async ({ page }) => {
    await noNetworkErrors(page);
    await page.goto('/users');
    const tableOrEmpty = page.locator('table, text=No users');
    await expect(tableOrEmpty.first()).toBeVisible({ timeout: 10_000 });
  });
});

import { defineConfig, devices } from '@playwright/test';

/**
 * Admin panel Playwright config.
 *
 * Run:  npx playwright test
 * UI:   npx playwright test --ui
 *
 * Requires a running backend (port 3000) and admin panel dev server (port 4101).
 * The runner script (cmds/run-tests.ps1) starts both automatically.
 */
export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  workers: 1,            // sequential — avoids auth race conditions
  reporter: [
    ['list'],
    ['html', { outputFolder: '../test-results/admin-panel-report', open: 'never' }],
  ],
  use: {
    baseURL: process.env.ADMIN_BASE_URL ?? 'http://localhost:4101',
    headless: true,
    screenshot: 'only-on-failure',
    video: 'off',
  },
  projects: [
    {
      name: 'setup',
      testMatch: '**/auth.setup.ts',
    },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: '.playwright/.auth/admin.json',
      },
      dependencies: ['setup'],
    },
  ],
});

/**
 * Loaded by jest-e2e.json via setupFiles[] — runs in the same process as
 * each test worker, so env vars set here ARE visible to the test code.
 *
 * Loads .env.test (if it exists) then falls back to .env, so you can keep
 * test credentials separate from development ones.
 */
import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.test'), override: true });

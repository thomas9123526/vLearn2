/**
 * Creates a full NestJS application instance pointed at the test database.
 * Call once per test file in beforeAll(), close in afterAll().
 *
 * Requires a running Postgres instance with a "vlearn2_test" database.
 * Override by setting TEST_DB_NAME in your environment.
 */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AppModule } from '../../src/app.module';

// Redirect TypeORM at the test DB before AppModule loads
process.env.DB_NAME = process.env.TEST_DB_NAME ?? 'vlearn2_test';
// Auto-create / sync schema instead of running migrations in tests
process.env.DB_SYNCHRONIZE = 'true';

export interface TestApp {
  app: INestApplication;
  module: TestingModule;
  close: () => Promise<void>;
}

let cached: TestApp | null = null;

/** Returns a shared app instance (created once, reused across specs in the same worker). */
export async function getTestApp(): Promise<TestApp> {
  if (cached) return cached;

  const module = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();

  const app = module.createNestApplication();
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  await app.init();

  cached = {
    app,
    module,
    close: async () => {
      await app.close();
      cached = null;
    },
  };
  return cached;
}

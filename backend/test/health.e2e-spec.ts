import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { HealthController } from '../src/health.controller';

/**
 * Health endpoint — no DB required, boots a minimal module.
 */
describe('GET /health', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [HealthController],
    }).compile();
    app = module.createNestApplication();
    await app.init();
  });

  afterAll(() => app.close());

  it('returns status ok with uptime and timestamp', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.body).toMatchObject({ status: 'ok' });
    expect(typeof res.body.timestamp).toBe('string');
    expect(typeof res.body.uptime).toBe('number');
  });
});

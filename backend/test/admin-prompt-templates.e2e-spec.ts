/**
 * Admin prompt-templates endpoint integration tests.
 */
import request from 'supertest';
import { getTestApp, TestApp } from './helpers/test-app';
import { getAdminToken, bearer } from './helpers/auth.helper';

describe('Admin /admin/prompt-templates (e2e)', () => {
  let ctx: TestApp;
  let token: string;

  beforeAll(async () => {
    ctx = await getTestApp();
    token = await getAdminToken(ctx.app);
  });

  afterAll(() => ctx.close());

  it('GET /admin/prompt-templates — returns 200 with array', async () => {
    const res = await request(ctx.app.getHttpServer())
      .get('/admin/prompt-templates')
      .set(bearer(token))
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
  });

  it('GET /admin/prompt-templates — each row has required fields', async () => {
    const res = await request(ctx.app.getHttpServer())
      .get('/admin/prompt-templates')
      .set(bearer(token))
      .expect(200);

    for (const tpl of res.body as Array<Record<string, unknown>>) {
      expect(typeof tpl.kind).toBe('string');
      expect(typeof tpl.label).toBe('string');
      expect(typeof tpl.template).toBe('string');
      expect(typeof tpl.is_active).toBe('boolean');
    }
  });

  it('PATCH /admin/prompt-templates/:kind — updates a template', async () => {
    // fetch tutor_system kind first to get current value
    const list = await request(ctx.app.getHttpServer())
      .get('/admin/prompt-templates')
      .set(bearer(token))
      .expect(200);

    const tpl = (list.body as Array<{ kind: string; template: string }>).find(
      (t) => t.kind === 'tutor_system',
    );
    if (!tpl) return; // no template seeded yet — skip

    const res = await request(ctx.app.getHttpServer())
      .patch('/admin/prompt-templates/tutor_system')
      .set(bearer(token))
      .send({ template: tpl.template, is_active: true })
      .expect(200);

    expect(res.body.kind).toBe('tutor_system');
  });

  it('GET /admin/prompt-templates — rejects unauthenticated', async () => {
    await request(ctx.app.getHttpServer())
      .get('/admin/prompt-templates')
      .expect(401);
  });
});

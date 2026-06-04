/**
 * Admin prompt-vars endpoint integration tests.
 *
 * These tests caught the PromptVarEntity not being registered in ALL_ENTITIES.
 * They boot the full app against vlearn2_test and exercise the CRUD flow.
 */
import request from 'supertest';
import { getTestApp, TestApp } from './helpers/test-app';
import { getAdminToken, bearer } from './helpers/auth.helper';
import { DataSource } from 'typeorm';

describe('Admin /admin/prompt-vars (e2e)', () => {
  let ctx: TestApp;
  let token: string;
  const createdKeys: string[] = [];

  beforeAll(async () => {
    ctx = await getTestApp();
    token = await getAdminToken(ctx.app);
  });

  afterAll(async () => {
    // clean up keys we created so tests are idempotent
    const ds = ctx.module.get(DataSource);
    if (createdKeys.length) {
      await ds.query(
        `DELETE FROM vl_prompt_vars WHERE key = ANY($1)`,
        [createdKeys],
      );
    }
    await ctx.close();
  });

  it('GET /admin/prompt-vars — returns 200 with array', async () => {
    const res = await request(ctx.app.getHttpServer())
      .get('/admin/prompt-vars')
      .set(bearer(token))
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
  });

  it('GET /admin/prompt-vars — rejects unauthenticated request', async () => {
    await request(ctx.app.getHttpServer())
      .get('/admin/prompt-vars')
      .expect(401);
  });

  it('POST /admin/prompt-vars — creates a new variable', async () => {
    const key = `test_var_${Date.now()}`;
    createdKeys.push(key);

    const res = await request(ctx.app.getHttpServer())
      .post('/admin/prompt-vars')
      .set(bearer(token))
      .send({
        key,
        label: 'Test Variable',
        description: 'Created by e2e test',
        global_value: 'test_value',
        scenario_overridable: true,
        sort_order: 999,
      })
      .expect(201);

    expect(res.body.key).toBe(key);
    expect(res.body.global_value).toBe('test_value');
  });

  it('PATCH /admin/prompt-vars/:key — updates global_value', async () => {
    const key = `test_patch_${Date.now()}`;
    createdKeys.push(key);

    await request(ctx.app.getHttpServer())
      .post('/admin/prompt-vars')
      .set(bearer(token))
      .send({ key, label: 'Patch Test', global_value: 'before' })
      .expect(201);

    const res = await request(ctx.app.getHttpServer())
      .patch(`/admin/prompt-vars/${key}`)
      .set(bearer(token))
      .send({ global_value: 'after' })
      .expect(200);

    expect(res.body.global_value).toBe('after');
  });

  it('DELETE /admin/prompt-vars/:key — removes the variable', async () => {
    const key = `test_delete_${Date.now()}`;
    // not pushed to createdKeys since we delete it ourselves

    await request(ctx.app.getHttpServer())
      .post('/admin/prompt-vars')
      .set(bearer(token))
      .send({ key, label: 'Delete Test', global_value: 'x' })
      .expect(201);

    await request(ctx.app.getHttpServer())
      .delete(`/admin/prompt-vars/${key}`)
      .set(bearer(token))
      .expect(200);

    // Confirm it's gone — GET list should not include it
    const list = await request(ctx.app.getHttpServer())
      .get('/admin/prompt-vars')
      .set(bearer(token))
      .expect(200);

    const found = (list.body as Array<{ key: string }>).find((v) => v.key === key);
    expect(found).toBeUndefined();
  });
});

// Dump the same OpenAPI spec that /api/docs serves into a standalone
// pair of files under backend/docs/:
//
//   openapi.json   raw spec, suitable for Postman / Swagger Editor /
//                  codegen / any compatible tool.
//   openapi.html   self-contained Swagger UI page that inlines the
//                  spec; the Swagger UI assets themselves load from a
//                  CDN so the file stays small (~5 KB) but rendering
//                  needs internet the first time.
//
// Run via `npm run docs:openapi`. The script boots the same AppModule
// the runtime uses but never calls `listen()`, so it doesn't conflict
// with a running server on the same port.

/* eslint-disable no-console */

import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ValidationPipe } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

import { AppModule } from '../app.module';

async function main() {
  // Pass `logger: false` to suppress the chatty Nest startup banner
  // -- this is a one-shot CLI, not a long-running server. Our own
  // status lines go through console.log so they survive that flag.
  const app = await NestFactory.create(AppModule, { logger: false });

  // Apply the same global plumbing main.ts applies, so the exported
  // spec matches the live /api/docs exactly. We only need the parts
  // that affect route shape (prefix) and DTO validation (pipe).
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.setGlobalPrefix('api', { exclude: ['health', 'uploads/(.*)'] });

  // Same DocumentBuilder shape as main.ts so the exported title /
  // version / auth scheme stay in lockstep with what the live server
  // advertises.
  const config = new DocumentBuilder()
    .setTitle('vLearn2 API')
    .setDescription('Backend API for the vLearn2 English-learning app.')
    .setVersion('1.0.0')
    .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' })
    .build();

  const doc = SwaggerModule.createDocument(app, config);

  const outDir = path.resolve(__dirname, '../../docs');
  fs.mkdirSync(outDir, { recursive: true });

  const jsonPath = path.join(outDir, 'openapi.json');
  fs.writeFileSync(jsonPath, JSON.stringify(doc, null, 2), 'utf8');
  console.log(`wrote ${path.relative(process.cwd(), jsonPath)}`);

  const htmlPath = path.join(outDir, 'openapi.html');
  fs.writeFileSync(htmlPath, renderStandaloneHtml(doc), 'utf8');
  console.log(`wrote ${path.relative(process.cwd(), htmlPath)}`);

  // Quick sanity numbers so the operator can eyeball that the export
  // actually contains content -- a route count drop is the most
  // common symptom of a stale build.
  const paths = Object.keys(doc.paths ?? {});
  const ops = paths.reduce((n, p) => {
    const item = (doc.paths as Record<string, unknown>)[p] as Record<string, unknown>;
    return n + Object.keys(item ?? {}).filter((k) =>
      ['get', 'post', 'put', 'patch', 'delete', 'options', 'head'].includes(k),
    ).length;
  }, 0);
  console.log(`spec: ${paths.length} paths, ${ops} operations`);

  // Don't await app.close() -- AppConfigService.refreshGzipCache()
  // fires a fire-and-forget DB query from its constructor, and
  // app.close() races it: closing the pool while the query is
  // in flight surfaces as an unhandled "Connection terminated"
  // rejection. The files we care about are already on disk by
  // this point; just exit and let the OS reclaim the pool.
  process.exit(0);
}

function renderStandaloneHtml(doc: unknown): string {
  // Inline the spec as a JS object so the file is self-contained --
  // no second fetch, no CORS, no separate static server. Swagger UI
  // is loaded from a pinned CDN version (kept in sync with the
  // @nestjs/swagger 11.x defaults) so a future UI bump here doesn't
  // silently change the layout.
  const inline = JSON.stringify(doc);
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>vLearn2 API</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.17.14/swagger-ui.css" />
  <style> body { margin: 0; } </style>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.17.14/swagger-ui-bundle.js" crossorigin></script>
  <script>
    const spec = ${inline};
    window.onload = () => {
      window.ui = SwaggerUIBundle({
        spec,
        dom_id: '#swagger-ui',
        deepLinking: true,
        persistAuthorization: true,
      });
    };
  </script>
</body>
</html>
`;
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('export-openapi failed:', err);
  process.exit(1);
});

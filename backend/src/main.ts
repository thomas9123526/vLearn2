// vLearn2 — backend bootstrap.
//
// Wires the NestJS app the way the rest of the codebase assumes:
//   * helmet for security headers and CORS pinned to CORS_ORIGINS;
//   * compression with a runtime kill-switch (admins can disable gzip
//     without restarting via the `system.gzip_enabled` app_config flag);
//   * a global validation pipe that strips unknown fields so DTOs are the
//     single source of truth for request payloads;
//   * an /api prefix on every route except /health and /uploads/* (static
//     file serving for scenario / persona / news images);
//   * Swagger docs at /api/docs with persisted bearer-token auth.
//
// All real business logic lives inside feature modules under src/*. This
// file is intentionally thin.

import './polyfill'; // must be first — populates globalThis.crypto for Node 18
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import compression from 'compression';
import cors from 'cors';
import * as path from 'path';
import { AppModule } from './app.module';
import { GzipFlagCache } from './app-config/app-config.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    bufferLogs: false,
  });
  const config = app.get(ConfigService);

  // ─── Security headers ──────────────────────────────────────
  // CSP's `upgrade-insecure-requests` directive (Helmet default) forces the
  // browser to refetch every subresource over HTTPS. Without a TLS cert on
  // this VPS, that breaks Swagger UI and any other in-app asset over plain
  // HTTP. Turn CSP off in development; re-enable it once HTTPS is in place.
  const isProd = (config.get<string>('NODE_ENV') ?? 'development') === 'production';
  app.use(helmet({ contentSecurityPolicy: isProd ? undefined : false }));

  // ─── CORS ──────────────────────────────────────────────────
  const corsOrigins = (config.get<string>('CORS_ORIGINS') ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  app.enableCors({
    origin: corsOrigins.length > 0 ? corsOrigins : true,
    credentials: true,
  });

  // ─── Conditional gzip (see todoList/0516/11 §11.2) ────────
  // The env-var `GZIP_ENABLED=false` forces compression off (useful for local
  // debugging). Otherwise the live `system.gzip_enabled` flag is consulted on
  // every request — admins flip it from the admin panel without restarting.
  const gzipForcedOff = config.get<string>('GZIP_ENABLED') === 'false';
  const gzipThreshold = parseInt(
    config.get<string>('GZIP_THRESHOLD_BYTES') ?? '102400',
    10,
  );
  app.use(
    compression({
      threshold: gzipThreshold,
      filter: (req, res) => {
        // if (gzipForcedOff) return false;
        // if (!GzipFlagCache.enabled) return false;
        return compression.filter(req, res);
      },
    }),
  );

  // ─── Body size limit (defends against very large payloads) ─
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // ─── API prefix + versioning ───────────────────────────────
  app.setGlobalPrefix('api', { exclude: ['health', 'uploads/(.*)'] });

  // ─── CORS for static files ──────────────────────────────────
  // The global CORS middleware may not apply to static files served via
  // useStaticAssets, so we add explicit CORS middleware for /uploads/
  const corsOptions = {
    origin: corsOrigins.length > 0 ? corsOrigins : true,
    credentials: true,
  };
  app.use('/uploads/', cors(corsOptions), (_req: any, res: any, next: any) => {
    // Helmet sets CORP to same-origin by default; override so cross-origin
    // pages (admin panel on :4101) can load images served from :5101.
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    next();
  });

  // ─── Static uploads (scenario hero images, news hero images) ──
  const uploadsDir = process.env.UPLOADS_DIR ?? path.resolve('uploads');
  app.useStaticAssets(uploadsDir, { prefix: '/uploads/' });

  // ─── Swagger docs at /api/docs ─────────────────────────────
  const swagger = new DocumentBuilder()
    .setTitle('vLearn2 API')
    .setDescription('Backend API for the vLearn2 English-learning app.')
    .setVersion('1.0.0')
    .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' })
    .build();
  const doc = SwaggerModule.createDocument(app, swagger);
  // The nginx in front of this backend maps /vfls/ → /api/, so the public
  // path for the OpenAPI spec is /vfls/docs-json. Swagger UI's default
  // (/api/docs-json) collides with another backend mounted at /api/, so we
  // pin the URL explicitly. Override via ?url= when accessing directly.
  SwaggerModule.setup('api/docs', app, doc, {
    swaggerOptions: {
      persistAuthorization: true,
      url: process.env.SWAGGER_SPEC_URL ?? '/vfls/docs-json',
    },
  });

  // ─── Listen ────────────────────────────────────────────────
  const port = parseInt(config.get<string>('PORT') ?? '3000', 10);
  await app.listen(port);

  logger.log(`vLearn2 backend listening on http://localhost:${port}`);
  logger.log(`Swagger docs at http://localhost:${port}/api/docs`);
  logger.log(`AI provider: ${config.get('AI_PROVIDER') ?? 'anthropic'}`);
  logger.log(
    `Gzip: ${
      gzipForcedOff
        ? 'forced off (GZIP_ENABLED=false)'
        : `runtime-toggled (≥${gzipThreshold}B); current=${GzipFlagCache.enabled}`
    }`,
  );
}

bootstrap().catch((err) => {
  console.error('Fatal bootstrap error:', err);
  process.exit(1);
});

import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule, { bufferLogs: false });
  const config = app.get(ConfigService);

  // ─── Security headers ──────────────────────────────────────
  app.use(helmet());

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
  const gzipEnabled = config.get<string>('GZIP_ENABLED') !== 'false';
  const gzipThreshold = parseInt(
    config.get<string>('GZIP_THRESHOLD_BYTES') ?? '102400',
    10,
  );
  app.use(
    compression({
      threshold: gzipThreshold,
      filter: (req, res) => {
        if (!gzipEnabled) return false;
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

  // ─── Swagger docs at /api/docs ─────────────────────────────
  const swagger = new DocumentBuilder()
    .setTitle('vLearn2 API')
    .setDescription('Backend API for the vLearn2 English-learning app.')
    .setVersion('1.0.0')
    .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' })
    .build();
  const doc = SwaggerModule.createDocument(app, swagger);
  SwaggerModule.setup('api/docs', app, doc, {
    swaggerOptions: { persistAuthorization: true },
  });

  // ─── Listen ────────────────────────────────────────────────
  const port = parseInt(config.get<string>('PORT') ?? '3000', 10);
  await app.listen(port);

  logger.log(`vLearn2 backend listening on http://localhost:${port}`);
  logger.log(`Swagger docs at http://localhost:${port}/api/docs`);
  logger.log(`AI provider: ${config.get('AI_PROVIDER') ?? 'anthropic'}`);
  logger.log(`Gzip: ${gzipEnabled ? `enabled (≥${gzipThreshold}B)` : 'disabled'}`);
}

bootstrap().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('Fatal bootstrap error:', err);
  process.exit(1);
});

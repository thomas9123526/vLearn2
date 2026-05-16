import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { join } from 'path';

/**
 * TypeORM config consumed by TypeOrmModule.forRootAsync() in AppModule.
 * Mirrors data-source.ts (which is used by the migration CLI).
 */
export const typeormConfigFactory = (
  config: ConfigService,
): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: config.get<string>('DB_HOST') ?? 'localhost',
  port: parseInt(config.get<string>('DB_PORT') ?? '5432', 10),
  username: config.get<string>('DB_USER') ?? 'postgres',
  password: config.get<string>('DB_PASSWORD') ?? '',
  database: config.get<string>('DB_NAME') ?? 'vlearn2',
  entities: [join(__dirname, 'entities', '*.entity.{ts,js}')],
  migrations: [join(__dirname, 'migrations', '*.{ts,js}')],
  migrationsRun: false,
  synchronize: false,
  logging: config.get<string>('DB_LOGGING') === 'true' ? ['error', 'query'] : ['error'],
});

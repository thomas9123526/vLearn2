import 'dotenv/config';
import { DataSource } from 'typeorm';
import { join } from 'path';
import { ALL_ENTITIES } from './entities';

/**
 * Standalone TypeORM data source for migrations and seeds.
 * The NestJS app uses TypeOrmModule.forRootAsync() with the same config
 * (see backend/src/database/typeorm-config.factory.ts).
 */
export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: parseInt(process.env.DB_PORT ?? '5432', 10),
  username: process.env.DB_USER ?? 'postgres',
  password: process.env.DB_PASSWORD ?? '',
  database: process.env.DB_NAME ?? 'vlearn2',
  entities: ALL_ENTITIES,
  migrations: [join(__dirname, 'migrations', '*.{ts,js}').replace(/\\/g, '/')],
  synchronize: false, // never true — migrations are the source of truth
  logging: process.env.DB_LOGGING === 'true' ? ['query', 'error'] : ['error'],
});

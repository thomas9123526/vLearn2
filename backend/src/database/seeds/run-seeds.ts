import { AppDataSource } from '../data-source';
import { seedPersonas } from './seeds/personas.seed';
import { seedScenarios } from './seeds/scenarios.seed';
import { seedCourses } from './seeds/courses.seed';
import { seedAchievements } from './seeds/achievements.seed';
import { seedAppConfig } from './seeds/app-config.seed';

async function main() {
  // eslint-disable-next-line no-console
  console.log('▶ Initializing data source...');
  await AppDataSource.initialize();

  try {
    // eslint-disable-next-line no-console
    console.log('▶ Seeding personas...');
    await seedPersonas(AppDataSource);

    // eslint-disable-next-line no-console
    console.log('▶ Seeding scenarios...');
    await seedScenarios(AppDataSource);

    // eslint-disable-next-line no-console
    console.log('▶ Seeding courses...');
    await seedCourses(AppDataSource);

    // eslint-disable-next-line no-console
    console.log('▶ Seeding achievements...');
    await seedAchievements(AppDataSource);

    // eslint-disable-next-line no-console
    console.log('▶ Seeding app_config (visibility flags)...');
    await seedAppConfig(AppDataSource);

    // eslint-disable-next-line no-console
    console.log('✓ Seed complete.');
  } finally {
    await AppDataSource.destroy();
  }
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('✗ Seed failed:', err);
  process.exit(1);
});

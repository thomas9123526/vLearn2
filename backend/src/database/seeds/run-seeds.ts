import { AppDataSource } from '../data-source';
import { seedPersonas } from './seeds/personas.seed';
import { seedScenarios } from './seeds/scenarios.seed';
import { seedCourses } from './seeds/courses.seed';
import { seedAchievements } from './seeds/achievements.seed';
import { seedAppConfig } from './seeds/app-config.seed';

async function main() {
  console.log('▶ Initializing data source...');
  await AppDataSource.initialize();

  try {
    console.log('▶ Seeding personas...');
    await seedPersonas(AppDataSource);

    console.log('▶ Seeding scenarios...');
    await seedScenarios(AppDataSource);

    console.log('▶ Seeding courses...');
    await seedCourses(AppDataSource);

    console.log('▶ Seeding achievements...');
    await seedAchievements(AppDataSource);

    console.log('▶ Seeding app_config (visibility flags)...');
    await seedAppConfig(AppDataSource);

    console.log('✓ Seed complete.');
  } finally {
    await AppDataSource.destroy();
  }
}

main().catch((err) => {
  console.error('✗ Seed failed:', err);
  process.exit(1);
});

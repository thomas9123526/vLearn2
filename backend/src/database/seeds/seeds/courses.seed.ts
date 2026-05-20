import { DataSource } from 'typeorm';
import {
  CourseEntity,
  CourseScenarioEntity,
} from '../../entities/course.entity';
import { ScenarioEntity } from '../../entities/scenario.entity';

interface CourseSeed {
  slug: string;
  title_en: string;
  title_ko: string;
  title_zh: string;
  description_en: string;
  level_range: string;
  scenario_slugs: string[];
}

const COURSES: CourseSeed[] = [
  {
    slug: 'beginner-foundations',
    title_en: 'Beginner Foundations',
    title_ko: '초급 기초',
    title_zh: '初级基础',
    description_en: 'Everyday English for A1–A2 learners.',
    level_range: 'A1-A2',
    scenario_slugs: [
      'restaurant-ordering',
      'taxi-ride',
      'greeting-strangers',
      'grocery-shopping',
      'asking-directions',
    ],
  },
  {
    slug: 'intermediate-fluency',
    title_en: 'Intermediate Fluency',
    title_ko: '중급 회화',
    title_zh: '中级流利',
    description_en: 'Build conversational fluency at B1–B2.',
    level_range: 'B1-B2',
    scenario_slugs: [
      'airport-check-in',
      'hotel-reservation',
      'business-meeting-intro',
      'first-date',
      'doctor-visit',
    ],
  },
];

export async function seedCourses(ds: DataSource): Promise<void> {
  const courseRepo = ds.getRepository(CourseEntity);
  const csRepo = ds.getRepository(CourseScenarioEntity);
  const scenarioRepo = ds.getRepository(ScenarioEntity);

  let courseOrder = 0;
  for (const c of COURSES) {
    const courseData = {
      slug: c.slug,
      title: { en: c.title_en, ko: c.title_ko, zh: c.title_zh },
      description: { en: c.description_en },
      level_range: c.level_range,
      order_index: courseOrder++,
      status: 'published' as const,
      published_at: new Date(),
    };
    let course = await courseRepo.findOne({ where: { slug: c.slug } });
    if (course) {
      Object.assign(course, courseData);
      course = await courseRepo.save(course);
    } else {
      course = await courseRepo.save(courseRepo.create(courseData));
    }

    // wipe + re-insert membership for idempotency
    await csRepo.delete({ course_id: course.id });
    let totalXp = 0;
    for (let i = 0; i < c.scenario_slugs.length; i++) {
      const slug = c.scenario_slugs[i];
      const scenario = await scenarioRepo.findOne({ where: { slug } });
      if (!scenario) {
        console.warn(
          `  ! Course '${c.slug}' references missing scenario '${slug}'`,
        );
        continue;
      }
      await csRepo.save(
        csRepo.create({
          course_id: course.id,
          scenario_id: scenario.id,
          order_index: i,
        }),
      );
      totalXp += scenario.xp_reward;
    }
    course.total_xp = totalXp;
    await courseRepo.save(course);
  }
}

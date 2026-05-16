import { DataSource } from 'typeorm';
import { AchievementEntity } from '../../entities/achievement.entity';

interface AchievementSeed {
  key: string;
  title_en: string;
  description_en: string;
  icon: string;
  xp_reward: number;
  condition_type: string;
  condition_value: number;
}

const ACHIEVEMENTS: AchievementSeed[] = [
  { key: 'first_session',     title_en: 'First Step',       description_en: 'Complete your first conversation.',     icon: '🎉', xp_reward: 25,  condition_type: 'sessions',     condition_value: 1 },
  { key: 'ten_sessions',      title_en: 'Getting Going',    description_en: 'Complete 10 conversations.',            icon: '💪', xp_reward: 50,  condition_type: 'sessions',     condition_value: 10 },
  { key: 'fifty_sessions',    title_en: 'Dedicated Learner', description_en: 'Complete 50 conversations.',           icon: '🔥', xp_reward: 100, condition_type: 'sessions',     condition_value: 50 },
  { key: 'streak_7',          title_en: 'Week Warrior',     description_en: '7-day learning streak.',                icon: '⚡', xp_reward: 50,  condition_type: 'streak',       condition_value: 7 },
  { key: 'streak_30',         title_en: 'Monthly Mastery',  description_en: '30-day learning streak.',               icon: '🏆', xp_reward: 200, condition_type: 'streak',       condition_value: 30 },
  { key: 'level_a2',          title_en: 'Foundations',      description_en: 'Reach level A2.',                       icon: '🌱', xp_reward: 75,  condition_type: 'level',        condition_value: 2 },
  { key: 'level_b1',          title_en: 'Conversational',   description_en: 'Reach level B1.',                       icon: '🌿', xp_reward: 150, condition_type: 'level',        condition_value: 3 },
  { key: 'level_b2',          title_en: 'Confident',        description_en: 'Reach level B2.',                       icon: '🌳', xp_reward: 250, condition_type: 'level',        condition_value: 4 },
  { key: 'score_80',          title_en: 'Strong Effort',    description_en: 'Score 80+ on a session.',               icon: '⭐', xp_reward: 25,  condition_type: 'score',        condition_value: 80 },
  { key: 'score_95',          title_en: 'Nearly Perfect',   description_en: 'Score 95+ on a session.',               icon: '💎', xp_reward: 75,  condition_type: 'score',        condition_value: 95 },
  { key: 'scenarios_10',      title_en: 'Explorer',         description_en: 'Complete 10 unique scenarios.',         icon: '🗺️', xp_reward: 75,  condition_type: 'scenarios',    condition_value: 10 },
  { key: 'all_personas',      title_en: 'Tutor Tour',       description_en: 'Practice with all four tutors.',        icon: '🤝', xp_reward: 50,  condition_type: 'personas',     condition_value: 4 },
];

export async function seedAchievements(ds: DataSource): Promise<void> {
  const repo = ds.getRepository(AchievementEntity);
  for (const a of ACHIEVEMENTS) {
    const data = {
      key: a.key,
      title: { en: a.title_en },
      description: { en: a.description_en },
      icon: a.icon,
      xp_reward: a.xp_reward,
      condition_type: a.condition_type,
      condition_value: a.condition_value,
    };
    const existing = await repo.findOne({ where: { key: a.key } });
    if (existing) {
      Object.assign(existing, data);
      await repo.save(existing);
    } else {
      await repo.save(repo.create(data));
    }
  }
}

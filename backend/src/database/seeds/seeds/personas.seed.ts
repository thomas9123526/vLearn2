import { DataSource } from 'typeorm';
import { PersonaEntity } from '../../entities/persona.entity';

const PERSONAS = [
  {
    slug: 'maya',
    name: 'Maya',
    accent: 'Warm American',
    style: 'Encouraging, patient',
    specialties: ['Travel', 'Daily life', 'Beginner-friendly'],
    gradient_from: '#FFB997',
    gradient_to: '#FF6B47',
    rive_asset: 'persona_maya.riv',
  },
  {
    slug: 'leo',
    name: 'Leo',
    accent: 'Casual British',
    style: 'Energetic, fun',
    specialties: ['Slang', 'Social conversation', 'Pop culture'],
    gradient_from: '#A8E6CF',
    gradient_to: '#5DBE9C',
    rive_asset: 'persona_leo.riv',
  },
  {
    slug: 'sofia',
    name: 'Sofia',
    accent: 'Crisp British',
    style: 'Precise, professional',
    specialties: ['Business', 'Formal English', 'Grammar'],
    gradient_from: '#C9B6FF',
    gradient_to: '#7C6BE6',
    rive_asset: 'persona_sofia.riv',
  },
  {
    slug: 'theo',
    name: 'Theo',
    accent: 'Australian',
    style: 'Intellectual, curious',
    specialties: ['Academic English', 'Critical thinking', 'Debate'],
    gradient_from: '#2C2A4A',
    gradient_to: '#4F4C7E',
    rive_asset: 'persona_theo.riv',
  },
];

export async function seedPersonas(ds: DataSource): Promise<void> {
  const repo = ds.getRepository(PersonaEntity);
  for (const p of PERSONAS) {
    const existing = await repo.findOne({ where: { slug: p.slug } });
    if (existing) {
      Object.assign(existing, p);
      await repo.save(existing);
    } else {
      await repo.save(repo.create(p));
    }
  }
}

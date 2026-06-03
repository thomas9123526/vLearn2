import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { PromptBuilderService } from './prompt-builder.service';
import { PromptTemplateEntity } from '../database/entities/prompt-template.entity';

describe('PromptBuilderService', () => {
  let service: PromptBuilderService;

  beforeEach(async () => {
    const mod = await Test.createTestingModule({
      providers: [
        PromptBuilderService,
        {
          // Force fallback to the built-in defaults by always returning null.
          provide: getRepositoryToken(PromptTemplateEntity),
          useValue: { findOne: jest.fn().mockResolvedValue(null) },
        },
      ],
    }).compile();
    service = mod.get(PromptBuilderService);
  });

  it('builds a system prompt that names the persona and level', async () => {
    const persona = {
      id: 'p1',
      slug: 'maya',
      name: 'Maya',
      accent: 'Warm American',
      style: 'Encouraging, patient',
      specialties: ['Travel'],
    } as never;
    const { prompt, source } = await service.buildSystemPrompt(persona, null, 3, 'ko');

    expect(source).toBeTruthy();
    expect(prompt).toContain('Maya');
    expect(prompt).toContain('Encouraging, patient');
    expect(prompt).toContain('B1');
    expect(prompt).toContain('ko');
    expect(prompt).toContain('Free conversation practice');
  });

  it('builds a grammar prompt that lists numbered messages', async () => {
    const out = await service.buildGrammarPrompt(
      ['I goes to store.', 'She buy apple.'],
      2,
    );
    expect(out).toContain('1. "I goes to store."');
    expect(out).toContain('2. "She buy apple."');
    expect(out).toContain('level 2/6');
  });
});

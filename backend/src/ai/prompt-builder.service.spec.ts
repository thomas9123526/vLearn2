import { Test } from '@nestjs/testing';
import { PromptBuilderService } from './prompt-builder.service';

describe('PromptBuilderService', () => {
  let service: PromptBuilderService;

  beforeEach(async () => {
    const mod = await Test.createTestingModule({
      providers: [PromptBuilderService],
    }).compile();
    service = mod.get(PromptBuilderService);
  });

  it('builds a system prompt that names the persona and level', () => {
    const persona = {
      id: 'p1',
      slug: 'maya',
      name: 'Maya',
      accent: 'Warm American',
      style: 'Encouraging, patient',
      specialties: ['Travel'],
    } as never;
    const result = service.buildSystemPrompt(persona, null, 3, 'ko');

    expect(result).toContain('You are Maya');
    expect(result).toContain('Encouraging, patient');
    expect(result).toContain('English level: B1 (3/6)');
    expect(result).toContain('Native language: ko');
    expect(result).toContain('Free conversation practice');
  });

  it('builds a grammar prompt that lists numbered messages', () => {
    const out = service.buildGrammarPrompt(['I goes to store.', 'She buy apple.'], 2);
    expect(out).toContain('1. "I goes to store."');
    expect(out).toContain('2. "She buy apple."');
    expect(out).toContain('level 2/6');
  });
});

import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { getRepositoryToken } from '@nestjs/typeorm';
import { PromptBuilderService } from './prompt-builder.service';
import { PromptTemplateEntity } from '../database/entities/prompt-template.entity';
import { PromptVarEntity } from '../database/entities/prompt-var.entity';

const mockTemplateRepo = { findOne: jest.fn().mockResolvedValue(null) };
const mockVarRepo      = { find:    jest.fn().mockResolvedValue([]) };
const mockConfig       = { get:     jest.fn().mockReturnValue(undefined) };

describe('PromptBuilderService', () => {
  let service: PromptBuilderService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const mod = await Test.createTestingModule({
      providers: [
        PromptBuilderService,
        { provide: ConfigService,                            useValue: mockConfig },
        { provide: getRepositoryToken(PromptTemplateEntity), useValue: mockTemplateRepo },
        { provide: getRepositoryToken(PromptVarEntity),      useValue: mockVarRepo },
      ],
    }).compile();

    service = mod.get(PromptBuilderService);
  });

  it('falls back to section-builder when no DB template exists', async () => {
    const persona = {
      id: 'p1', slug: 'maya', name: 'Maya',
      accent: 'Warm American', style: 'Encouraging, patient',
      specialties: ['Travel'],
    } as never;

    const { prompt, source } = await service.buildSystemPrompt(persona, null, 3, 'ko');

    expect(source).toContain('section-builder');
    expect(prompt).toContain('Maya');
    expect(prompt).toContain('Encouraging, patient');
    expect(prompt).toContain('B1');
    expect(prompt).toContain('Free conversation practice');
  });

  it('uses DB template when one is active', async () => {
    mockTemplateRepo.findOne.mockResolvedValueOnce({
      kind: 'tutor_system',
      template: 'Hello {{persona.name}} at {{user.level_label}}',
      is_active: true,
    });

    const persona = {
      id: 'p2', slug: 'leo', name: 'Leo',
      accent: 'British', style: 'Direct',
      specialties: [],
    } as never;

    const { prompt, source } = await service.buildSystemPrompt(persona, null, 2, 'zh');

    expect(source).toContain('DB template');
    expect(prompt).toBe('Hello Leo at A2');
  });

  it('resolves prompt vars from the vars repository', async () => {
    mockVarRepo.find.mockResolvedValueOnce([
      { key: 'country_adjective', global_value: 'Chinese', sort_order: 0 },
      { key: 'learner_description', global_value: 'adult learners', sort_order: 1 },
      { key: 'avoid_cultures_phrase', global_value: 'American and European', sort_order: 2 },
    ]);

    const evalPrompt = await service.buildEvaluationSystemPrompt(null);

    expect(evalPrompt).toContain('Chinese');
    expect(evalPrompt).toContain('adult learners');
    expect(evalPrompt).toContain('American and European');
    expect(evalPrompt).toContain('/think');   // always appended
  });

  it('appends /no_think to tutor prompt when AI_DISABLE_THINKING is true', async () => {
    mockConfig.get.mockImplementation((key: string) =>
      key === 'AI_DISABLE_THINKING' ? 'true' : undefined,
    );

    // Re-create service so constructor reads the updated config mock
    const mod = await Test.createTestingModule({
      providers: [
        PromptBuilderService,
        { provide: ConfigService,                            useValue: mockConfig },
        { provide: getRepositoryToken(PromptTemplateEntity), useValue: mockTemplateRepo },
        { provide: getRepositoryToken(PromptVarEntity),      useValue: mockVarRepo },
      ],
    }).compile();
    const svc = mod.get(PromptBuilderService);

    const persona = {
      id: 'p3', slug: 'sam', name: 'Sam',
      accent: '', style: 'Casual', specialties: [],
    } as never;

    const { prompt } = await svc.buildSystemPrompt(persona, null, 1, 'en');
    expect(prompt).toContain('/no_think');
  });
});

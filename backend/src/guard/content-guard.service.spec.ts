import { ContentGuardService } from './content-guard.service';

describe('ContentGuardService', () => {
  let svc: ContentGuardService;

  beforeAll(() => {
    svc = new ContentGuardService();
  });

  it('passes clean text', () => {
    expect(svc.check('Hello, how are you today?').severity).toBe('ok');
  });

  it('does not false-positive substring matches (Scunthorpe problem)', () => {
    // "ass" appears inside "embarrass" — word boundary should prevent matching
    const result = svc.check('I felt embarrassed by the situation.');
    expect(result.severity).toBe('ok');
  });

  it('warns on mild profanity', () => {
    const result = svc.check('damn that is annoying');
    expect(result.severity).toBe('warn');
    expect(result.matchedTerms).toContain('damn');
  });

  it('blocks severe profanity', () => {
    const result = svc.check('fuck this');
    expect(result.severity).toBe('block');
  });
});

import { cn } from '../utils';

describe('cn (tailwind class merger)', () => {
  it('merges class names', () => {
    expect(cn('a', 'b')).toBe('a b');
  });

  it('drops conditional false values', () => {
    expect(cn('a', false && 'b', 'c')).toBe('a c');
  });

  it('lets later tailwind utilities override earlier ones', () => {
    // tailwind-merge resolves conflicting utilities; padding "p-2" overrides "p-4"
    expect(cn('p-4', 'p-2')).toBe('p-2');
  });

  it('keeps non-conflicting utilities', () => {
    expect(cn('flex', 'gap-2')).toBe('flex gap-2');
  });
});

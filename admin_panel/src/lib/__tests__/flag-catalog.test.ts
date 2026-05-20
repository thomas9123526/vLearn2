import {
  APP_TABS,
  FLAG_CATALOG,
  descriptorFor,
} from '../flag-catalog';

describe('flag-catalog', () => {
  it('descriptorFor returns the matching descriptor', () => {
    const d = descriptorFor('home.greeting');
    expect(d).toBeDefined();
    expect(d?.tab).toBe('home');
    expect(d?.tier).toBe('big');
  });

  it('descriptorFor returns undefined for an unknown key', () => {
    expect(descriptorFor('does.not.exist')).toBeUndefined();
  });

  it('every flag references a known tab', () => {
    const knownTabs = new Set(APP_TABS.map((t) => t.id));
    for (const flag of FLAG_CATALOG) {
      expect(knownTabs.has(flag.tab)).toBe(true);
    }
  });

  it('flag keys are unique', () => {
    const keys = FLAG_CATALOG.map((f) => f.key);
    expect(new Set(keys).size).toBe(keys.length);
  });

  it('every tab has at least one flag', () => {
    for (const tab of APP_TABS) {
      const count = FLAG_CATALOG.filter((f) => f.tab === tab.id).length;
      expect(count).toBeGreaterThan(0);
    }
  });

  it('only big or fine tiers are used', () => {
    for (const f of FLAG_CATALOG) {
      expect(['big', 'fine']).toContain(f.tier);
    }
  });
});

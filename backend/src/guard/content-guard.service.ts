import { Injectable, Logger } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';

export type GuardSeverity = 'ok' | 'warn' | 'block';

export interface GuardResult {
  severity: GuardSeverity;
  matchedTerms: string[];
  language?: string;
}

interface Wordlist {
  language: string;
  block: string[];
  warn: string[];
}

/**
 * Server-side content guard. Loads wordlists from disk at boot; reloadable via
 * the admin endpoint without restart (POST /admin/guard/reload).
 */
@Injectable()
export class ContentGuardService {
  private readonly logger = new Logger('ContentGuardService');
  private wordlists: Map<string, Wordlist> = new Map();

  constructor() {
    this.reload();
  }

  reload(): void {
    const langs = ['en', 'ko', 'zh', 'custom'];
    for (const lang of langs) {
      try {
        const filename = lang === 'custom' ? 'custom.json' : `profanity_${lang}.json`;
        const path = join(__dirname, 'wordlists', filename);
        const data = JSON.parse(readFileSync(path, 'utf-8')) as Wordlist;
        this.wordlists.set(lang, data);
      } catch (e) {
        this.logger.warn(`Could not load ${lang} wordlist: ${(e as Error).message}`);
      }
    }
    this.logger.log(`Loaded ${this.wordlists.size} wordlists`);
  }

  check(text: string, activeLanguages: string[] = ['en']): GuardResult {
    if (!text || text.trim().length === 0) {
      return { severity: 'ok', matchedTerms: [] };
    }
    const normalized = this.normalize(text);
    const langs = new Set<string>(activeLanguages);
    langs.add('en'); // always check English
    langs.add('custom'); // always check custom additions

    let warnMatches: string[] = [];
    for (const lang of langs) {
      const wl = this.wordlists.get(lang);
      if (!wl) continue;

      for (const term of wl.block) {
        if (this.matches(normalized, term.toLowerCase())) {
          return { severity: 'block', matchedTerms: [term], language: lang };
        }
      }
      for (const term of wl.warn) {
        if (this.matches(normalized, term.toLowerCase())) {
          warnMatches.push(term);
        }
      }
    }

    return warnMatches.length > 0
      ? { severity: 'warn', matchedTerms: warnMatches }
      : { severity: 'ok', matchedTerms: [] };
  }

  private normalize(text: string): string {
    return text
      .toLowerCase()
      .normalize('NFKC')
      // Strip combining marks
      .replace(/\p{M}/gu, '')
      // Collapse whitespace
      .replace(/\s+/g, ' ')
      .trim();
  }

  private matches(normalized: string, term: string): boolean {
    if (term.includes(' ')) {
      // multi-word phrase: substring match
      return normalized.includes(term);
    }
    // single word: word-boundary regex
    const escaped = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const re = new RegExp(`(^|[^\\p{L}\\p{N}])${escaped}([^\\p{L}\\p{N}]|$)`, 'u');
    return re.test(normalized);
  }
}

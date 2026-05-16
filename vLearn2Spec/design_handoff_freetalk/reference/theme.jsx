// Theme palettes + persona definitions for FreeTalk.
// Each palette is a coherent, layered system designed for editorial warmth:
//   bg < surface < surfaceAlt < surfaceDeep      (page → card → muted → sunken)
//   ink > inkSoft > inkFaint                     (text contrast ladder)
//   accent (hero)   accent2 (secondary, harmonious complement)
//   accentSoft (tinted background)  accentInk (deep on-tint text)
//   good / warn / bad — tuned to each theme, never clashing
// Exposed on window so other Babel scripts can read them.

const THEMES = {
  // ───────── APRICOT ─────────
  // Warm parchment + terracotta + olive. Mediterranean villa, golden hour.
  sunrise: {
    name: 'Apricot',
    bg:          '#faf6ef',
    surface:     '#ffffff',
    surfaceAlt:  '#f2eada',
    surfaceDeep: '#e8dcc4',
    ink:         '#2a1d12',
    inkSoft:     '#6c5641',
    inkFaint:    '#a8917b',
    border:      'rgba(70,48,22,0.085)',
    accent:      '#d4633a',
    accent2:     '#7d8c52',
    accentSoft:  '#fbe1d1',
    accentInk:   '#6e2911',
    good:        '#5e8a4a',
    warn:        '#c89035',
    bad:         '#b94a3a',
    glow:
      'radial-gradient(900px 600px at 78% -10%, #fbe1d1 0%, transparent 62%),' +
      'radial-gradient(700px 500px at -8% 92%, #f5e6c8 0%, transparent 70%)',
  },

  // ───────── SAGE ─────────
  // Eucalyptus + dusty rose. Quiet, editorial, calming.
  mint: {
    name: 'Sage',
    bg:          '#f3f4ee',
    surface:     '#ffffff',
    surfaceAlt:  '#e6eae0',
    surfaceDeep: '#d4dbcc',
    ink:         '#1d2620',
    inkSoft:     '#52624f',
    inkFaint:    '#92a193',
    border:      'rgba(30,55,40,0.085)',
    accent:      '#446b54',
    accent2:     '#c47d6b',
    accentSoft:  '#d6e2d4',
    accentInk:   '#1e3326',
    good:        '#4a8062',
    warn:        '#c8943f',
    bad:         '#b8584a',
    glow:
      'radial-gradient(900px 600px at 82% -10%, #d6e2d4 0%, transparent 65%),' +
      'radial-gradient(700px 500px at -8% 92%, #ead8cf 0%, transparent 70%)',
  },

  // ───────── IRIS ─────────
  // Cool ivory + periwinkle + warm amber. Ethereal, refined, hopeful.
  lavender: {
    name: 'Iris',
    bg:          '#f6f4fb',
    surface:     '#ffffff',
    surfaceAlt:  '#ebe6f4',
    surfaceDeep: '#d8d0e8',
    ink:         '#1f1932',
    inkSoft:     '#594b78',
    inkFaint:    '#9286ad',
    border:      'rgba(60,30,90,0.085)',
    accent:      '#6957c2',
    accent2:     '#d4925a',
    accentSoft:  '#e0d6f4',
    accentInk:   '#2e1d75',
    good:        '#4a8c6e',
    warn:        '#c98740',
    bad:         '#b8585a',
    glow:
      'radial-gradient(900px 600px at 82% -10%, #e0d6f4 0%, transparent 65%),' +
      'radial-gradient(700px 500px at -8% 92%, #f0e2d0 0%, transparent 70%)',
  },

  // ───────── OBSIDIAN ─────────
  // Deep navy + electric teal + warm amber. Luxurious dark mode.
  midnight: {
    name: 'Obsidian',
    bg:          '#0e1424',
    surface:     '#181f33',
    surfaceAlt:  '#232b42',
    surfaceDeep: '#2c3653',
    ink:         '#eef1fa',
    inkSoft:     '#a0aac7',
    inkFaint:    '#5e688a',
    border:      'rgba(160,178,228,0.13)',
    accent:      '#5fc8d2',
    accent2:     '#f0b562',
    accentSoft:  'rgba(95,200,210,0.18)',
    accentInk:   '#b3ecf2',
    good:        '#6fd8a8',
    warn:        '#f0b562',
    bad:         '#ff8676',
    glow:
      'radial-gradient(900px 700px at 82% -10%, rgba(95,200,210,0.22) 0%, transparent 60%),' +
      'radial-gradient(700px 500px at -8% 92%, rgba(240,181,98,0.18) 0%, transparent 70%)',
  },
};

// Personas. Each carries its own avatar palette + accent that works across themes.
// Accents are saturation-matched (oklch lightness ~0.62, chroma ~0.12) so the four
// personas read as a family rather than four random colors.
const PERSONAS = {
  maya: {
    name: 'Maya',
    role: 'Friendly best friend',
    bio: 'Warm, encouraging, loves casual chat about everyday life.',
    initial: 'M',
    avatarBg: 'linear-gradient(135deg, #f7c6a7 0%, #d97757 55%, #a44a2a 100%)',
    accent: '#d97757',
    speaks: ['Daily life', 'Free chat', 'Roleplay'],
  },
  leo: {
    name: 'Leo',
    role: 'Cool mentor',
    bio: 'Confident and clear. Coaches you for interviews and meetings.',
    initial: 'L',
    avatarBg: 'linear-gradient(135deg, #b3c7e6 0%, #4a6fa5 55%, #233f70 100%)',
    accent: '#4a6fa5',
    speaks: ['Business', 'Academic', 'Free chat'],
  },
  sofia: {
    name: 'Sofia',
    role: 'Academic prof',
    bio: 'Precise and thoughtful. Pushes your vocabulary and structure.',
    initial: 'S',
    avatarBg: 'linear-gradient(135deg, #d6c4ee 0%, #7e5aaf 55%, #3f2978 100%)',
    accent: '#7e5aaf',
    speaks: ['Academic', 'Business', 'Debates'],
    enabled: false,
  },
  theo: {
    name: 'Theo',
    role: 'Chill traveler',
    bio: 'Easygoing. Helps you order coffee in Lisbon or barter in Bangkok.',
    initial: 'T',
    avatarBg: 'linear-gradient(135deg, #b6d6bd 0%, #5a8c6e 55%, #2a5340 100%)',
    accent: '#5a8c6e',
    speaks: ['Travel', 'Daily life', 'Free chat'],
    enabled: false,
  },
};

// Difficulty + feedback intensities (presentational only).
const DIFFICULTIES = {
  beginner:     { label: 'Beginner',     cefr: 'A1 · A2', tagline: 'Short sentences, gentle pace.' },
  intermediate: { label: 'Intermediate', cefr: 'B1 · B2', tagline: 'Real conversation, mixed speed.' },
  advanced:     { label: 'Advanced',     cefr: 'C1 · C2', tagline: 'Nuance, idioms, fast cadence.' },
};

const FEEDBACKS = {
  gentle:   { label: 'Gentle',   tagline: 'Confidence first. Surface only the biggest issues.' },
  balanced: { label: 'Balanced', tagline: 'Praise wins, flag patterns worth fixing.' },
  strict:   { label: 'Strict',   tagline: 'Catch everything. Suitable for exam prep.' },
};

// Active persona list (filtered to currently-enabled tutors).
window.__activePersonas = () => Object.fromEntries(
  Object.entries(window.PERSONAS).filter(([, v]) => v.enabled !== false)
);

Object.assign(window, { THEMES, PERSONAS, DIFFICULTIES, FEEDBACKS });

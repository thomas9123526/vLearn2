// Intermediate scenario brief — shown between picking a topic and starting
// the live conversation. Sets the scene: role, setting, objectives, useful
// phrases, expected length, recommended persona.

const { useState: uSd, useMemo: uMd } = React;

// Scenario-specific briefs. Keyed by scenario.title. Fallback to a generic
// brief for any title not listed.
const SCENARIO_BRIEFS = {
  'Airport check-in': {
    setting: 'Terminal 3 · 06:42 · long line at Skyhigh Airways.',
    youAre: 'You · a traveler with one carry-on and a tight connection.',
    theyAre: 'an agent who has seen it all before sunrise.',
    twist: 'Your bag is 2.4 kg over and your gate just changed.',
    objectives: [
      'Confirm the new gate without sounding panicked.',
      'Negotiate the bag weight politely.',
      'Ask about a faster security lane.',
    ],
    phrases: [
      'Could you double-check the gate for me?',
      'Is there any flexibility on the weight?',
      'Where would I find priority security?',
    ],
    vibe: 'polite urgency',
  },
  'First date': {
    setting: 'A small wine bar with mismatched chairs · Tuesday, 7:48 PM.',
    youAre: 'You · curious but a little nervous.',
    theyAre: 'a designer who likes hiking and very dry humor.',
    twist: 'They open with “So… what’s the weirdest thing you’ve eaten?”',
    objectives: [
      'Keep the volley going — ask before you answer.',
      'Drop one specific detail (smell, place, year).',
      'Spot if they’re flirting and flirt back lightly.',
    ],
    phrases: [
      'Honestly? Probably… and yours?',
      'That’s very specific — go on.',
      'I’d be terrible at that. Teach me.',
    ],
    vibe: 'light · curious',
  },
  'Job interview': {
    setting: 'Glass meeting room · second-round panel · 35 min booked.',
    youAre: 'You · final-round candidate for a product role.',
    theyAre: 'a hiring manager and a senior engineer.',
    twist: 'They ask for a failure story — and a number.',
    objectives: [
      'Structure your answer (situation → action → result).',
      'Quantify at least one outcome.',
      'Ask one strong, specific question at the end.',
    ],
    phrases: [
      'I’d break it into three parts.',
      'The result was roughly a 22% lift, measured over six weeks.',
      'How does the team know it’s shipped the right thing?',
    ],
    vibe: 'composed · specific',
  },
  'Order at a café': {
    setting: 'Tiny third-wave coffee shop · only oat milk left · 1 barista.',
    youAre: 'You · running late, wants something that isn’t on the menu.',
    theyAre: 'a barista with strong opinions on espresso.',
    twist: 'They suggest a “better” drink — politely push back.',
    objectives: [
      'Order off-menu without sounding rude.',
      'Handle the alt-milk surcharge gracefully.',
      'Leave room for small talk.',
    ],
    phrases: [
      'Could I get something a bit closer to a flat white?',
      'Oat is fine — what’s the extra?',
      'Busy morning?',
    ],
    vibe: 'warm · efficient',
  },
  'Negotiate a raise': {
    setting: 'Your manager’s desk, Thursday 4pm · cycle just ended.',
    youAre: 'You · two strong quarters in a row, nervous to ask.',
    theyAre: 'a fair manager who hates surprises.',
    twist: 'They counter with a title instead of money.',
    objectives: [
      'Lead with impact, not feelings.',
      'Anchor a specific number.',
      'Hold the silence after you ask.',
    ],
    phrases: [
      'I want to walk you through the two things I shipped this half.',
      'Based on that, I’d like to talk about $X.',
      'I hear you — let me think about how those compare.',
    ],
    vibe: 'firm · friendly',
  },
};

const DEFAULT_BRIEF = (s) => ({
  setting: `${s.title} · a realistic, slightly noisy environment.`,
  youAre: 'You · the speaker. Confident enough to keep going when stuck.',
  theyAre: 'a native English speaker who plays this scene often.',
  twist: 'They’ll improvise — expect at least one curveball.',
  objectives: [
    'Use full sentences instead of one-word replies.',
    'Ask one follow-up question.',
    'Recover gracefully when you don’t catch a word.',
  ],
  phrases: [
    'Sorry — could you say that again?',
    'I don’t know the word, but it’s like…',
    'What would you say in this situation?',
  ],
  vibe: 'natural · unhurried',
});

// Tiny stylized illustration — chosen by category
const SceneIllustration = ({ scenario, theme, accent }) => {
  const cat = scenario.cat;
  // Simple scene compositions per category. All built from primitives.
  const scenes = {
    travel: (
      <>
        <rect x="0" y="0" width="320" height="180" fill={accent} opacity=".08" />
        <path d="M0 130 Q 80 110 160 130 T 320 130 L 320 180 L 0 180 Z" fill={accent} opacity=".22" />
        <circle cx="48" cy="46" r="18" fill="#fff" />
        <circle cx="68" cy="42" r="14" fill="#fff" />
        {/* Plane */}
        <g transform="translate(200 60) rotate(-12)">
          <path d="M0 0 L 70 -6 L 80 0 L 70 6 Z" fill={accent} />
          <path d="M30 0 L 36 -18 L 44 -16 L 42 0 Z" fill={accent} />
          <path d="M30 0 L 36 18 L 44 16 L 42 0 Z" fill={accent} opacity=".85" />
        </g>
        {/* Suitcase */}
        <g transform="translate(40 130)">
          <rect x="0" y="6" width="48" height="34" rx="5" fill={accent} />
          <rect x="14" y="0" width="20" height="8" rx="2" fill="none" stroke={accent} strokeWidth="3" />
          <line x1="0" y1="22" x2="48" y2="22" stroke="#fff" strokeWidth="2" opacity=".6" />
        </g>
      </>
    ),
    biz: (
      <>
        <rect x="0" y="0" width="320" height="180" fill={accent} opacity=".08" />
        {/* Table */}
        <rect x="40" y="120" width="240" height="14" rx="3" fill={accent} opacity=".35" />
        {/* Laptop */}
        <g transform="translate(120 70)">
          <rect x="0" y="0" width="80" height="50" rx="4" fill={accent} />
          <rect x="6" y="6" width="68" height="36" rx="2" fill="#fff" opacity=".25" />
          <rect x="-8" y="50" width="96" height="6" rx="2" fill={accent} opacity=".7" />
        </g>
        {/* Chart */}
        <g transform="translate(220 50)">
          <rect x="0" y="40" width="10" height="22" fill={accent} opacity=".7" />
          <rect x="14" y="28" width="10" height="34" fill={accent} opacity=".85" />
          <rect x="28" y="14" width="10" height="48" fill={accent} />
        </g>
        {/* Coffee */}
        <circle cx="60" cy="100" r="14" fill={accent} opacity=".4" />
        <circle cx="60" cy="100" r="10" fill="#fff" />
      </>
    ),
    daily: (
      <>
        <rect x="0" y="0" width="320" height="180" fill={accent} opacity=".08" />
        {/* Café table */}
        <ellipse cx="160" cy="138" rx="120" ry="14" fill={accent} opacity=".25" />
        {/* Two cups */}
        <g transform="translate(110 90)">
          <rect x="0" y="0" width="34" height="40" rx="4" fill={accent} />
          <path d="M34 8 Q 46 8 46 20 Q 46 32 34 32" stroke={accent} strokeWidth="4" fill="none" />
          <ellipse cx="17" cy="2" rx="14" ry="3" fill="#fff" opacity=".4" />
        </g>
        <g transform="translate(180 96)">
          <rect x="0" y="0" width="30" height="34" rx="4" fill={accent} opacity=".8" />
          <ellipse cx="15" cy="2" rx="12" ry="3" fill="#fff" opacity=".4" />
        </g>
        {/* Window */}
        <rect x="20" y="20" width="60" height="46" rx="4" fill="none" stroke={accent} strokeWidth="2" opacity=".6" />
        <line x1="50" y1="20" x2="50" y2="66" stroke={accent} strokeWidth="2" opacity=".6" />
      </>
    ),
    school: (
      <>
        <rect x="0" y="0" width="320" height="180" fill={accent} opacity=".08" />
        {/* Lectern */}
        <path d="M140 80 L 180 80 L 188 140 L 132 140 Z" fill={accent} />
        <rect x="155" y="60" width="10" height="22" fill={accent} opacity=".7" />
        {/* Books */}
        <g transform="translate(40 120)">
          <rect x="0" y="0" width="44" height="10" fill={accent} opacity=".85" />
          <rect x="2" y="-10" width="44" height="10" fill={accent} opacity=".55" />
          <rect x="6" y="-20" width="44" height="10" fill={accent} />
        </g>
        {/* Lamp */}
        <g transform="translate(240 50)">
          <path d="M0 0 L 28 0 L 18 30 L 10 30 Z" fill={accent} />
          <rect x="13" y="30" width="2" height="50" fill={accent} />
          <rect x="0" y="80" width="28" height="4" rx="1" fill={accent} />
        </g>
      </>
    ),
    roleplay: (
      <>
        <rect x="0" y="0" width="320" height="180" fill={accent} opacity=".08" />
        {/* Stage */}
        <ellipse cx="160" cy="150" rx="120" ry="14" fill={accent} opacity=".3" />
        {/* Two masks */}
        <g transform="translate(80 60)">
          <ellipse cx="0" cy="0" rx="32" ry="38" fill={accent} />
          <circle cx="-10" cy="-6" r="3" fill="#fff" />
          <circle cx="10" cy="-6" r="3" fill="#fff" />
          <path d="M-12 14 Q 0 22 12 14" stroke="#fff" strokeWidth="3" fill="none" />
        </g>
        <g transform="translate(220 60)">
          <ellipse cx="0" cy="0" rx="32" ry="38" fill={accent} opacity=".75" />
          <circle cx="-10" cy="-6" r="3" fill="#fff" />
          <circle cx="10" cy="-6" r="3" fill="#fff" />
          <path d="M-12 18 Q 0 8 12 18" stroke="#fff" strokeWidth="3" fill="none" />
        </g>
        {/* Sparkles */}
        <circle cx="40" cy="30" r="3" fill={accent} />
        <circle cx="280" cy="30" r="3" fill={accent} />
        <circle cx="160" cy="20" r="2" fill={accent} />
      </>
    ),
    free: (
      <>
        <rect x="0" y="0" width="320" height="180" fill={accent} opacity=".08" />
        {/* Floating speech bubbles */}
        <path d="M40 40 Q 40 24 60 24 L 120 24 Q 140 24 140 44 Q 140 64 120 64 L 80 64 L 64 76 L 70 64 Q 40 60 40 40 Z" fill={accent} />
        <path d="M180 70 Q 180 56 198 56 L 260 56 Q 280 56 280 76 Q 280 94 260 94 L 220 94 L 210 106 L 214 94 Q 180 92 180 70 Z" fill={accent} opacity=".7" />
        <circle cx="80" cy="44" r="3" fill="#fff" />
        <circle cx="90" cy="44" r="3" fill="#fff" />
        <circle cx="100" cy="44" r="3" fill="#fff" />
      </>
    ),
  };
  return (
    <svg viewBox="0 0 320 180" style={{ display: 'block', width: '100%', height: '100%' }}>
      {scenes[cat] || scenes.free}
    </svg>
  );
};

function ScenarioDetailScreen({ theme, persona, nav, layout, state }) {
  const isDesktop = layout === 'desktop';
  const scenario = state.scenario || SCENARIOS[6];
  const brief = SCENARIO_BRIEFS[scenario.title] || DEFAULT_BRIEF(scenario);
  const p = PERSONAS[persona];

  // CEFR-ish pill content per scenario tag
  const tagInfo = {
    A1: { label: 'Beginner', tone: theme.good },
    A2: { label: 'Easy',     tone: theme.good },
    B1: { label: 'Comfortable', tone: theme.warn },
    B2: { label: 'Stretching', tone: theme.warn },
    C1: { label: 'Challenging', tone: theme.bad },
    C2: { label: 'Native-paced', tone: theme.bad },
    any: { label: 'Any level', tone: theme.inkSoft },
  };
  const ti = tagInfo[scenario.tag] || tagInfo.any;

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
      <div style={{ position: 'absolute', inset: 0, background: theme.glow, pointerEvents: 'none' }} />

      {/* Header */}
      <div style={{ padding: isDesktop ? '14px 28px' : '12px 16px', display: 'flex', alignItems: 'center', gap: 12, position: 'relative', zIndex: 2 }}>
        <button onClick={() => nav('scenarios')} style={{ width: 34, height: 34, borderRadius: 999, border: 'none', background: theme.surfaceAlt, color: theme.ink, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="back" size={16} />
        </button>
        <div style={{ flex: 1, fontSize: 12, color: theme.inkFaint, fontFamily: 'JetBrains Mono, monospace', letterSpacing: '.14em', textTransform: 'uppercase' }}>
          Brief · {CATS.find(c => c.id === scenario.cat)?.label || 'Scenario'}
        </div>
      </div>

      {/* Scroll body */}
      <div style={{ flex: 1, overflowY: 'auto', padding: isDesktop ? '8px 28px 140px' : '4px 16px 140px', position: 'relative', zIndex: 1 }}>
        <div style={{ maxWidth: isDesktop ? 920 : '100%', margin: '0 auto' }}>

          {/* Hero card */}
          <Card className="ft-slide-up" theme={theme} padding={0} style={{
            overflow: 'hidden', marginBottom: 18,
            background: `linear-gradient(135deg, ${theme.surface}, ${theme.surfaceAlt})`,
            border: `1px solid ${theme.border}`,
          }}>
            <div style={{ display: isDesktop ? 'grid' : 'block', gridTemplateColumns: isDesktop ? '1fr 1fr' : 'unset' }}>
              {/* Illustration */}
              <div style={{ height: isDesktop ? 240 : 160, background: theme.accentSoft, position: 'relative' }}>
                <SceneIllustration scenario={scenario} theme={theme} accent={theme.accent} />
                {/* Floating chips */}
                <div style={{ position: 'absolute', top: 12, left: 12, display: 'flex', gap: 6 }}>
                  <span style={{ padding: '4px 10px', borderRadius: 999, background: theme.surface, color: theme.ink, fontSize: 10, fontFamily: 'JetBrains Mono, monospace', letterSpacing: '.1em', textTransform: 'uppercase', border: `1px solid ${theme.border}` }}>{scenario.tag}</span>
                  <span style={{ padding: '4px 10px', borderRadius: 999, background: theme.surface, color: theme.ink, fontSize: 10, fontFamily: 'JetBrains Mono, monospace', letterSpacing: '.1em', textTransform: 'uppercase', border: `1px solid ${theme.border}` }}>~{scenario.mins} min</span>
                </div>
              </div>
              {/* Headline */}
              <div style={{ padding: isDesktop ? '28px 32px' : '20px 18px' }}>
                <div style={{ fontSize: 11, letterSpacing: '.18em', color: theme.inkFaint, textTransform: 'uppercase', marginBottom: 6, fontFamily: 'JetBrains Mono, monospace' }}>Scene</div>
                <h1 style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 42 : 30, fontWeight: 400, margin: 0, letterSpacing: '-0.02em', lineHeight: 1.05 }}>
                  {scenario.title}
                </h1>
                <p style={{ marginTop: 12, color: theme.inkSoft, fontSize: isDesktop ? 15 : 13, lineHeight: 1.55 }}>
                  {brief.setting}
                </p>
                <div style={{ marginTop: 14, display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: ti.tone, letterSpacing: '.1em', textTransform: 'uppercase' }}>
                  <span style={{ width: 6, height: 6, borderRadius: 3, background: ti.tone }} />
                  {ti.label}
                  <span style={{ color: theme.inkFaint }}>·</span>
                  <span style={{ color: theme.inkSoft, textTransform: 'none', letterSpacing: '.02em', fontFamily: 'inherit' }}>vibe: <span style={{ fontStyle: 'italic' }}>{brief.vibe}</span></span>
                </div>
              </div>
            </div>
          </Card>

          {/* Roles */}
          <div className="ft-slide-up" style={{ display: 'grid', gridTemplateColumns: isDesktop ? '1fr 1fr' : '1fr', gap: 12, marginBottom: 18, animationDelay: '.05s' }}>
            <Card theme={theme} padding={16}>
              <div style={{ fontSize: 10, letterSpacing: '.18em', color: theme.inkFaint, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace' }}>You play</div>
              <div style={{ marginTop: 6, fontSize: 15, color: theme.ink, lineHeight: 1.45 }}>{brief.youAre}</div>
            </Card>
            <Card theme={theme} padding={16}>
              <div style={{ fontSize: 10, letterSpacing: '.18em', color: theme.inkFaint, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace' }}>{p.name} plays</div>
              <div style={{ marginTop: 6, fontSize: 15, color: theme.ink, lineHeight: 1.45 }}>{brief.theyAre}</div>
            </Card>
          </div>

          {/* Twist banner */}
          <div className="ft-slide-up" style={{
            display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 18,
            padding: '14px 16px', borderRadius: 14,
            background: `linear-gradient(135deg, ${theme.accent}1a, ${theme.accent}0a)`,
            border: `1px dashed ${theme.accent}55`,
            animationDelay: '.1s',
          }}>
            <div style={{ width: 28, height: 28, borderRadius: 8, background: theme.accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontFamily: 'Instrument Serif, serif', fontStyle: 'italic', fontSize: 18 }}>?!</div>
            <div>
              <div style={{ fontSize: 10, letterSpacing: '.18em', color: theme.accent, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', marginBottom: 4 }}>The twist</div>
              <div style={{ fontSize: 14, color: theme.ink, lineHeight: 1.5 }}>{brief.twist}</div>
            </div>
          </div>

          {/* Objectives + Phrases */}
          <div className="ft-slide-up" style={{ display: 'grid', gridTemplateColumns: isDesktop ? '1fr 1fr' : '1fr', gap: 12, marginBottom: 20, animationDelay: '.15s' }}>
            <Card theme={theme} padding={18}>
              <div style={{ fontSize: 10, letterSpacing: '.18em', color: theme.inkFaint, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', marginBottom: 12 }}>What to aim for</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {brief.objectives.map((o, i) => (
                  <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                    <div style={{ width: 22, height: 22, borderRadius: 11, background: theme.accentSoft, color: theme.accent, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontSize: 11, fontWeight: 700, fontFamily: 'JetBrains Mono, monospace' }}>{i + 1}</div>
                    <div style={{ fontSize: 14, color: theme.ink, lineHeight: 1.5 }}>{o}</div>
                  </div>
                ))}
              </div>
            </Card>
            <Card theme={theme} padding={18}>
              <div style={{ fontSize: 10, letterSpacing: '.18em', color: theme.inkFaint, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', marginBottom: 12 }}>Phrases worth stealing</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {brief.phrases.map((ph, i) => (
                  <div key={i} style={{
                    padding: '10px 12px', borderRadius: 10,
                    background: theme.surfaceAlt, border: `1px solid ${theme.border}`,
                    fontFamily: 'Instrument Serif, serif', fontStyle: 'italic',
                    fontSize: 15, color: theme.ink, lineHeight: 1.4,
                    position: 'relative',
                  }}>
                    <span style={{ position: 'absolute', left: 8, top: 2, color: theme.accent, fontSize: 18 }}>“</span>
                    <span style={{ paddingLeft: 12 }}>{ph}</span>
                  </div>
                ))}
              </div>
            </Card>
          </div>

          {/* Persona pairing */}
          <Card className="ft-slide-up" theme={theme} padding={14} style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 20, animationDelay: '.2s' }}>
            <Avatar persona={persona.toLowerCase ? persona.toLowerCase() : persona} size={48} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 11, color: theme.inkFaint, fontFamily: 'JetBrains Mono, monospace', letterSpacing: '.14em', textTransform: 'uppercase' }}>Speaking with</div>
              <div style={{ fontWeight: 600, fontSize: 15, color: theme.ink }}>{p.name} <span style={{ color: theme.inkSoft, fontWeight: 400 }}>· {p.role}</span></div>
            </div>
            <button onClick={() => nav('settings')} style={{ padding: '8px 14px', borderRadius: 999, border: `1px solid ${theme.border}`, background: theme.surface, color: theme.ink, fontSize: 12, fontWeight: 500, cursor: 'pointer', fontFamily: 'inherit', whiteSpace: 'nowrap' }}>Change</button>
          </Card>
        </div>
      </div>

      {/* Sticky CTA dock */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: isDesktop ? '16px 28px 22px' : '14px 16px 18px',
        background: `linear-gradient(to top, ${theme.bg} 60%, transparent)`,
        zIndex: 3,
      }}>
        <div style={{ maxWidth: 920, margin: '0 auto', display: 'flex', gap: 10, alignItems: 'center' }}>
          <button onClick={() => nav('scenarios')} style={{
            padding: '12px 18px', borderRadius: 14, border: `1px solid ${theme.border}`,
            background: theme.surface, color: theme.ink, fontSize: 13, fontWeight: 500,
            cursor: 'pointer', fontFamily: 'inherit', flexShrink: 0,
          }}>Back to topics</button>
          <button onClick={() => nav('convo')} style={{
            flex: 1, padding: '14px 18px', borderRadius: 14, border: 'none',
            background: theme.accent, color: '#fff',
            fontSize: 14, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
            boxShadow: `0 12px 26px ${theme.accent}55`,
            transition: 'transform .12s ease',
          }}
            onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-1px)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; }}
          >
            <Icon name="mic" size={16} stroke="#fff" />
            Start speaking
            <span style={{ opacity: .7, fontFamily: 'JetBrains Mono, monospace', fontSize: 11, marginLeft: 6 }}>{scenario.mins}m</span>
          </button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ScenarioDetailScreen });

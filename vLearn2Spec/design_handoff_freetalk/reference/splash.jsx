// Splash / first screen for FreeTalk.
// Wordmark + date + slogan, floating playful icons, "Tap to begin" CTA.

const { useState: uSs, useEffect: uEs, useMemo: uMs } = React;

// Tiny SVG glyph icons — stylized, friendly. Each is one expression of speech.
const FUN_GLYPHS = {
  bubble: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <path d="M10 14 Q 10 6 18 6 L 46 6 Q 54 6 54 14 L 54 36 Q 54 44 46 44 L 26 44 L 16 54 L 18 44 Q 10 44 10 36 Z" fill={color} />
      <circle cx="24" cy="25" r="3" fill="#fff" />
      <circle cx="34" cy="25" r="3" fill="#fff" />
      <path d="M22 32 Q 28 38 36 32" stroke="#fff" strokeWidth="2.2" fill="none" strokeLinecap="round" />
    </svg>
  ),
  mic: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <rect x="24" y="8" width="16" height="30" rx="8" fill={color} />
      <path d="M14 32 Q 14 50 32 50 Q 50 50 50 32" stroke={color} strokeWidth="4" fill="none" strokeLinecap="round" />
      <rect x="29" y="50" width="6" height="8" fill={color} />
      <rect x="20" y="58" width="24" height="3" rx="1.5" fill={color} />
    </svg>
  ),
  mouth: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <ellipse cx="32" cy="32" rx="24" ry="14" fill={color} />
      <path d="M10 32 Q 32 38 54 32 Q 32 26 10 32 Z" fill="#fff" opacity=".25" />
      <ellipse cx="32" cy="32" rx="6" ry="9" fill="#3a1212" />
    </svg>
  ),
  globe: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <circle cx="32" cy="32" r="24" fill={color} />
      <ellipse cx="32" cy="32" rx="24" ry="10" fill="none" stroke="#fff" strokeWidth="2" opacity=".8" />
      <ellipse cx="32" cy="32" rx="10" ry="24" fill="none" stroke="#fff" strokeWidth="2" opacity=".8" />
      <path d="M8 32 H 56" stroke="#fff" strokeWidth="2" opacity=".8" />
      <circle cx="22" cy="22" r="3" fill="#fff" />
      <circle cx="42" cy="38" r="2.5" fill="#fff" />
    </svg>
  ),
  letterA: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <rect x="6" y="6" width="52" height="52" rx="12" fill={color} />
      <text x="32" y="46" textAnchor="middle" fontFamily="Instrument Serif, serif" fontSize="40" fill="#fff" fontStyle="italic">A</text>
    </svg>
  ),
  star: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <path d="M32 6 L 39 24 L 58 26 L 44 39 L 48 58 L 32 48 L 16 58 L 20 39 L 6 26 L 25 24 Z" fill={color} />
      <circle cx="32" cy="32" r="3" fill="#fff" />
    </svg>
  ),
  wink: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <circle cx="32" cy="32" r="26" fill={color} />
      <circle cx="22" cy="26" r="3" fill="#fff" />
      <path d="M37 26 Q 42 22 47 26" stroke="#fff" strokeWidth="2.4" fill="none" strokeLinecap="round" />
      <path d="M20 40 Q 32 50 44 40" stroke="#fff" strokeWidth="2.8" fill="none" strokeLinecap="round" />
    </svg>
  ),
  heart: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <path d="M32 54 C 12 40 6 30 12 18 C 18 8 30 12 32 22 C 34 12 46 8 52 18 C 58 30 52 40 32 54 Z" fill={color} />
    </svg>
  ),
  cloud: (color) => (
    <svg viewBox="0 0 64 64" width="100%" height="100%">
      <path d="M14 42 Q 4 42 6 32 Q 8 24 18 24 Q 20 14 32 14 Q 44 14 46 24 Q 58 24 58 34 Q 58 44 48 44 Z" fill={color} />
      <circle cx="24" cy="34" r="2.5" fill="#fff" />
      <circle cx="34" cy="34" r="2.5" fill="#fff" />
      <path d="M26 39 Q 30 42 34 39" stroke="#fff" strokeWidth="2" fill="none" strokeLinecap="round" />
    </svg>
  ),
};

// Positions are normalized: [leftPct, topPct, sizePx, rotateDeg, delay]
const SPLASH_LAYOUT_MOBILE = [
  { id: 'bubble',  pos: [10, 14, 64, -8, 0],   color: 'maya' },
  { id: 'mic',     pos: [78, 10, 56, 12, .2],  color: 'leo' },
  { id: 'star',    pos: [6, 38, 44, 18, .35],  color: 'theo' },
  { id: 'globe',   pos: [82, 36, 62, -6, .15], color: 'sofia' },
  { id: 'heart',   pos: [14, 64, 40, -14, .4], color: 'theo' },
  { id: 'wink',    pos: [80, 64, 58, 8, .25],  color: 'maya' },
  { id: 'letterA', pos: [4, 82, 46, -10, .45], color: 'leo' },
  { id: 'cloud',   pos: [76, 84, 58, 6, .3],   color: 'sofia' },
];
const SPLASH_LAYOUT_DESKTOP = [
  { id: 'bubble',  pos: [8, 16, 84, -10, 0],   color: 'maya' },
  { id: 'mic',     pos: [86, 12, 72, 14, .2],  color: 'leo' },
  { id: 'mouth',   pos: [4, 70, 78, 6, .15],   color: 'maya' },
  { id: 'star',    pos: [82, 28, 56, 18, .35], color: 'theo' },
  { id: 'globe',   pos: [88, 60, 84, -6, .1],  color: 'sofia' },
  { id: 'heart',   pos: [10, 32, 54, -12, .25],color: 'theo' },
  { id: 'wink',    pos: [88, 82, 68, 8, .45],  color: 'maya' },
  { id: 'letterA', pos: [12, 84, 60, -8, .5],  color: 'leo' },
  { id: 'cloud',   pos: [50, 8, 60, 4, .2],    color: 'sofia' },
];

function SplashScreen({ theme, nav, layout }) {
  const isDesktop = layout === 'desktop';
  const layoutData = isDesktop ? SPLASH_LAYOUT_DESKTOP : SPLASH_LAYOUT_MOBILE;
  const today = uMs(() => {
    const d = new Date();
    return {
      day: String(d.getDate()).padStart(2, '0'),
      month: d.toLocaleString('en', { month: 'short' }).toUpperCase(),
      year: d.getFullYear(),
      weekday: d.toLocaleString('en', { weekday: 'long' }).toUpperCase(),
    };
  }, []);

  // Persona accent map (uses PERSONAS lookup for diverse harmonious colors)
  const colorFor = (key) => (PERSONAS[key] ? PERSONAS[key].accent : theme.accent);

  // Subtle entrance for the wordmark
  const [ready, setReady] = uSs(false);
  uEs(() => { const t = setTimeout(() => setReady(true), 60); return () => clearTimeout(t); }, []);

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative', overflow: 'hidden',
      background: theme.bg, color: theme.ink,
    }}>
      {/* Soft radial glow */}
      <div style={{ position: 'absolute', inset: 0, background: theme.glow, pointerEvents: 'none' }} />
      {/* Color wash centered on logo */}
      <div style={{
        position: 'absolute', left: '50%', top: '50%', width: isDesktop ? 720 : 460, height: isDesktop ? 720 : 460,
        transform: 'translate(-50%,-50%)',
        background: `radial-gradient(circle, ${theme.accent}22 0%, transparent 65%)`,
        pointerEvents: 'none',
      }} />

      {/* Floating playful icons */}
      {layoutData.map((g, i) => {
        const [l, t, s, rot, delay] = g.pos;
        return (
          <div
            key={g.id + i}
            style={{
              position: 'absolute',
              left: `${l}%`, top: `${t}%`,
              width: s, height: s,
              transform: `rotate(${rot}deg)`,
              opacity: 0,
              animation: `ft-splash-in .9s cubic-bezier(.34,1.56,.64,1) ${delay}s forwards, ft-splash-bob ${4 + i * .25}s ease-in-out ${delay + .9}s infinite`,
              filter: 'drop-shadow(0 8px 16px rgba(0,0,0,.08))',
              pointerEvents: 'none',
            }}
          >
            {FUN_GLYPHS[g.id](colorFor(g.color))}
          </div>
        );
      })}

      {/* Centerpiece */}
      <div style={{
        position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', textAlign: 'center', padding: '0 24px',
      }}>
        {/* Date band */}
        <div className="ft-fade-in" style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: isDesktop ? 12 : 11,
          letterSpacing: '.22em', color: theme.inkFaint,
          display: 'flex', alignItems: 'center', gap: 10, marginBottom: isDesktop ? 28 : 22,
        }}>
          <span style={{ width: 24, height: 1, background: theme.border }} />
          <span>{today.weekday} · {today.day} {today.month} {today.year}</span>
          <span style={{ width: 24, height: 1, background: theme.border }} />
        </div>

        {/* Monogram badge */}
        <div className="ft-pop-in" style={{
          width: isDesktop ? 84 : 68, height: isDesktop ? 84 : 68,
          borderRadius: isDesktop ? 24 : 20,
          background: theme.accent, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Instrument Serif, serif', fontStyle: 'italic',
          fontSize: isDesktop ? 56 : 44, lineHeight: 1,
          boxShadow: `0 18px 40px ${theme.accent}44, inset 0 -2px 6px rgba(0,0,0,.15), inset 0 2px 6px rgba(255,255,255,.3)`,
          marginBottom: isDesktop ? 22 : 18, position: 'relative',
        }}>
          <span style={{ transform: 'translateY(2%)' }}>F</span>
          {/* Animated speech dot */}
          <div style={{
            position: 'absolute', top: -6, right: -6,
            width: 18, height: 18, borderRadius: 9, background: '#fff',
            border: `3px solid ${theme.accent}`,
            animation: 'ft-blink 1.6s ease-in-out infinite',
          }} />
        </div>

        {/* Wordmark */}
        <h1 style={{
          fontFamily: 'Instrument Serif, serif',
          fontSize: isDesktop ? 108 : 72,
          fontWeight: 400, margin: 0, letterSpacing: '-0.03em',
          lineHeight: .95, color: theme.ink,
          opacity: ready ? 1 : 0, transform: ready ? 'none' : 'translateY(8px)',
          transition: 'opacity .7s ease .1s, transform .7s ease .1s',
        }}>
          Free<span style={{ fontStyle: 'italic', color: theme.accent }}>Talk</span>
        </h1>

        {/* Slogan */}
        <p className="ft-slide-up" style={{
          fontFamily: 'Instrument Serif, serif', fontStyle: 'italic',
          fontSize: isDesktop ? 22 : 17, color: theme.inkSoft,
          margin: isDesktop ? '10px 0 0' : '8px 0 0',
          letterSpacing: '.005em', animationDelay: '.3s',
        }}>
          Open your mouth. Find your voice.
        </p>

        {/* CTA */}
        <button
          onClick={() => nav('signup')}
          className="ft-slide-up"
          style={{
            marginTop: isDesktop ? 44 : 36,
            padding: isDesktop ? '14px 28px' : '12px 22px',
            borderRadius: 999, border: 'none',
            background: theme.ink, color: theme.bg,
            fontFamily: 'inherit', fontSize: isDesktop ? 14 : 13, fontWeight: 600,
            cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 10,
            boxShadow: `0 14px 30px ${theme.accent}33`,
            animationDelay: '.45s',
            transition: 'transform .15s ease',
          }}
          onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-1px)'; }}
          onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; }}
        >
          {t('Tap to begin')}
          <span style={{ display: 'inline-flex', width: 22, height: 22, borderRadius: 11, background: theme.accent, color: '#fff', alignItems: 'center', justifyContent: 'center', fontSize: 11 }}>→</span>
        </button>

        {/* Bottom-left ID hint */}
        <div className="ft-fade-in" style={{
          position: 'absolute', left: isDesktop ? 32 : 18, bottom: isDesktop ? 32 : 22,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 11, letterSpacing: '.06em',
          color: theme.inkFaint, padding: '6px 10px', borderRadius: 8,
          border: `1px dashed ${theme.border}`, background: theme.surface + 'aa',
          backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
          animationDelay: '.7s',
        }}>ㄱ123456789</div>
        {/* Bottom-right ID hint */}
        <div className="ft-fade-in" style={{
          position: 'absolute', right: isDesktop ? 32 : 18, bottom: isDesktop ? 32 : 22,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 11, letterSpacing: '.06em',
          color: theme.inkFaint, padding: '6px 10px', borderRadius: 8,
          border: `1px dashed ${theme.border}`, background: theme.surface + 'aa',
          backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
          animationDelay: '.7s',
        }}>ㄱ987654321</div>

        {/* Tiny footer line */}
        <div className="ft-fade-in" style={{
          position: 'absolute', bottom: isDesktop ? 28 : 18, left: 0, right: 0, textAlign: 'center',
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10, letterSpacing: '.18em',
          color: theme.inkFaint, animationDelay: '.7s',
        }}>
          v 1.0 · WIN · ANDROID · MADE FOR SPEAKERS-TO-BE
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { SplashScreen });

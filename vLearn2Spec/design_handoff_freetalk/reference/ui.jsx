// UI primitives + shared components for FreeTalk.
// Icons, Avatar, Waveform, ScoreRing, ProgressBar, Buttons, Chips...

const { useState, useEffect, useRef, useMemo, createContext, useContext } = React;

// ── Icon set (single source of truth; thin 1.6 stroke) ───────────────────
const Icon = ({ name, size = 20, stroke = 'currentColor', fill = 'none', strokeWidth = 1.7 }) => {
  const paths = {
    home: <path d="M3 11.5L12 4l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1v-8.5z" />,
    chat: <path d="M21 12a8 8 0 0 1-11.7 7.1L4 20l1-4.2A8 8 0 1 1 21 12z" />,
    chart: <path d="M4 20V8M10 20V4M16 20v-9M22 20H2" />,
    user: <><circle cx="12" cy="8" r="4" /><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6" /></>,
    cog: <><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1A2 2 0 1 1 4.3 17l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8L4.2 7A2 2 0 1 1 7 4.3l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1A2 2 0 1 1 19.7 7l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z" /></>,
    mic: <><rect x="9" y="3" width="6" height="11" rx="3" /><path d="M5 11a7 7 0 0 0 14 0M12 18v3" /></>,
    play: <path d="M6 4l14 8-14 8V4z" fill={fill === 'none' ? stroke : fill} />,
    pause: <><rect x="6" y="4" width="4" height="16" rx="1" fill={stroke} /><rect x="14" y="4" width="4" height="16" rx="1" fill={stroke} /></>,
    check: <path d="M5 12l4.5 4.5L19 7" />,
    x: <path d="M6 6l12 12M18 6L6 18" />,
    arrow: <path d="M5 12h14M13 5l7 7-7 7" />,
    back: <path d="M19 12H5M11 5l-7 7 7 7" />,
    flame: <path d="M12 2c1 4 5 5 5 10a5 5 0 1 1-10 0c0-2 1-3 2-4-1 2 0 4 2 4 0-3-2-4 1-10z" />,
    book: <path d="M4 4h6a3 3 0 0 1 3 3v14a3 3 0 0 0-3-3H4V4zm16 0h-6a3 3 0 0 0-3 3v14a3 3 0 0 1 3-3h6V4z" />,
    bolt: <path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z" fill={stroke} />,
    plane: <path d="M2 14l20-7-5 14-4-7-3 8-2-5-6-3z" />,
    briefcase: <><rect x="3" y="7" width="18" height="13" rx="2" /><path d="M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2M3 13h18" /></>,
    coffee: <><path d="M4 8h13v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V8zM17 10h2a3 3 0 0 1 0 6h-2" /><path d="M7 4v2M11 4v2M15 4v2" /></>,
    grad: <path d="M2 9l10-5 10 5-10 5L2 9zM6 11v5c3 2 9 2 12 0v-5" />,
    heart: <path d="M12 21s-7-4.5-9.5-9A5.5 5.5 0 0 1 12 6a5.5 5.5 0 0 1 9.5 6c-2.5 4.5-9.5 9-9.5 9z" />,
    sparkle: <path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3zM19 17l.8 1.5 1.5.5-1.5.5L19 21l-.8-1.5-1.5-.5 1.5-.5z" />,
    plus: <path d="M12 5v14M5 12h14" />,
    search: <><circle cx="11" cy="11" r="7" /><path d="M21 21l-4.5-4.5" /></>,
    bell: <><path d="M6 8a6 6 0 0 1 12 0v5l2 3H4l2-3V8z" /><path d="M10 19a2 2 0 0 0 4 0" /></>,
    flag: <path d="M5 21V4h12l-2 4 2 4H7v9" />,
    target: <><circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="5" /><circle cx="12" cy="12" r="1.5" fill={stroke} /></>,
    globe: <><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18" /></>,
    moon: <path d="M21 13a9 9 0 1 1-10-10 7 7 0 0 0 10 10z" />,
    sun: <><circle cx="12" cy="12" r="4" /><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.5 4.5l2 2M17.5 17.5l2 2M4.5 19.5l2-2M17.5 6.5l2-2" /></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={stroke} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
      {paths[name]}
    </svg>
  );
};

// ── Persona avatar ──────────────────────────────────────────────────────
const Avatar = ({ persona, size = 56, pulse = false, ring = false, ringColor }) => {
  const p = PERSONAS[persona] || PERSONAS.maya;
  return (
    <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
      {pulse && (
        <>
          <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: p.accent, opacity: .35, animation: 'ft-pulse 1.8s ease-out infinite' }} />
          <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: p.accent, opacity: .35, animation: 'ft-pulse 1.8s ease-out infinite .6s' }} />
        </>
      )}
      <div style={{
        width: size, height: size, borderRadius: '50%', background: p.avatarBg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: '#fff', fontFamily: 'Instrument Serif, serif', fontSize: size * 0.5, fontWeight: 400,
        boxShadow: '0 6px 18px rgba(0,0,0,.12), inset 0 -2px 6px rgba(0,0,0,.18), inset 0 2px 6px rgba(255,255,255,.35)',
        border: ring ? `2px solid ${ringColor || '#fff'}` : 'none',
        position: 'relative', overflow: 'hidden',
      }}>
        <span style={{ transform: 'translateY(2%)', letterSpacing: '-0.02em' }}>{p.initial}</span>
        {/* Subtle inner highlight orbiting glow */}
        <div style={{ position: 'absolute', inset: -size*.3, background: 'conic-gradient(from 0deg, transparent 70%, rgba(255,255,255,.18) 80%, transparent 95%)', animation: 'ft-orbit 14s linear infinite', pointerEvents: 'none' }} />
      </div>
    </div>
  );
};

// ── Talking avatar (stylized animated face) ─────────────────────────────
// An original geometric portrait, distinct per persona. Mouth animates
// continuously while `mode === 'speaking'`; eyes blink on a long cycle;
// "listening" tilts the head and lifts a brow. Pure SVG + CSS keyframes.
const TalkingAvatar = ({ persona, mode = 'idle', size = 220, theme }) => {
  const p = PERSONAS[persona] || PERSONAS.maya;
  const speaking = mode === 'speaking';
  const listening = mode === 'listening';
  const thinking = mode === 'thinking';

  // Per-persona look. Skin/hair/accessory kept stylized + warm. No realism.
  const looks = {
    maya: {
      skin: '#f4cba3', skinShade: '#e0a880',
      hair: '#3a2418', hairLight: '#5a3624',
      // Long wavy hair around face
      hairBack: 'M50 110 Q 50 50 100 40 Q 150 50 150 110 L 150 165 Q 145 175 130 178 L 70 178 Q 55 175 50 165 Z',
      hairFront: 'M62 88 Q 70 64 100 60 Q 130 64 138 88 Q 132 78 118 82 Q 108 70 100 76 Q 92 70 82 82 Q 68 78 62 88 Z',
      cheek: '#f0a98a',
      lip: '#c5564b',
      accessory: null,
    },
    leo: {
      skin: '#e8b88a', skinShade: '#cf9a6b',
      hair: '#241612', hairLight: '#3a221c',
      // Short crop
      hairBack: 'M58 90 Q 58 50 100 46 Q 142 50 142 90 L 142 96 Q 130 86 100 86 Q 70 86 58 96 Z',
      hairFront: 'M64 82 Q 78 60 100 60 Q 124 60 136 82 Q 122 72 100 76 Q 80 72 64 82 Z',
      cheek: '#dfa282',
      lip: '#a64a3b',
      accessory: 'glasses',
    },
    sofia: {
      skin: '#f0c39a', skinShade: '#d6a275',
      hair: '#1a0f0a', hairLight: '#2e1c14',
      // Hair pulled back with bun
      hairBack: 'M58 105 Q 58 55 100 48 Q 142 55 142 105 L 142 150 Q 138 162 124 166 L 76 166 Q 62 162 58 150 Z',
      hairFront: 'M68 74 Q 84 66 100 66 Q 116 66 132 74 Q 120 70 100 72 Q 80 70 68 74 Z',
      hairBun: { cx: 100, cy: 32, rx: 22, ry: 18 },
      cheek: '#e8a98a',
      lip: '#a13a44',
      accessory: 'glasses-oval',
    },
    theo: {
      skin: '#f2c89c', skinShade: '#d8a878',
      hair: '#4a2a14', hairLight: '#6b3e1f',
      // Messy/wavy
      hairBack: 'M55 102 Q 50 48 100 42 Q 152 48 148 102 L 148 130 Q 142 142 128 144 L 72 144 Q 58 142 55 130 Z',
      hairFront: 'M58 84 Q 64 56 88 58 Q 96 70 104 60 Q 116 56 130 68 Q 142 76 142 90 Q 130 78 116 82 Q 106 74 96 80 Q 86 72 72 80 Q 62 80 58 84 Z',
      cheek: '#eaad88',
      lip: '#9c3e2f',
      accessory: null,
    },
  };
  const L = looks[persona] || looks.maya;

  // Animation classes via inline keyframes (scoped names)
  return (
    <div style={{ width: size, height: size, position: 'relative', flexShrink: 0 }}>
      {/* Background glow */}
      <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: p.avatarBg, opacity: .14 }} />
      {(speaking || listening) && (
        <>
          <div style={{ position: 'absolute', inset: -6, borderRadius: '50%', border: `2px solid ${p.accent}`, opacity: .35, animation: `ft-pulse ${speaking ? '1.6s' : '1.2s'} ease-out infinite` }} />
          <div style={{ position: 'absolute', inset: -6, borderRadius: '50%', border: `2px solid ${p.accent}`, opacity: .35, animation: `ft-pulse ${speaking ? '1.6s' : '1.2s'} ease-out infinite .55s` }} />
        </>
      )}

      <svg viewBox="0 0 200 200" width={size} height={size} style={{ position: 'relative', display: 'block', overflow: 'visible' }}>
        <defs>
          <radialGradient id={`fa-bg-${persona}`} cx="50%" cy="35%" r="65%">
            <stop offset="0%" stopColor={p.accent} stopOpacity=".25" />
            <stop offset="70%" stopColor={p.accent} stopOpacity="0" />
          </radialGradient>
          <clipPath id={`fa-clip-${persona}`}><circle cx="100" cy="100" r="98" /></clipPath>
          <radialGradient id={`fa-skin-${persona}`} cx="45%" cy="40%" r="65%">
            <stop offset="0%" stopColor={L.skin} />
            <stop offset="100%" stopColor={L.skinShade} />
          </radialGradient>
        </defs>

        <circle cx="100" cy="100" r="98" fill={`url(#fa-bg-${persona})`} />

        {/* Head group — gentle bob/tilt by mode */}
        <g clipPath={`url(#fa-clip-${persona})`}>
          <g style={{
            transformOrigin: '100px 130px',
            animation: speaking
              ? 'ft-head-bob 1.1s ease-in-out infinite'
              : listening
              ? 'ft-head-tilt 3s ease-in-out infinite'
              : 'ft-head-idle 6s ease-in-out infinite',
          }}>
            {/* Neck */}
            <rect x="85" y="155" width="30" height="35" rx="10" fill={`url(#fa-skin-${persona})`} />
            <path d="M82 175 Q 100 188 118 175 L 118 200 L 82 200 Z" fill={p.accent} opacity=".85" />
            {/* Shirt collar accent */}
            <path d="M82 175 Q 100 195 118 175" stroke={L.hair} strokeWidth="1.5" fill="none" opacity=".4" />

            {/* Hair back */}
            <path d={L.hairBack} fill={L.hair} />

            {/* Face */}
            <ellipse cx="100" cy="115" rx="42" ry="50" fill={`url(#fa-skin-${persona})`} />
            {/* Ear hints */}
            <ellipse cx="58" cy="120" rx="6" ry="9" fill={L.skinShade} />
            <ellipse cx="142" cy="120" rx="6" ry="9" fill={L.skinShade} />

            {/* Cheek blush */}
            <ellipse cx="74" cy="128" rx="9" ry="5" fill={L.cheek} opacity=".55" />
            <ellipse cx="126" cy="128" rx="9" ry="5" fill={L.cheek} opacity=".55" />

            {/* Eyebrows — lift when listening */}
            <g style={{ transformOrigin: '100px 100px', animation: listening ? 'ft-brow-lift 2.4s ease-in-out infinite' : 'none' }}>
              <path d="M76 96 Q 84 90 92 96" stroke={L.hair} strokeWidth="3.2" strokeLinecap="round" fill="none" />
              <path d="M108 96 Q 116 90 124 96" stroke={L.hair} strokeWidth="3.2" strokeLinecap="round" fill="none" />
            </g>

            {/* Eyes — blink keyframe scales eyelid */}
            <g>
              <g style={{ transformOrigin: '84px 108px', animation: 'ft-blink 5.2s ease-in-out infinite' }}>
                <ellipse cx="84" cy="108" rx="5" ry="6.5" fill="#fff" />
                <circle cx="85" cy="109" r="3.4" fill={L.hair} />
                <circle cx="86.2" cy="107.2" r="1" fill="#fff" />
              </g>
              <g style={{ transformOrigin: '116px 108px', animation: 'ft-blink 5.2s ease-in-out infinite' }}>
                <ellipse cx="116" cy="108" rx="5" ry="6.5" fill="#fff" />
                <circle cx="117" cy="109" r="3.4" fill={L.hair} />
                <circle cx="118.2" cy="107.2" r="1" fill="#fff" />
              </g>
            </g>

            {/* Glasses */}
            {L.accessory === 'glasses' && (
              <g stroke={L.hair} strokeWidth="2.4" fill="none">
                <rect x="72" y="100" width="22" height="16" rx="3" />
                <rect x="106" y="100" width="22" height="16" rx="3" />
                <path d="M94 108 L 106 108" />
              </g>
            )}
            {L.accessory === 'glasses-oval' && (
              <g stroke={L.hair} strokeWidth="2.2" fill="none">
                <ellipse cx="84" cy="108" rx="11" ry="9" />
                <ellipse cx="116" cy="108" rx="11" ry="9" />
                <path d="M95 108 L 105 108" />
              </g>
            )}

            {/* Nose */}
            <path d="M100 116 Q 96 126 100 132 Q 104 130 104 128" stroke={L.skinShade} strokeWidth="1.6" fill="none" strokeLinecap="round" opacity=".7" />

            {/* Mouth group — animates while speaking */}
            <g style={{
              transformOrigin: '100px 145px',
              animation: speaking
                ? 'ft-mouth-talk .42s ease-in-out infinite'
                : thinking
                ? 'ft-mouth-hm 1.8s ease-in-out infinite'
                : 'none',
            }}>
              {/* Lip outline */}
              <path d="M84 144 Q 100 154 116 144" stroke={L.lip} strokeWidth="2.2" fill="none" strokeLinecap="round" opacity={speaking ? 0 : .9} />
              {/* Inner mouth visible when speaking */}
              <ellipse cx="100" cy="146" rx="11" ry="3" fill="#3a1212" opacity={speaking ? 1 : 0} />
              <ellipse cx="100" cy="146" rx="11" ry="3" fill={L.lip} stroke={L.lip} strokeWidth="2" opacity={speaking ? 1 : 0} style={{
                animation: speaking ? 'ft-mouth-open .42s ease-in-out infinite' : 'none',
                transformOrigin: '100px 146px',
              }} />
            </g>

            {/* Hair front (over forehead) */}
            <path d={L.hairFront} fill={L.hair} />
            {L.hairBun && (
              <ellipse cx={L.hairBun.cx} cy={L.hairBun.cy} rx={L.hairBun.rx} ry={L.hairBun.ry} fill={L.hair} />
            )}
            {/* Highlight on hair */}
            <path d={L.hairFront} fill={L.hairLight} opacity=".35" transform="translate(0 -2)" style={{ filter: 'blur(2px)' }} />
          </g>
        </g>

        {/* Outer ring */}
        <circle cx="100" cy="100" r="98" fill="none" stroke={p.accent} strokeOpacity=".18" strokeWidth="2" />
      </svg>

      {/* Status caption inside the badge — appears under chin */}
      {(speaking || listening || thinking) && (
        <div style={{
          position: 'absolute', left: '50%', bottom: -8, transform: 'translateX(-50%)',
          fontSize: 11, fontFamily: 'JetBrains Mono, monospace', letterSpacing: '.08em',
          color: theme ? theme.inkSoft : '#666', textTransform: 'uppercase',
          display: 'flex', alignItems: 'center', gap: 6, whiteSpace: 'nowrap',
        }}>
          {speaking && <><span style={{ width: 6, height: 6, borderRadius: 3, background: p.accent, animation: 'ft-blink 1s ease-in-out infinite' }} />speaking</>}
          {listening && <><span style={{ width: 6, height: 6, borderRadius: 3, background: theme?.bad || '#c0392b', animation: 'ft-blink .6s ease-in-out infinite' }} />listening</>}
          {thinking && <>thinking…</>}
        </div>
      )}
    </div>
  );
};

// ── Live waveform (animated bars) ───────────────────────────────────────
const Waveform = ({ active = true, color = '#fff', bars = 28, height = 32, gap = 3, barWidth = 3 }) => {
  // Stable deterministic heights/delays per bar
  const items = useMemo(() => Array.from({ length: bars }, (_, i) => {
    const seed = Math.sin(i * 1.7) * 1000;
    const r = seed - Math.floor(seed);
    return { delay: r * 1.1, dur: 0.6 + r * 0.8, scale: 0.35 + r * 0.65 };
  }), [bars]);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap, height, justifyContent: 'center' }}>
      {items.map((b, i) => (
        <div key={i} style={{
          width: barWidth, height: '100%', borderRadius: barWidth,
          background: color, transformOrigin: 'center',
          transform: active ? undefined : `scaleY(${b.scale})`,
          animation: active ? `ft-wave ${b.dur}s ease-in-out ${b.delay}s infinite` : 'none',
        }} />
      ))}
    </div>
  );
};

// ── Score ring (svg circular progress) ──────────────────────────────────
const ScoreRing = ({ value = 0, size = 96, stroke = 8, label, color = '#e26a3a', track = 'rgba(0,0,0,.06)', ink = '#2a1f17', sub }) => {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const dash = (value / 100) * c;
  return (
    <div style={{ position: 'relative', width: size, height: size, display: 'inline-block' }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={track} strokeWidth={stroke} fill="none" />
        <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke} fill="none"
          strokeLinecap="round" strokeDasharray={`${dash} ${c}`} style={{ transition: 'stroke-dasharray 1.2s cubic-bezier(.22,.61,.36,1)' }} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: ink }}>
        <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: size * 0.36, lineHeight: 1, fontWeight: 400 }}>{value}</div>
        {sub && <div style={{ fontSize: 10, opacity: .55, marginTop: 2, letterSpacing: '.04em', textTransform: 'uppercase' }}>{(window.t && window.t(sub)) || sub}</div>}
      </div>
    </div>
  );
};

// ── Pill / Chip ─────────────────────────────────────────────────────────
const Chip = ({ children, active, onClick, theme, icon }) => (
  <button onClick={onClick} style={{
    border: `1px solid ${active ? theme.accent : theme.border}`,
    background: active ? theme.accent : theme.surface,
    color: active ? '#fff' : theme.ink,
    padding: '6px 12px', borderRadius: 999, fontSize: 12.5, fontWeight: 500,
    cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 6,
    transition: 'all .18s ease', letterSpacing: '.01em',
  }}>
    {icon}{children}
  </button>
);

// ── Primary button ──────────────────────────────────────────────────────
const Button = ({ children, onClick, theme, variant = 'primary', size = 'md', icon, iconRight, full, style: extraStyle = {} }) => {
  const sizes = {
    sm: { padX: 12, padY: 7, font: 12.5, radius: 10 },
    md: { padX: 18, padY: 11, font: 14, radius: 12 },
    lg: { padX: 22, padY: 15, font: 16, radius: 14 },
  }[size];
  const variants = {
    primary: { bg: theme.accent, color: '#fff', border: theme.accent, shadow: `0 6px 16px ${theme.accent}55` },
    ghost:   { bg: 'transparent', color: theme.ink, border: 'transparent' },
    soft:    { bg: theme.accentSoft, color: theme.accentInk, border: 'transparent' },
    outline: { bg: theme.surface, color: theme.ink, border: theme.border },
  }[variant];
  return (
    <button onClick={onClick} style={{
      padding: `${sizes.padY}px ${sizes.padX}px`, fontSize: sizes.font, fontWeight: 600,
      background: variants.bg, color: variants.color,
      border: `1px solid ${variants.border}`, borderRadius: sizes.radius,
      cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      transition: 'transform .14s ease, box-shadow .18s ease, background .18s',
      boxShadow: variants.shadow || 'none', letterSpacing: '.005em',
      width: full ? '100%' : undefined, ...extraStyle,
    }}
    onMouseDown={(e) => e.currentTarget.style.transform = 'scale(.97)'}
    onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
    onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}>
      {icon}<span>{children}</span>{iconRight}
    </button>
  );
};

// ── Card ─────────────────────────────────────────────────────────────────
const Card = ({ children, theme, padding = 16, style: extra = {}, onClick, hoverable }) => (
  <div onClick={onClick} style={{
    background: theme.surface, border: `1px solid ${theme.border}`, borderRadius: 18, padding,
    transition: 'transform .2s ease, box-shadow .2s ease',
    cursor: onClick ? 'pointer' : 'default',
    boxShadow: '0 1px 0 rgba(255,255,255,.6) inset, 0 4px 14px rgba(20,15,10,.04)',
    ...extra,
  }}
  onMouseEnter={(e) => hoverable && (e.currentTarget.style.transform = 'translateY(-2px)', e.currentTarget.style.boxShadow = '0 1px 0 rgba(255,255,255,.6) inset, 0 12px 28px rgba(20,15,10,.08)')}
  onMouseLeave={(e) => hoverable && (e.currentTarget.style.transform = '', e.currentTarget.style.boxShadow = '0 1px 0 rgba(255,255,255,.6) inset, 0 4px 14px rgba(20,15,10,.04)')}>
    {children}
  </div>
);

// ── Linear progress bar ──────────────────────────────────────────────────
// Count-up: animates a number 0 → target with ease-out cubic via rAF.
function useCountUp(target, opts) {
  const o = opts || {};
  const duration = typeof o.duration === 'number' ? o.duration : 1200;
  const decimals = typeof o.decimals === 'number' ? o.decimals : 0;
  const delay = typeof o.delay === 'number' ? o.delay : 0;
  const safeTarget = (typeof target === 'number' && isFinite(target)) ? target : 0;
  const [val, setVal] = useState(safeTarget === 0 ? 0 : 0);
  useEffect(() => {
    let raf, t0;
    setVal(0);
    const ease = (x) => 1 - Math.pow(1 - x, 3);
    const factor = Math.pow(10, decimals);
    const tick = (now) => {
      if (!t0) t0 = now;
      const e = now - t0 - delay;
      if (e < 0) { raf = requestAnimationFrame(tick); return; }
      const p = Math.min(1, e / duration);
      const v = safeTarget * ease(p);
      const rounded = Math.round(v * factor) / factor;
      setVal(isFinite(rounded) ? rounded : safeTarget);
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [safeTarget, duration, decimals, delay]);
  return val;
}

const Bar = ({ value, color, track, height = 6, label, delay = 0, duration = 900 }) => {
  const [w, setW] = useState(0);
  useEffect(() => {
    setW(0);
    const id = setTimeout(() => setW(value), 40 + delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return (
    <div>
      {label && <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, marginBottom: 4, opacity: .7 }}>{label}</div>}
      <div style={{ background: track, height, borderRadius: height, overflow: 'hidden' }}>
        <div style={{ width: `${w}%`, height: '100%', background: color, borderRadius: height, transition: `width ${duration}ms cubic-bezier(.22,.61,.36,1)` }} />
      </div>
    </div>
  );
};

// ── Section header ───────────────────────────────────────────────────────
const SectionHead = ({ kicker, title, action, theme, size = 'md' }) => (
  <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', marginBottom: 12 }}>
    <div>
      {kicker && <div style={{ fontSize: 10, letterSpacing: '.16em', textTransform: 'uppercase', color: theme.inkFaint, marginBottom: 6 }}>{kicker}</div>}
      <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: size === 'lg' ? 32 : 22, lineHeight: 1.2, color: theme.ink, letterSpacing: '-0.01em' }}>{title}</div>
    </div>
    {action}
  </div>
);

// AnimatedNumber: simple inline count-up display.
const AnimatedNumber = ({ value, duration = 1200, decimals = 0, delay = 0, suffix = '' }) => {
  const v = useCountUp(value, { duration, decimals, delay });
  return <span>{v}{suffix}</span>;
};

Object.assign(window, { Icon, Avatar, TalkingAvatar, Waveform, ScoreRing, Chip, Button, Card, Bar, SectionHead, useCountUp, AnimatedNumber });

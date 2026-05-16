// More screens for FreeTalk: Report, Progress, Course, Settings.

const { useState: uSx, useEffect: uEx, useRef: uRx, useMemo: uMx } = React;

// ═════════════════════════════════════════════════════════════════════════
// REPORT — post-conversation evaluation (richly animated)
// ═════════════════════════════════════════════════════════════════════════

// Tick a number from 0 → target over `dur` ms, easing out. (Local to screens2.)
function useReportCountUp(target, dur = 1400, startDelay = 0) {
  const [n, setN] = uSx(0);
  uEx(() => {
    let raf, t0;
    const start = performance.now() + startDelay;
    const tick = (now) => {
      if (now < start) { raf = requestAnimationFrame(tick); return; }
      if (t0 == null) t0 = now;
      const p = Math.min(1, (now - t0) / dur);
      const eased = 1 - Math.pow(1 - p, 3);
      setN(Math.round(target * eased));
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [target]);
  return n;
}

// Animated ring that fills 0 → value with sparkles + glow.
function AnimatedScoreRing({ value, size, stroke, color, track, ink, sub, theme }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const [progress, setProgress] = uSx(0);
  uEx(() => {
    const t = setTimeout(() => setProgress(value), 200);
    return () => clearTimeout(t);
  }, [value]);
  const dash = (progress / 100) * c;
  const n = useReportCountUp(value, 1500, 200);

  // Sparkle positions around the ring
  const sparkles = uMx(() => Array.from({ length: 8 }, (_, i) => {
    const a = (i / 8) * Math.PI * 2;
    return { x: Math.cos(a) * (r + 6), y: Math.sin(a) * (r + 6), delay: i * 0.15 };
  }), [r]);

  return (
    <div style={{ position: 'relative', width: size, height: size, display: 'inline-block' }}>
      {/* Burst behind ring (mounted-once radial) */}
      <div style={{
        position: 'absolute', inset: 0, borderRadius: '50%',
        background: `radial-gradient(circle, ${color}33 0%, transparent 70%)`,
        animation: 'ft-burst 1.2s ease-out both',
      }} />
      {/* Sparkles around ring */}
      {sparkles.map((s, i) => (
        <div key={i} style={{
          position: 'absolute', left: '50%', top: '50%',
          width: 8, height: 8, marginLeft: -4, marginTop: -4,
          transform: `translate(${s.x}px, ${s.y}px)`,
          animation: `ft-sparkle 2.4s ease-in-out ${s.delay}s infinite`,
        }}>
          <svg viewBox="0 0 24 24" width="8" height="8">
            <path d="M12 2 L13.5 10.5 L22 12 L13.5 13.5 L12 22 L10.5 13.5 L2 12 L10.5 10.5 Z" fill={color} />
          </svg>
        </div>
      ))}
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)', position: 'relative', zIndex: 1 }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={track} strokeWidth={stroke} fill="none" />
        <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke} fill="none"
          strokeLinecap="round" strokeDasharray={`${dash} ${c}`}
          style={{ transition: 'stroke-dasharray 1.5s cubic-bezier(.22,.61,.36,1)', filter: `drop-shadow(0 0 6px ${color}66)` }} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: ink, zIndex: 2 }}>
        <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: size * 0.36, lineHeight: 1, fontWeight: 400 }}>{n}</div>
        {sub && <div style={{ fontSize: 10, opacity: .55, marginTop: 2, letterSpacing: '.08em', textTransform: 'uppercase' }}>{(window.t && window.t(sub)) || sub}</div>}
      </div>
    </div>
  );
}

// Animated bar that grows + animated count on the right.
function AnimatedScoreBar({ label, value, color, track, delay = 0, theme }) {
  const n = useReportCountUp(value, 1100, delay);
  return (
    <div style={{ animation: `ft-slide-up .5s both ${delay/1000}s` }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 4 }}>
        <div style={{ fontSize: 12, color: theme.inkSoft, textTransform: 'capitalize' }}>{t(label)}</div>
        <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 14, color: theme.ink }}>{n}</div>
      </div>
      <div style={{ height: 5, background: track, borderRadius: 999, overflow: 'hidden', position: 'relative' }}>
        <div style={{
          position: 'absolute', inset: 0, transformOrigin: 'left center',
          background: `linear-gradient(90deg, ${color}, ${color}cc)`,
          width: `${value}%`, borderRadius: 999,
          animation: `ft-bar-grow 1.2s cubic-bezier(.22,.61,.36,1) both ${delay/1000 + 0.1}s`,
        }} />
        {/* shimmer sweep on top */}
        <div style={{
          position: 'absolute', top: 0, bottom: 0, width: '40%',
          background: 'linear-gradient(90deg, transparent, rgba(255,255,255,.6), transparent)',
          animation: `ft-shimmer 2.4s ease-in-out ${delay/1000 + 0.6}s infinite`,
          backgroundSize: '200% 100%',
        }} />
      </div>
    </div>
  );
}

// Confetti burst — emits N pieces falling from top with varied colors/dx.
function ConfettiBurst({ palette, count = 28 }) {
  const pieces = uMx(() => Array.from({ length: count }, (_, i) => ({
    left: Math.random() * 100,
    dx:   (Math.random() - 0.5) * 220,
    rz:   (Math.random() * 720 - 360),
    dur:  2400 + Math.random() * 1600,
    delay: Math.random() * 600,
    color: palette[i % palette.length],
    size: 6 + Math.random() * 8,
    shape: i % 3, // 0 rect, 1 circle, 2 diamond
  })), [count]);
  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none', zIndex: 3 }}>
      {pieces.map((p, i) => (
        <div key={i} style={{
          position: 'absolute', left: `${p.left}%`, top: 0,
          width: p.size, height: p.shape === 0 ? p.size * 0.5 : p.size,
          background: p.color,
          borderRadius: p.shape === 1 ? '50%' : p.shape === 2 ? 0 : 2,
          transform: p.shape === 2 ? 'rotate(45deg)' : 'none',
          ['--dx']: `${p.dx}px`,
          ['--rz']: `${p.rz}deg`,
          animation: `ft-confetti-fall ${p.dur}ms cubic-bezier(.2,.4,.6,1) ${p.delay}ms both`,
        }} />
      ))}
    </div>
  );
}

function ReportScreen({ theme, persona, feedback, nav, layout }) {
  const p = PERSONAS[persona];
  const isDesktop = layout === 'desktop';

  const scores = {
    pronunciation: 78,
    grammar: 71,
    fluency: 84,
    vocabulary: 69,
  };
  const overall = Math.round((scores.pronunciation + scores.grammar + scores.fluency + scores.vocabulary) / 4);
  const cefr = overall >= 80 ? 'B2' : overall >= 70 ? 'B1+' : overall >= 60 ? 'B1' : 'A2';

  const corrections = [
    { you: 'I go to hiking on weekends.',     fix: 'I go hiking on weekends.',          kind: 'grammar', note: 'No “to” after “go” + activity-ing.' },
    { you: 'Sometime we cook together.',      fix: 'Sometimes we cook together.',       kind: 'grammar', note: '“Sometimes” = on some occasions.' },
    { you: 'The view was inkredibel.',        fix: 'The view was incredible.',          kind: 'pron',    note: 'Stress: in-CRE-di-ble. /ɪnˈkrɛd.ə.bəl/' },
    { you: 'I have went there last weekend.', fix: 'I went there last weekend.',        kind: 'grammar', note: 'Simple past — no auxiliary.' },
  ];

  const phrases = [
    { phrase: 'gorgeous view',     ex: 'The bay had a gorgeous view at sunset.' },
    { phrase: 'wind down',         ex: 'I cook to wind down after work.' },
    { phrase: 'pop over',          ex: 'My friends pop over on Sundays.' },
  ];

  const confettiPalette = [theme.accent, theme.good, theme.warn, theme.accentInk, '#ffffff'];
  const sessionStats = useReportCountUp(142, 1200, 400);
  const wordsPerMin = useReportCountUp(20, 1200, 600);

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, overflow: 'auto', position: 'relative' }}>
      {/* Background glow */}
      <div style={{ position: 'absolute', inset: 0, background: theme.glow, pointerEvents: 'none' }} />

      {/* Floating decorative shapes in background */}
      <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', top: '12%', left: '6%', width: 80, height: 80, borderRadius: '50%', background: theme.accentSoft, opacity: .5, animation: 'ft-float-slow 7s ease-in-out infinite' }} />
        <div style={{ position: 'absolute', top: '34%', right: '4%', width: 56, height: 56, borderRadius: 16, background: theme.accent + '22', animation: 'ft-float-slow 9s ease-in-out infinite', animationDelay: '-3s', transform: 'rotate(20deg)' }} />
        <div style={{ position: 'absolute', bottom: '18%', left: '10%', width: 40, height: 40, background: theme.good + '33', transform: 'rotate(45deg)', animation: 'ft-float-slow 11s ease-in-out infinite', animationDelay: '-5s' }} />
        <div style={{ position: 'absolute', top: '55%', right: '12%', width: 22, height: 22, borderRadius: '50%', background: theme.warn + '55', animation: 'ft-float-slow 6s ease-in-out infinite', animationDelay: '-2s' }} />
      </div>

      {/* Confetti — only at top, only on mount */}
      <ConfettiBurst palette={confettiPalette} count={isDesktop ? 36 : 24} />

      <div style={{ position: 'relative', padding: isDesktop ? '32px 48px 64px' : '20px 18px 40px', maxWidth: isDesktop ? 940 : '100%', margin: '0 auto', zIndex: 2 }}>

        {/* Header */}
        <div className="ft-fade-in" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 22 }}>
          <button onClick={() => nav('home')} style={{ width: 34, height: 34, borderRadius: 999, border: 'none', background: theme.surface, color: theme.ink, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="back" size={16} />
          </button>
          <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.16em', textTransform: 'uppercase' }}>{t('Session report')}</div>
          <button style={{ padding: '6px 12px', fontSize: 12, fontWeight: 500, border: `1px solid ${theme.border}`, background: theme.surface, color: theme.ink, borderRadius: 999, cursor: 'pointer' }}>{t('Share')}</button>
        </div>

        {/* Headline with shimmer on italic phrase */}
        <div className="ft-fade-in" style={{ textAlign: 'center', marginBottom: 24, position: 'relative' }}>
          <h1 className="ft-serif" style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 48 : 32, fontWeight: 400, margin: 0, letterSpacing: '-0.02em', lineHeight: 1.18 }}>
            {t('Nice talk.')}{' '}
            <span style={{
              fontStyle: 'italic',
              backgroundImage: `linear-gradient(90deg, ${theme.accent} 0%, ${theme.accent} 30%, #ffffff 50%, ${theme.accent} 70%, ${theme.accent} 100%)`,
              backgroundSize: '200% 100%',
              WebkitBackgroundClip: 'text',
              backgroundClip: 'text',
              color: 'transparent',
              animation: 'ft-text-shimmer 3s ease-in-out 0.6s infinite',
            }}>{t('You’re getting there.')}</span>
          </h1>
          <p className="ft-fade-in" style={{ color: theme.inkSoft, fontSize: 13, marginTop: 8, animationDelay: '.2s' }}>
            7 {t('min')} · <span style={{ fontFamily: 'JetBrains Mono, monospace' }}>{sessionStats}</span> {t('words')} · <span style={{ fontFamily: 'JetBrains Mono, monospace' }}>{wordsPerMin}</span> {t('wpm')} · {t('with')} {p.name}
          </p>
        </div>

        {/* Score hero */}
        <Card theme={theme} padding={isDesktop ? 28 : 22} style={{ marginBottom: 22, position: 'relative', overflow: 'visible' }}>
          {/* CEFR stamp */}
          <div style={{
            position: 'absolute', top: -14, right: isDesktop ? 24 : 14,
            background: theme.accent, color: '#fff',
            fontFamily: 'Instrument Serif, serif', fontSize: 22,
            padding: '8px 18px', borderRadius: 12,
            boxShadow: `0 8px 20px ${theme.accent}66`,
            animation: 'ft-stamp-in .9s cubic-bezier(.34,1.56,.64,1) both .9s, ft-wiggle 4s ease-in-out 2s infinite',
            transformOrigin: 'center',
            border: '2px solid rgba(255,255,255,.4)',
          }}>
            <div style={{ fontSize: 9, letterSpacing: '.18em', opacity: .8, marginBottom: 2 }}>CEFR</div>
            <div style={{ lineHeight: .9, fontSize: 26 }}>{cefr}</div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: isDesktop ? 32 : 20, flexWrap: isDesktop ? 'nowrap' : 'wrap' }}>
            <div className="ft-pop-in" style={{ position: 'relative' }}>
              <AnimatedScoreRing value={overall} size={isDesktop ? 160 : 130} stroke={12} color={theme.accent} track={theme.accentSoft} ink={theme.ink} sub="Overall" theme={theme} />
              <div style={{
                position: 'absolute', bottom: -6, left: '50%', transform: 'translateX(-50%)',
                background: theme.good, color: '#fff', fontSize: 10, fontWeight: 700,
                padding: '4px 10px', borderRadius: 999,
                display: 'flex', alignItems: 'center', gap: 4, whiteSpace: 'nowrap',
                animation: 'ft-stamp-in .8s cubic-bezier(.34,1.56,.64,1) both 1.6s',
                boxShadow: `0 4px 12px ${theme.good}66`,
                zIndex: 3,
              }}>
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
                  <path d="M5 12 L10 17 L19 7" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"
                    strokeDasharray="24" style={{ animation: 'ft-tick-draw .5s ease-out forwards 2.1s', strokeDashoffset: 24 }} />
                </svg>
                +6 {t('this week')}
              </div>
            </div>
            <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, minWidth: 200 }}>
              {Object.entries(scores).map(([k, v], i) => (
                <AnimatedScoreBar key={k} label={k} value={v} color={theme.accent} track={theme.accentSoft} delay={400 + i * 180} theme={theme} />
              ))}
            </div>
          </div>
        </Card>

        {/* Coach note */}
        <Card theme={theme} padding={16} style={{
          marginBottom: 22, background: theme.surfaceAlt, border: 'none',
          display: 'flex', gap: 14, alignItems: 'flex-start',
          animation: 'ft-slide-up .6s cubic-bezier(.22,.61,.36,1) both 2.4s',
          position: 'relative', overflow: 'hidden',
        }}>
          {/* subtle moving sheen */}
          <div style={{
            position: 'absolute', inset: 0, pointerEvents: 'none',
            background: `linear-gradient(115deg, transparent 30%, ${theme.accent}11 50%, transparent 70%)`,
            backgroundSize: '200% 100%',
            animation: 'ft-shimmer 6s ease-in-out 3s infinite',
          }} />
          <div style={{ position: 'relative', animation: 'ft-float-slow 6s ease-in-out infinite' }}>
            <Avatar persona={persona} size={42} />
            {/* speech bubble tail */}
            <svg width="14" height="10" style={{ position: 'absolute', right: -7, top: 14 }} viewBox="0 0 14 10">
              <path d="M0 4 L10 0 L8 10 Z" fill={theme.surfaceAlt} />
            </svg>
          </div>
          <div style={{ flex: 1, position: 'relative' }}>
            <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.08em', textTransform: 'uppercase', marginBottom: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
              {t('From')} {p.name}
              <span style={{
                display: 'inline-block', width: 6, height: 6, borderRadius: '50%',
                background: theme.good,
                animation: 'ft-pulse 2s ease-out infinite',
                transformOrigin: 'center',
              }} />
            </div>
            <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 18, lineHeight: 1.35, color: theme.ink }}>
              “Your storytelling is really opening up — you used <em>incredible</em>, <em>finally</em>, and <em>maple</em> beautifully. Watch the past-tense slip with <em>have went</em> and you’ll sound much more natural.”
            </div>
          </div>
        </Card>

        {/* Corrections */}
        <SectionHead theme={theme} kicker={t('Correct these')} title={t('Mistakes worth fixing')}
          action={<div style={{ fontSize: 11, color: theme.inkFaint, fontFamily: 'JetBrains Mono, monospace' }}>{corrections.length} {t('items')}</div>} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 22 }}>
          {corrections.map((c, i) => (
            <Card key={i} theme={theme} padding={14} style={{
              animation: `ft-slide-up .5s both ${2.6 + i*.12}s`,
              position: 'relative', overflow: 'hidden',
              transition: 'transform .25s ease, box-shadow .25s ease',
            }}
            onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = `0 8px 20px ${theme.accent}22`; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = ''; }}>
              {/* left accent bar */}
              <div style={{
                position: 'absolute', left: 0, top: 0, bottom: 0, width: 3,
                background: c.kind === 'pron' ? theme.bad : theme.warn,
                transformOrigin: 'top',
                animation: `ft-bar-grow .5s ease-out both ${2.7 + i*.12}s`,
              }} />
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                <div style={{
                  width: 30, height: 30, borderRadius: 8,
                  background: c.kind === 'pron' ? theme.bad + '22' : theme.warn + '22',
                  color: c.kind === 'pron' ? theme.bad : theme.warn,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                  animation: `ft-pop-in .5s cubic-bezier(.34,1.56,.64,1) both ${2.75 + i*.12}s`,
                }}>
                  <Icon name={c.kind === 'pron' ? 'mic' : 'sparkle'} size={14} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, alignItems: 'center', fontSize: 13.5 }}>
                    <span style={{ textDecoration: 'line-through', color: theme.inkSoft }}>{c.you}</span>
                    <span style={{ display: 'inline-flex', animation: `ft-wiggle 2s ease-in-out ${3 + i*.12}s infinite` }}>
                      <Icon name="arrow" size={12} stroke={theme.accent} />
                    </span>
                    <span style={{
                      color: theme.accent, fontWeight: 600,
                      animation: `ft-fade-in .5s ease both ${3 + i*.12}s`,
                    }}>{c.fix}</span>
                  </div>
                  <div style={{ fontSize: 11.5, color: theme.inkSoft, marginTop: 6, lineHeight: 1.5 }}>{c.note}</div>
                </div>
                <button style={{
                  width: 28, height: 28, borderRadius: 8,
                  border: `1px solid ${theme.border}`, background: theme.surface,
                  color: theme.ink, cursor: 'pointer',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                  transition: 'transform .15s ease, background .15s ease',
                }} title="Hear it"
                onMouseEnter={(e) => { e.currentTarget.style.transform = 'scale(1.12)'; e.currentTarget.style.background = theme.accentSoft; }}
                onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.background = theme.surface; }}>
                  <Icon name="play" size={12} fill={theme.ink} stroke={theme.ink} />
                </button>
              </div>
            </Card>
          ))}
        </div>

        {/* New phrases */}
        <SectionHead theme={theme} kicker={t('Pocket these')} title={t('New phrases you used')} />
        <div style={{ display: 'grid', gridTemplateColumns: isDesktop ? 'repeat(3, 1fr)' : '1fr', gap: 10, marginBottom: 22 }}>
          {phrases.map((ph, i) => (
            <Card key={i} theme={theme} padding={14} style={{
              animation: `ft-slide-up .5s both ${3.2 + i*.12}s`,
              transition: 'transform .25s ease, box-shadow .25s ease',
              cursor: 'pointer',
            }}
            onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-3px) rotate(-.5deg)'; e.currentTarget.style.boxShadow = `0 10px 24px ${theme.accent}33`; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = ''; }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 18, color: theme.ink }}>{ph.phrase}</div>
                <button style={{
                  width: 26, height: 26, borderRadius: 8, border: 'none',
                  background: theme.accentSoft, color: theme.accent, cursor: 'pointer',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  transition: 'transform .2s cubic-bezier(.34,1.56,.64,1)',
                }}
                onMouseEnter={(e) => { e.currentTarget.style.transform = 'scale(1.18) rotate(90deg)'; }}
                onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; }}>
                  <Icon name="plus" size={14} />
                </button>
              </div>
              <div style={{ fontSize: 11.5, color: theme.inkSoft, marginTop: 4, fontStyle: 'italic' }}>“{ph.ex}”</div>
            </Card>
          ))}
        </div>

        {/* CTAs */}
        <div style={{ display: 'flex', gap: 10, justifyContent: 'center', animation: 'ft-slide-up .6s both 3.8s' }}>
          <Button theme={theme} variant="outline" size="md" onClick={() => nav('home')}>{t('Done')}</Button>
          <span style={{ display: 'inline-block', animation: 'ft-float-slow 3s ease-in-out infinite' }}>
            <Button theme={theme} size="md" icon={<Icon name="mic" size={16} stroke="#fff" />} onClick={() => nav('convo')}>{t('Practice again')}</Button>
          </span>
        </div>
      </div>
    </div>
  );
}

// Animated chart bar — grows from 0 to target height, with count-up label.
function ChartBar({ week, idx, total, max, theme }) {
  const isLast = idx === total - 1;
  const targetPct = (week.val / max) * 100;
  const [h, setH] = uSx(0);
  uEx(() => {
    setH(0);
    const id = setTimeout(() => setH(targetPct), 60 + idx * 80);
    return () => clearTimeout(id);
  }, [targetPct, idx]);
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
      <div style={{ flex: 1, width: '100%', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', position: 'relative' }}>
        <div style={{
          width: 10, height: `${h}%`, borderRadius: 999,
          background: isLast ? theme.bad : `${theme.bad}d9`,
          transition: 'height .9s cubic-bezier(.22,.61,.36,1)',
          position: 'relative',
          boxShadow: isLast ? `0 0 14px ${theme.bad}66` : `0 0 8px ${theme.bad}33`,
        }}>
          {/* Top value label — always shown above each bar */}
          {h > 0 && (
            <div style={{
              position: 'absolute', top: -20, left: '50%', transform: 'translateX(-50%)',
              fontSize: 11, fontFamily: 'JetBrains Mono, monospace',
              color: isLast ? theme.bad : theme.inkSoft,
              fontWeight: isLast ? 700 : 500,
              animation: `ft-fade-in .4s ease both ${.1 + idx * 0.08}s`,
              whiteSpace: 'nowrap',
            }}>
              <AnimatedNumber value={week.val} duration={900} delay={60 + idx * 80} />
            </div>
          )}
        </div>
      </div>
      <div style={{ fontSize: 10, color: isLast ? theme.ink : theme.inkFaint, fontFamily: 'JetBrains Mono, monospace', fontWeight: isLast ? 700 : 500 }}>{week.w}</div>
    </div>
  );
}

// Skill radar chart: pentagon (or N-gon) with animated fill + side-by-side bars.
// `skills` = [{ k: 'Fluency', v: 72, d: '+8' }, ...]
function SkillRadarCard({ skills, theme, isDesktop }) {
  const PROFILES = [
    { id: 'now',        label: 'Now',         values: skills.map(s => s.v) },
    { id: 'lastmonth',  label: 'Last month',  values: skills.map(s => Math.max(20, s.v - 12 + (skills.indexOf(s) % 3 - 1) * 3)) },
    { id: 'goal',       label: 'Goal',        values: skills.map(() => 90) },
    { id: 'level',      label: 'CEFR B1 avg', values: [62, 58, 60, 55, 65] },
    { id: 'level-up',   label: 'CEFR B2 goal', values: [78, 75, 76, 72, 80] },
  ];
  const [active, setActive] = uSx('now');
  const cur = PROFILES.find(p => p.id === active);
  const N = skills.length;
  const size = isDesktop ? 280 : 240;
  const cx = size / 2, cy = size / 2, R = size * 0.38;

  // Animation: tween 0 → cur.values when profile changes
  const [anim, setAnim] = uSx(skills.map(() => 0));
  uEx(() => {
    let raf, t0;
    const start = anim;
    const target = cur.values;
    const dur = 700;
    const ease = (x) => 1 - Math.pow(1 - x, 3);
    const tick = (now) => {
      if (!t0) t0 = now;
      const p = Math.min(1, (now - t0) / dur);
      setAnim(start.map((s, i) => Math.round(s + (target[i] - s) * ease(p))));
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [active]);

  // Geometry: angle per vertex, starting at top (-90°)
  const point = (i, ratio) => {
    const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
    return [cx + Math.cos(a) * R * ratio, cy + Math.sin(a) * R * ratio];
  };
  const polygon = (vals) => vals.map((v, i) => point(i, v / 100).join(',')).join(' ');
  const overall = Math.round(skills.reduce((s, x) => s + x.v, 0) / skills.length);

  return (
    <Card theme={theme} padding={isDesktop ? 22 : 18} style={{ marginBottom: 22 }}>
      {/* Profile chips */}
      <div style={{ display: 'flex', gap: 8, overflowX: 'auto', marginBottom: 18, scrollbarWidth: 'none', paddingBottom: 2 }}>
        {PROFILES.map(p => {
          const isActive = p.id === active;
          return (
            <button key={p.id} onClick={() => setActive(p.id)} style={{
              flexShrink: 0, padding: '7px 14px', borderRadius: 999,
              border: `1px solid ${isActive ? theme.ink : theme.border}`,
              background: isActive ? theme.ink : theme.surface,
              color: isActive ? theme.bg : theme.ink,
              fontFamily: 'inherit', fontSize: 12.5, fontWeight: 600, cursor: 'pointer',
              transition: 'all .15s ease', whiteSpace: 'nowrap',
            }}>{p.label}</button>
          );
        })}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: isDesktop ? `${size + 32}px 1fr` : '1fr', gap: isDesktop ? 28 : 18, alignItems: 'center' }}>
        {/* Radar */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ overflow: 'visible' }}>
            {/* Grid rings */}
            {[0.25, 0.5, 0.75, 1].map((ratio, i) => (
              <polygon key={i}
                points={Array.from({ length: N }, (_, j) => point(j, ratio).join(',')).join(' ')}
                fill="none" stroke={theme.border} strokeWidth="1" opacity={0.8} />
            ))}
            {/* Spokes */}
            {Array.from({ length: N }, (_, i) => {
              const [px, py] = point(i, 1);
              return <line key={i} x1={cx} y1={cy} x2={px} y2={py} stroke={theme.border} strokeWidth="1" opacity={0.6} />;
            })}
            {/* Filled value polygon */}
            <polygon points={polygon(anim)}
              fill={theme.accent} fillOpacity="0.22"
              stroke={theme.accent} strokeWidth="2" strokeLinejoin="round"
              style={{ transition: 'all .3s ease' }} />
            {/* Value dots */}
            {anim.map((v, i) => {
              const [px, py] = point(i, v / 100);
              return (
                <g key={i}>
                  <circle cx={px} cy={py} r="4.5" fill={theme.accent} stroke="#fff" strokeWidth="2" />
                </g>
              );
            })}
            {/* Center dot */}
            <circle cx={cx} cy={cy} r="3" fill={theme.inkSoft} />
            {/* Axis labels + values */}
            {skills.map((s, i) => {
              const [lx, ly] = point(i, 1.18);
              const [vx, vy] = point(i, (anim[i] / 100) - 0.08);
              const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
              const anchor = Math.abs(Math.cos(a)) < 0.2 ? 'middle' : (Math.cos(a) > 0 ? 'start' : 'end');
              return (
                <g key={i}>
                  <text x={lx} y={ly} textAnchor={anchor} dominantBaseline="middle"
                    style={{ fontSize: 12, fontFamily: 'Plus Jakarta Sans, sans-serif', fontWeight: 500, fill: theme.ink }}>
                    {t(s.k)}
                  </text>
                  <text x={vx} y={vy} textAnchor="middle" dominantBaseline="middle"
                    style={{ fontSize: 11, fontFamily: 'JetBrains Mono, monospace', fill: theme.accent, fontWeight: 700 }}>
                    {anim[i]}
                  </text>
                </g>
              );
            })}
          </svg>
        </div>

        {/* Attributes panel */}
        <div>
          <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.14em', textTransform: 'uppercase', marginBottom: 12 }}>{t('Attributes')}</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
            {skills.map((s, i) => (
              <div key={s.k} style={{ display: 'grid', gridTemplateColumns: '100px 1fr 36px', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{t(s.k)}</span>
                <div style={{ height: 6, background: theme.surfaceAlt, borderRadius: 999, overflow: 'hidden' }}>
                  <div style={{
                    width: `${anim[i]}%`, height: '100%', background: theme.accent,
                    borderRadius: 999, transition: 'width .35s cubic-bezier(.22,.61,.36,1)',
                  }} />
                </div>
                <span style={{ fontSize: 13, color: theme.ink, fontWeight: 700, fontFamily: 'JetBrains Mono, monospace', textAlign: 'right' }}>{anim[i]}</span>
              </div>
            ))}
          </div>

          {/* Overall rating */}
          <div style={{
            marginTop: 16, padding: '12px 14px', borderRadius: 12,
            border: `1px solid ${theme.border}`, background: theme.surfaceAlt,
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          }}>
            <div>
              <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.06em' }}>{t('Overall rating')}</div>
              <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 36, color: theme.ink, lineHeight: 1, marginTop: 2 }}>
                <AnimatedNumber value={Math.round(anim.reduce((s, x) => s + x, 0) / N)} duration={500} />
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.06em' }}>{cur.label}</div>
              <div style={{ fontSize: 12, color: theme.good, fontWeight: 700, fontFamily: 'JetBrains Mono, monospace', marginTop: 4 }}>
                {skills.map(s => s.d).join(' · ')}
              </div>
            </div>
          </div>
        </div>
      </div>
    </Card>
  );
}

// ═════════════════════════════════════════════════════════════════════════
// PROGRESS — charts, badges
// ═════════════════════════════════════════════════════════════════════════
function ProgressScreen({ theme, layout, persona }) {
  const isDesktop = layout === 'desktop';
  const weeks = [
    { w: 'W1', val: 28, sess: 4 },
    { w: 'W2', val: 35, sess: 5 },
    { w: 'W3', val: 42, sess: 6 },
    { w: 'W4', val: 38, sess: 5 },
    { w: 'W5', val: 51, sess: 7 },
    { w: 'W6', val: 58, sess: 8 },
    { w: 'W7', val: 64, sess: 7 },
  ];
  const max = Math.max(...weeks.map(w => w.val));

  const skills = [
    { k: 'Fluency',       v: 72, d: '+8' },
    { k: 'Grammar',       v: 58, d: '+3' },
    { k: 'Vocabulary',    v: 66, d: '+5' },
    { k: 'Pronunciation', v: 60, d: '+6' },
  ];

  const badges = [
    { n: 'First Word',     k: 'flame',  unlocked: true },
    { n: '7-day Streak',   k: 'flame',  unlocked: true },
    { n: '1,000 Words',    k: 'book',   unlocked: true },
    { n: 'Café Master',    k: 'coffee', unlocked: true },
    { n: 'Interview Ready',k: 'briefcase', unlocked: false },
    { n: 'Debate Champ',   k: 'grad',   unlocked: false },
  ];

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, overflow: 'auto' }}>
      <div style={{ padding: isDesktop ? '32px 48px 48px' : '20px 18px 32px', maxWidth: isDesktop ? 940 : '100%', margin: '0 auto' }}>
        <h1 style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 40 : 28, fontWeight: 400, margin: '0 0 4px', letterSpacing: '-0.02em' }}>{t('Your')} <span style={{ fontStyle: 'italic', color: theme.accent }}>{t('progress')}</span></h1>
        <p style={{ color: theme.inkSoft, fontSize: 13, margin: '0 0 22px' }}>{t('7 weeks in. Up and to the right.')}</p>

        {/* CEFR card */}
        <Card theme={theme} padding={isDesktop ? 24 : 18} style={{ marginBottom: 18 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            <div style={{ width: 64, height: 64, borderRadius: 16, background: theme.accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Instrument Serif, serif', fontSize: 30 }}>B1</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.1em', textTransform: 'uppercase' }}>{t('Current level')}</div>
              <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 22, color: theme.ink, marginTop: 2 }}>{t('Intermediate · climbing toward B2')}</div>
              <div style={{ marginTop: 8 }}>
                <Bar value={64} color={theme.accent} track={theme.accentSoft} height={6} />
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: theme.inkFaint, marginTop: 4, fontFamily: 'JetBrains Mono, monospace' }}>
                  <span>A1</span><span>A2</span><span>B1</span><span>B2</span><span>C1</span><span>C2</span>
                </div>
              </div>
            </div>
          </div>
        </Card>

        {/* Activity chart */}
        <Card theme={theme} padding={isDesktop ? 24 : 18} style={{ marginBottom: 18 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 16, gap: 12, flexWrap: 'wrap' }}>
            <div>
              <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.08em', textTransform: 'uppercase' }}>{t('Minutes spoken')}</div>
              <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 24, color: theme.ink, marginTop: 2 }}><AnimatedNumber value={316} duration={1400} /> {t('min')} · {t('last 7 weeks')}</div>
            </div>
            <div style={{ display: 'flex', gap: 4, background: theme.surfaceAlt, padding: 3, borderRadius: 999 }}>
              {['7w','30d','All'].map((r, i) => (
                <button key={r} style={{
                  padding: '5px 11px', borderRadius: 999, border: 'none', cursor: 'pointer',
                  background: i === 0 ? theme.surface : 'transparent',
                  color: i === 0 ? theme.ink : theme.inkSoft,
                  fontSize: 11.5, fontWeight: 600, fontFamily: 'inherit',
                  boxShadow: i === 0 ? '0 1px 3px rgba(0,0,0,.08)' : 'none',
                }}>{r}</button>
              ))}
            </div>
          </div>

          {/* Summary stat grid */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginBottom: 18 }}>
            {[
              { lbl: t('Avg / day'),   val: 6.4,  suffix: ' ' + t('min'), color: theme.accent, delta: '+0.9' },
              { lbl: t('Best day'),    val: 14,   suffix: ' ' + t('min'), color: theme.good,   delta: 'Sat' },
              { lbl: t('Sessions'),    val: 42,   suffix: '',             color: theme.warn,   delta: '+8' },
              { lbl: t('Day streak'),  val: 12,   suffix: 'd',            color: theme.bad,    delta: '🔥' },
            ].map((s, i) => (
              <div key={i} style={{
                padding: '10px 12px', borderRadius: 12,
                background: theme.surfaceAlt, position: 'relative',
                animation: `ft-fade-in .5s both ${.1 + i*.06}s`,
              }}>
                <div style={{ fontSize: 10, color: theme.inkFaint, letterSpacing: '.06em', textTransform: 'uppercase', marginBottom: 4 }}>{s.lbl}</div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                  <span style={{ fontFamily: 'Instrument Serif, serif', fontSize: 22, color: theme.ink, lineHeight: 1 }}>
                    <AnimatedNumber value={s.val} duration={1200} delay={200 + i * 80} decimals={Number.isInteger(s.val) ? 0 : 1} />
                  </span>
                  <span style={{ fontSize: 11, color: theme.inkSoft }}>{s.suffix}</span>
                </div>
                <div style={{ marginTop: 4, fontSize: 10.5, color: s.color, fontWeight: 600, fontFamily: 'JetBrains Mono, monospace' }}>{s.delta}</div>
              </div>
            ))}
          </div>

          {/* Bar chart with goal line */}
          <div style={{ position: 'relative', height: 160, paddingTop: 14 }}>
            {/* Goal dotted line at 50 min */}
            <div style={{
              position: 'absolute', left: 0, right: 0,
              top: `${14 + (1 - 50 / max) * 140}px`,
              borderTop: `1.5px dashed ${theme.accent}66`, zIndex: 1,
            }}>
              <span style={{
                position: 'absolute', right: 0, top: -10,
                fontSize: 10, color: theme.accent, fontWeight: 600,
                background: theme.surface, padding: '0 6px', borderRadius: 4,
                fontFamily: 'JetBrains Mono, monospace',
              }}>{t('Goal')} 50</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, height: '100%', position: 'relative', zIndex: 2 }}>
              {weeks.map((w, i) => (
                <ChartBar key={w.w} week={w} idx={i} total={weeks.length} max={max} theme={theme} />
              ))}
            </div>
          </div>

          {/* Time-of-day breakdown */}
          <div style={{
            marginTop: 18, paddingTop: 16,
            borderTop: `1px solid ${theme.border}`,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.08em', textTransform: 'uppercase' }}>{t('Time of day')}</div>
              <div style={{ fontSize: 11, color: theme.inkSoft }}>{t('You speak most in the')} <strong style={{ color: theme.ink, fontWeight: 700 }}>{t('evening')}</strong></div>
            </div>
            <div style={{ display: 'flex', gap: 4, height: 32 }}>
              {[
                { lbl: t('Morning'), pct: 18, hint: '6–12' },
                { lbl: t('Midday'),  pct: 22, hint: '12–17' },
                { lbl: t('Evening'), pct: 46, hint: '17–22' },
                { lbl: t('Night'),   pct: 14, hint: '22–6' },
              ].map((seg, i) => (
                <div key={i} title={`${seg.lbl} · ${seg.pct}% · ${seg.hint}`} style={{
                  flex: seg.pct, borderRadius: 6, position: 'relative',
                  background: i === 2 ? theme.accent : theme.accentSoft,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: i === 2 ? '#fff' : theme.accentInk,
                  fontSize: 11, fontWeight: 600,
                  transition: 'background .2s ease',
                  animation: `ft-fade-in .5s both ${.5 + i*.07}s`,
                }}>{seg.pct}%</div>
              ))}
            </div>
            <div style={{ display: 'flex', gap: 4, marginTop: 6 }}>
              {[{lbl: t('Morning'), pct: 18}, {lbl: t('Midday'), pct: 22}, {lbl: t('Evening'), pct: 46}, {lbl: t('Night'), pct: 14}].map((seg, i) => (
                <div key={i} style={{ flex: seg.pct, fontSize: 10, color: theme.inkFaint, textAlign: 'center', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{seg.lbl}</div>
              ))}
            </div>
          </div>
        </Card>

        {/* Skills — radar + bars combo */}
        <SectionHead theme={theme} kicker={t('Skill breakdown')} title={t('Where you’re strong, where to push')} />
        <SkillRadarCard skills={[
          { k: 'Fluency',       v: 72, d: '+8' },
          { k: 'Grammar',       v: 58, d: '+3' },
          { k: 'Vocabulary',    v: 66, d: '+5' },
          { k: 'Pronunciation', v: 60, d: '+6' },
          { k: 'Listening',     v: 80, d: '+4' },
        ]} theme={theme} isDesktop={isDesktop} />

        {/* Badges */}
        <SectionHead theme={theme} kicker={t('Badges')} title={t('Trophies & milestones')} />
        <div style={{ display: 'grid', gridTemplateColumns: isDesktop ? 'repeat(6, 1fr)' : 'repeat(3, 1fr)', gap: 10 }}>
          {badges.map((b, i) => (
            <Card key={b.n} theme={theme} padding={12} style={{ textAlign: 'center', opacity: b.unlocked ? 1 : 0.45, animation: `ft-pop-in .5s both ${i*.06}s` }}>
              <div style={{ width: 48, height: 48, borderRadius: '50%', background: b.unlocked ? theme.accent : theme.surfaceAlt, color: b.unlocked ? '#fff' : theme.inkFaint, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 8px' }}>
                <Icon name={b.k} size={20} />
              </div>
              <div style={{ fontSize: 11.5, fontWeight: 600, color: theme.ink }}>{t(b.n)}</div>
              {!b.unlocked && <div style={{ fontSize: 10, color: theme.inkFaint, marginTop: 2 }}>{t('Locked')}</div>}
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════
// COURSE — learning path customization
// ═════════════════════════════════════════════════════════════════════════
function CourseScreen({ theme, layout, nav, state, setState }) {
  const isDesktop = layout === 'desktop';
  const focus = state.courseFocus || ['travel', 'biz'];
  const tone = state.courseTone || 'realistic';
  const minutes = state.courseMinutes || 15;

  const toggle = (k) => setState({ ...state, courseFocus: focus.includes(k) ? focus.filter(x => x !== k) : [...focus, k] });

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, overflow: 'auto' }}>
      <div style={{ padding: isDesktop ? '32px 48px 48px' : '20px 18px 32px', maxWidth: isDesktop ? 920 : '100%', margin: '0 auto' }}>
        <h1 style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 40 : 28, fontWeight: 400, margin: '0 0 4px', letterSpacing: '-0.02em' }}>{t('Build your')} <span style={{ fontStyle: 'italic', color: theme.accent }}>{t('course')}</span></h1>
        <p style={{ color: theme.inkSoft, fontSize: 13, margin: '0 0 24px' }}>{t('Tell us how you live and we’ll script lessons around it.')}</p>

        {/* Focus areas */}
        <SectionHead theme={theme} kicker="01" title={t('What should we drill?')} />
        <div style={{ display: 'grid', gridTemplateColumns: isDesktop ? 'repeat(3, 1fr)' : '1fr 1fr', gap: 10, marginBottom: 22 }}>
          {[
            { id: 'travel', icon: 'plane',     t: t('Travel')   },
            { id: 'biz',    icon: 'briefcase', t: t('Business') },
            { id: 'daily',  icon: 'home',      t: t('Daily life') },
            { id: 'school', icon: 'grad',      t: t('Academic') },
            { id: 'free',   icon: 'chat',      t: t('Free chat') },
            { id: 'role',   icon: 'sparkle',   t: t('Roleplay') },
          ].map((c, i) => {
            const active = focus.includes(c.id);
            return (
              <Card key={c.id} theme={theme} padding={14} onClick={() => toggle(c.id)} hoverable
                style={{
                  border: active ? `1.5px solid ${theme.accent}` : `1px solid ${theme.border}`,
                  background: active ? theme.accentSoft : theme.surface,
                  textAlign: 'center', animation: `ft-pop-in .4s both ${i*.05}s`,
                }}>
                <div style={{ width: 40, height: 40, borderRadius: 12, background: active ? theme.accent : theme.surfaceAlt, color: active ? '#fff' : theme.inkSoft, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 8px' }}>
                  <Icon name={c.icon} size={18} />
                </div>
                <div style={{ fontWeight: 600, fontSize: 13 }}>{c.t}</div>
              </Card>
            );
          })}
        </div>

        {/* Style */}
        <SectionHead theme={theme} kicker="02" title={t('What kind of conversations?')} />
        <div style={{ display: 'grid', gridTemplateColumns: isDesktop ? 'repeat(3, 1fr)' : '1fr', gap: 10, marginBottom: 22 }}>
          {[
            { id: 'realistic', t: t('Realistic'), d: t('Match real-world cadence, accents, slang.') },
            { id: 'clean',     t: t('Clean'),     d: t('Textbook clarity. Slow and structured.') },
            { id: 'playful',   t: t('Playful'),   d: t('Games, jokes, role-play scenarios.') },
          ].map((o) => {
            const active = tone === o.id;
            return (
              <Card key={o.id} theme={theme} padding={14} onClick={() => setState({ ...state, courseTone: o.id })} hoverable
                style={{ border: active ? `1.5px solid ${theme.accent}` : `1px solid ${theme.border}`, background: active ? theme.accentSoft : theme.surface }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{o.t}</div>
                  <div style={{ width: 18, height: 18, borderRadius: 9, border: `1.5px solid ${active ? theme.accent : theme.border}`, background: active ? theme.accent : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    {active && <Icon name="check" size={11} stroke="#fff" />}
                  </div>
                </div>
                <div style={{ fontSize: 12, color: theme.inkSoft, marginTop: 4 }}>{o.d}</div>
              </Card>
            );
          })}
        </div>

        {/* Minutes */}
        <SectionHead theme={theme} kicker="03" title={t('How much time per day?')} />
        <Card theme={theme} padding={isDesktop ? 22 : 18} style={{ marginBottom: 22 }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
            <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 36, color: theme.ink, lineHeight: 1 }}>{minutes}<span style={{ fontSize: 16, color: theme.inkSoft }}> {t('min')}</span></div>
            <div style={{ fontSize: 12, color: theme.inkSoft }}>~{Math.round(minutes * 7 / 60 * 10) / 10} {t('hrs / week')}</div>
          </div>
          <input type="range" min={5} max={45} step={5} value={minutes} onChange={(e) => setState({ ...state, courseMinutes: +e.target.value })}
            style={{ width: '100%', accentColor: theme.accent }} />
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: theme.inkFaint, fontFamily: 'JetBrains Mono, monospace', marginTop: 6 }}>
            <span>5</span><span>15</span><span>25</span><span>35</span><span>45</span>
          </div>
        </Card>

        {/* Path preview */}
        <SectionHead theme={theme} kicker={t('Your plan')} title={t('Next 4 weeks')} />
        <div style={{ position: 'relative', paddingLeft: 26 }}>
          <div style={{ position: 'absolute', left: 11, top: 8, bottom: 8, width: 2, background: theme.border }} />
          {[
            { w: t('Week 1'), t: t('Foundations: small talk & introductions'), n: '5 ' + t('sessions') },
            { w: t('Week 2'), t: t('Travel core: arrivals, navigation, food'),  n: '6 ' + t('sessions') },
            { w: t('Week 3'), t: t('Business basics: meetings & email-speak'),  n: '5 ' + t('sessions') },
            { w: t('Week 4'), t: t('Mock interview week'),                       n: '4 ' + t('sessions') + ' · ' + t('placement') },
          ].map((p, i) => (
            <div key={i} style={{ position: 'relative', paddingBottom: 14, animation: `ft-slide-up .5s both ${i*.08}s` }}>
              <div style={{ position: 'absolute', left: -26, top: 4, width: 24, height: 24, borderRadius: 12, background: theme.accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 700 }}>{i + 1}</div>
              <Card theme={theme} padding={12}>
                <div style={{ fontSize: 10, color: theme.inkFaint, letterSpacing: '.1em', textTransform: 'uppercase' }}>{p.w}</div>
                <div style={{ fontWeight: 600, fontSize: 14, marginTop: 2 }}>{p.t}</div>
                <div style={{ fontSize: 11.5, color: theme.inkSoft, marginTop: 2, fontFamily: 'JetBrains Mono, monospace' }}>{p.n}</div>
              </Card>
            </div>
          ))}
        </div>

        <div style={{ marginTop: 20, textAlign: 'center' }}>
          <Button theme={theme} size="lg" iconRight={<Icon name="arrow" size={18} stroke="#fff" />} onClick={() => nav('home')}>{t('Save my course')}</Button>
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════
// SETTINGS — profile, persona switch, prefs
// ═════════════════════════════════════════════════════════════════════════
function SettingsScreen({ theme, persona, difficulty, feedback, nav, layout, tweaks, setTweak }) {
  const isDesktop = layout === 'desktop';
  const [editOpen, setEditOpen] = uSx(false);
  const [editName, setEditName] = uSx(tweaks.profileName || 'Jamie Chen');
  const [editLevel, setEditLevel] = uSx(tweaks.profileLevel || 'B1 · Intermediate');
  const [curPwd, setCurPwd] = uSx('');
  const [newPwd, setNewPwd] = uSx('');
  const [confirmPwd, setConfirmPwd] = uSx('');
  const [showPwd, setShowPwd] = uSx(false);
  const [editError, setEditError] = uSx(null);

  const saveProfile = () => {
    if (!editName.trim()) { setEditError('Name is required.'); return; }
    // Password change is optional — only validate if any field is filled
    const anyPwd = curPwd || newPwd || confirmPwd;
    if (anyPwd) {
      if (!curPwd) { setEditError('Enter your current password.'); return; }
      if (newPwd.length < 6) { setEditError('New password must be at least 6 characters.'); return; }
      if (newPwd !== confirmPwd) { setEditError('New passwords don\u2019t match.'); return; }
    }
    setTweak({ profileName: editName.trim(), profileLevel: editLevel });
    setEditOpen(false);
    setCurPwd(''); setNewPwd(''); setConfirmPwd('');
    setEditError(null);
  };

  const profileName = tweaks.profileName || 'Jamie Chen';
  const profileEmail = tweaks.profileEmail || 'jamie@freetalk.app';
  const profileLevel = tweaks.profileLevel || 'B1 · Intermediate';

  const Field = ({ label, children }) => (
    <label style={{ display: 'block' }}>
      <div style={{ fontSize: 12, fontWeight: 600, color: theme.inkSoft, marginBottom: 6 }}>{label}</div>
      {children}
    </label>
  );
  const inputStyle = {
    width: '100%', height: 42, padding: '0 12px',
    background: theme.surface, color: theme.ink,
    border: `1px solid ${theme.border}`, borderRadius: 10,
    fontSize: 14, fontFamily: 'inherit', outline: 'none', boxSizing: 'border-box',
  };

  // ── Edit Profile dialog ──
  const EditDialog = () => (
    <div onClick={() => setEditOpen(false)} style={{
      position: 'absolute', inset: 0, zIndex: 50,
      background: 'rgba(15,18,30,.48)', backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
      display: 'flex', alignItems: 'flex-start', justifyContent: 'center',
      padding: isDesktop ? '40px 20px 20px' : '40px 14px 14px',
      animation: 'ft-fade-in .25s ease both',
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        background: theme.surface, color: theme.ink,
        width: '100%', maxWidth: isDesktop ? 480 : '100%',
        borderRadius: 22, overflow: 'hidden',
        boxShadow: '0 24px 60px rgba(0,0,0,.28), 0 0 0 1px ' + theme.border,
        animation: 'ft-pop-in .35s cubic-bezier(.34,1.56,.64,1) both',
        display: 'flex', flexDirection: 'column',
        maxHeight: 'calc(100% - 0px)',
      }}>
        {/* Header */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '14px 14px 14px 18px',
          borderBottom: `1px solid ${theme.border}`,
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 700, fontSize: 15, color: theme.ink }}>{t('Edit profile')}</div>
            <div style={{ fontSize: 11.5, color: theme.inkFaint, marginTop: 1 }}>{t('Update your account details.')}</div>
          </div>
          <button onClick={() => setEditOpen(false)} title="Close" style={{
            width: 32, height: 32, borderRadius: 8, border: 'none',
            background: 'transparent', color: theme.inkSoft, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0,
          }}
          onMouseEnter={e => e.currentTarget.style.background = theme.surfaceAlt}
          onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M3 3l10 10M13 3L3 13" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"/>
            </svg>
          </button>
        </div>

        {/* Body — scrollable */}
        <div style={{ padding: '18px 18px 16px', display: 'flex', flexDirection: 'column', gap: 14, overflowY: 'auto' }}>
          {/* Avatar preview */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 4 }}>
            <div style={{
              width: 64, height: 64, borderRadius: '50%',
              background: theme.accent, color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Instrument Serif, serif', fontSize: 28, letterSpacing: '-0.01em',
              boxShadow: `0 6px 18px ${theme.accent}55`,
            }}>{(editName || 'J').slice(0, 1).toUpperCase()}</div>
            <button style={{
              padding: '8px 14px', borderRadius: 999,
              border: `1px solid ${theme.border}`, background: theme.surface,
              color: theme.ink, fontSize: 12.5, fontWeight: 600, cursor: 'pointer',
              fontFamily: 'inherit',
            }}>{t('Change photo')}</button>
          </div>

          {/* Name */}
          <Field label={t('Name')}>
            <input value={editName} onChange={e => setEditName(e.target.value)} style={inputStyle} />
          </Field>

          {/* Level */}
          <Field label={t('Level')}>
            <select value={editLevel} onChange={e => setEditLevel(e.target.value)} style={{ ...inputStyle, appearance: 'none' }}>
              <option>A1 · Starter</option>
              <option>A2 · Elementary</option>
              <option>B1 · Intermediate</option>
              <option>B2 · Upper-Intermediate</option>
              <option>C1 · Advanced</option>
              <option>C2 · Mastery</option>
            </select>
          </Field>

          {/* Password section */}
          <div style={{
            marginTop: 6, paddingTop: 14, borderTop: `1px solid ${theme.border}`,
            display: 'flex', flexDirection: 'column', gap: 12,
          }}>
            <div>
              <div style={{ fontWeight: 700, fontSize: 13.5, color: theme.ink }}>{t('Change password')}</div>
              <div style={{ fontSize: 11.5, color: theme.inkFaint, marginTop: 2 }}>{t('Leave blank to keep your current password.')}</div>
            </div>
            <Field label={t('Current password')}>
              <input type={showPwd ? 'text' : 'password'} value={curPwd} onChange={e => setCurPwd(e.target.value)} placeholder="••••••••" style={inputStyle} />
            </Field>
            <Field label={t('New password')}>
              <input type={showPwd ? 'text' : 'password'} value={newPwd} onChange={e => setNewPwd(e.target.value)} placeholder={t('Min 6 characters')} style={inputStyle} />
            </Field>
            <Field label={t('Confirm new password')}>
              <input type={showPwd ? 'text' : 'password'} value={confirmPwd} onChange={e => setConfirmPwd(e.target.value)} placeholder="••••••••" style={inputStyle} />
            </Field>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12.5, color: theme.inkSoft, cursor: 'pointer' }}>
              <span onClick={() => setShowPwd(s => !s)} style={{ width: 16, height: 16, borderRadius: 4, border: `1.5px solid ${showPwd ? theme.accent : theme.border}`, background: showPwd ? theme.accent : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all .15s' }}>
                {showPwd && <Icon name="check" size={10} stroke="#fff" />}
              </span>
              {t('Show passwords')}
            </label>
          </div>

          {editError && <div style={{ fontSize: 12, color: theme.bad, marginTop: -4 }}>{editError}</div>}
        </div>

        {/* Footer */}
        <div style={{
          display: 'flex', justifyContent: 'flex-end', gap: 8,
          padding: '12px 16px 16px', borderTop: `1px solid ${theme.border}`,
        }}>
          <button onClick={() => setEditOpen(false)} style={{
            padding: '9px 16px', borderRadius: 10,
            border: `1px solid ${theme.border}`, background: theme.surface,
            color: theme.ink, fontSize: 13, fontWeight: 600, cursor: 'pointer',
            fontFamily: 'inherit',
          }}>{t('Cancel')}</button>
          <button onClick={saveProfile} style={{
            padding: '9px 16px', borderRadius: 10, border: 'none',
            background: theme.accent, color: '#fff',
            fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
            boxShadow: `0 4px 12px ${theme.accent}66`,
          }}>{t('Save changes')}</button>
        </div>
      </div>
    </div>
  );

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, overflow: 'auto', position: 'relative' }}>
      <div style={{ padding: isDesktop ? '32px 48px 48px' : '20px 18px 32px', maxWidth: isDesktop ? 760 : '100%', margin: '0 auto' }}>
        <h1 className="ft-serif" style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 40 : 28, fontWeight: 400, margin: '0 0 22px', letterSpacing: '-0.02em' }}>{t('Settings')}</h1>

        {/* Profile */}
        <Card theme={theme} padding={isDesktop ? 22 : 18} style={{ marginBottom: 22, display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 56, height: 56, borderRadius: '50%', background: theme.surfaceAlt, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Instrument Serif, serif', fontSize: 24, color: theme.ink }}>{(profileName || 'J').slice(0,1).toUpperCase()}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 600, fontSize: 16 }}>{profileName}</div>
            <div style={{ fontSize: 12, color: theme.inkSoft }}>{profileEmail} · {profileLevel}</div>
          </div>
          <Button theme={theme} variant="outline" size="sm" onClick={() => { setEditOpen(true); setEditError(null); setCurPwd(''); setNewPwd(''); setConfirmPwd(''); }}>{t('Edit')}</Button>
        </Card>

        {editOpen && <EditDialog />}

        {/* Tutor persona — linear carousel with arrow buttons on both ends */}
        <SectionHead theme={theme} kicker={t('Tutor')} title={t('Choose your speaking partner')} />
        {(() => {
          const personaIds = Object.keys(PERSONAS).filter(id => PERSONAS[id].enabled !== false);
          const activeIdx = Math.max(0, personaIds.indexOf(persona));
          const cycle = (dir) => {
            const next = (activeIdx + dir + personaIds.length) % personaIds.length;
            setTweak('persona', personaIds[next]);
          };
          const active = PERSONAS[personaIds[activeIdx]];
          const prev = PERSONAS[personaIds[(activeIdx - 1 + personaIds.length) % personaIds.length]];
          const next = PERSONAS[personaIds[(activeIdx + 1) % personaIds.length]];
          const ArrowBtn = ({ onClick, dir, hint }) => (
            <button onClick={onClick} aria-label={dir === -1 ? 'previous' : 'next'} style={{
              flexShrink: 0, width: 44, height: 44, borderRadius: '50%',
              border: `1px solid ${theme.border}`, background: theme.surface, color: theme.ink,
              display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
              boxShadow: '0 4px 12px rgba(0,0,0,.06)', transition: 'transform .15s ease, background .15s ease',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = theme.accentSoft; e.currentTarget.style.transform = `translateX(${dir * 2}px)`; }}
            onMouseLeave={e => { e.currentTarget.style.background = theme.surface; e.currentTarget.style.transform = 'translateX(0)'; }}
            title={hint}>
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style={{ transform: dir === -1 ? 'rotate(180deg)' : 'none' }}>
                <path d="M5 3l5 5-5 5" stroke={theme.ink} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          );
          return (
            <Card theme={theme} padding={isDesktop ? 22 : 18} style={{
              marginBottom: 22, position: 'relative', overflow: 'hidden',
              background: `linear-gradient(135deg, ${theme.accentSoft} 0%, ${theme.surface} 70%)`,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: isDesktop ? 16 : 12 }}>
                <ArrowBtn onClick={() => cycle(-1)} dir={-1} hint={prev.name} />
                <div style={{
                  flex: 1, display: 'flex', alignItems: 'center', gap: isDesktop ? 18 : 14,
                  padding: '4px 4px',
                }}>
                  <div key={persona} style={{
                    flexShrink: 0, animation: 'ft-fade-in .35s ease-out',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    width: isDesktop ? 96 : 84, height: isDesktop ? 96 : 84,
                    borderRadius: '50%', overflow: 'hidden',
                    background: theme.surface,
                    boxShadow: `0 8px 24px ${theme.accent}33, 0 0 0 3px ${theme.accent}`,
                  }}>
                    <TalkingAvatar persona={persona} mode="idle" size={isDesktop ? 96 : 84} theme={theme} />
                  </div>
                  <div key={persona + '-info'} style={{ flex: 1, minWidth: 0, animation: 'ft-fade-in .35s ease-out .05s both' }}>
                    <div className="ft-serif" style={{
                      fontFamily: 'Instrument Serif, serif',
                      fontSize: isDesktop ? 30 : 26, color: theme.ink,
                      lineHeight: 1.1, letterSpacing: '-0.01em',
                    }}>{active.name}</div>
                    <div style={{ fontSize: 12.5, color: theme.inkSoft, marginTop: 4 }}>{active.role}</div>
                    <div style={{
                      display: 'inline-flex', alignItems: 'center', gap: 6,
                      marginTop: 10, padding: '4px 10px', borderRadius: 999,
                      background: theme.accent, color: '#fff',
                      fontSize: 10.5, fontWeight: 600, letterSpacing: '.08em', textTransform: 'uppercase',
                    }}>
                      <Icon name="check" size={10} stroke="#fff" /> {t('Selected')}
                    </div>
                  </div>
                </div>
                <ArrowBtn onClick={() => cycle(1)} dir={1} hint={next.name} />
              </div>
              {/* Dots indicator */}
              <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginTop: 14 }}>
                {personaIds.map((id, i) => (
                  <button key={id} onClick={() => setTweak('persona', id)} aria-label={PERSONAS[id].name} style={{
                    width: i === activeIdx ? 22 : 7, height: 7, borderRadius: 4,
                    border: 'none', cursor: 'pointer', padding: 0,
                    background: i === activeIdx ? theme.accent : theme.border,
                    transition: 'width .25s ease, background .25s ease',
                  }} />
                ))}
              </div>
            </Card>
          );
        })()}

        {/* Difficulty */}
        <SectionHead theme={theme} kicker={t('Difficulty')} title={t('Level of challenge')} />
        <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
          {Object.entries(DIFFICULTIES).map(([id, d]) => {
            const active = difficulty === id;
            return (
              <Card key={id} theme={theme} padding={12} hoverable onClick={() => setTweak('difficulty', id)}
                style={{ flex: 1, border: active ? `1.5px solid ${theme.accent}` : `1px solid ${theme.border}`, background: active ? theme.accentSoft : theme.surface, textAlign: 'center' }}>
                <div style={{ fontWeight: 600, fontSize: 13.5 }}>{d.label}</div>
                <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 10, color: theme.inkFaint, marginTop: 2 }}>{d.cefr}</div>
              </Card>
            );
          })}
        </div>

        {/* Feedback */}
        <SectionHead theme={theme} kicker={t('Feedback')} title={t('How tough should the report be?')} />
        <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
          {Object.entries(FEEDBACKS).map(([id, f]) => {
            const active = feedback === id;
            return (
              <Card key={id} theme={theme} padding={12} hoverable onClick={() => setTweak('feedback', id)}
                style={{ flex: 1, border: active ? `1.5px solid ${theme.accent}` : `1px solid ${theme.border}`, background: active ? theme.accentSoft : theme.surface, textAlign: 'center' }}>
                <div style={{ fontWeight: 600, fontSize: 13.5 }}>{f.label}</div>
                <div style={{ fontSize: 10, color: theme.inkFaint, marginTop: 4, lineHeight: 1.3 }}>{f.tagline}</div>
              </Card>
            );
          })}
        </div>

        {/* Theme */}
        <SectionHead theme={theme} kicker={t('Appearance')} title={t('Theme')} />
        <div style={{ display: 'flex', gap: 10, marginBottom: 22 }}>
          {Object.entries(THEMES).map(([id, t]) => {
            const active = tweaks.theme === id;
            return (
              <button key={id} onClick={() => setTweak('theme', id)} style={{
                flex: 1, padding: 10, borderRadius: 14,
                border: active ? `1.5px solid ${theme.accent}` : `1px solid ${theme.border}`,
                background: t.bg, color: t.ink, cursor: 'pointer',
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              }}>
                <div style={{ display: 'flex', gap: 4 }}>
                  <div style={{ width: 14, height: 14, borderRadius: 4, background: t.accent }} />
                  <div style={{ width: 14, height: 14, borderRadius: 4, background: t.surfaceAlt }} />
                </div>
                <div style={{ fontSize: 11, fontWeight: 600 }}>{t.name}</div>
              </button>
            );
          })}
        </div>

        {/* Other settings */}
        <SectionHead theme={theme} kicker={t('Other')} title={t('Preferences')} />
        <Card theme={theme} padding={0}>
          {(() => {
            const langLabels = { en: 'English', zh: '中文', ko: '한국어' };
            const langOrder = ['en', 'zh', 'ko'];
            const curLang = tweaks.lang || 'en';
            const cycleLang = () => {
              const next = langOrder[(langOrder.indexOf(curLang) + 1) % langOrder.length];
              setTweak('lang', next);
            };
            const fontOptions = ['Sans', 'Serif', 'Mono'];
            const curFont = tweaks.font || 'Sans';
            const cycleFont = () => {
              const next = fontOptions[(fontOptions.indexOf(curFont) + 1) % fontOptions.length];
              setTweak('font', next);
            };
            const rows = [
              { label: t('App language'),          value: langLabels[curLang], icon: 'globe', onClick: cycleLang },
              { label: t('Voice playback speed'),   value: '1.0×',             icon: 'play' },
              { label: t('Font'),                   value: curFont,            icon: 'book', onClick: cycleFont },
              { label: t('Sign out'),               value: '',                 icon: 'arrow', danger: true, onClick: () => nav('signin') },
            ];
            return rows.map((row, i, arr) => (
              <div key={i} onClick={row.onClick} style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 14, borderBottom: i < arr.length - 1 ? `1px solid ${theme.border}` : 'none', cursor: row.onClick ? 'pointer' : 'default', transition: 'background .15s ease' }}
                onMouseEnter={e => { if (row.onClick) e.currentTarget.style.background = theme.surfaceAlt; }}
                onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; }}>
                <div style={{ width: 28, height: 28, borderRadius: 8, background: theme.surfaceAlt, color: row.danger ? theme.bad : theme.inkSoft, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Icon name={row.icon} size={14} />
                </div>
                <div style={{ flex: 1, fontSize: 13.5, color: row.danger ? theme.bad : theme.ink, fontWeight: row.danger ? 600 : 500 }}>{row.label}</div>
                <div style={{ fontSize: 12, color: theme.inkFaint, fontFamily: 'JetBrains Mono, monospace' }}>{row.value}</div>
                {!row.danger && <Icon name="arrow" size={14} stroke={theme.inkFaint} />}
              </div>
            ));
          })()}
        </Card>
      </div>
    </div>
  );
}

Object.assign(window, { ReportScreen, ProgressScreen, CourseScreen, SettingsScreen });

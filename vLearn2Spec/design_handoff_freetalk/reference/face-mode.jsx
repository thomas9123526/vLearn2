// Face-to-face conversation mode — large tutor character on screen,
// designed to feel like a video call with a real (cartoon) human.
// Used by ConvoScreen when convoMode === 'face'.

const { useState: uSf, useEffect: uEf, useRef: uRf } = React;

// ── Hand wave SVG (4-finger flat hand, used in greeting moments) ─────
const WaveHand = ({ size = 80, color = '#f4cba3', shade = '#d8a878' }) => (
  <svg viewBox="0 0 100 100" width={size} height={size}>
    <g style={{ transformOrigin: '50px 90px', animation: 'ftf-wave-hand 1.6s ease-in-out infinite' }}>
      <path d="M30 50 Q 28 30 38 28 Q 46 28 46 42 L 46 55 Q 50 32 60 30 Q 70 30 68 46 L 66 60
               Q 72 38 80 38 Q 88 40 84 56 L 80 70
               Q 84 56 90 58 Q 94 62 88 74 Q 80 90 60 92 Q 36 92 28 76 Q 22 64 24 56 Z" fill={color} />
      <path d="M30 50 Q 28 30 38 28 Q 46 28 46 42 L 46 55" stroke={shade} strokeWidth="1.5" fill="none" />
    </g>
  </svg>
);

// ── Big caption (live closed-captioning effect) ──────────────────────
function LiveCaption({ text, theme, color }) {
  const [shown, setShown] = uSf('');
  uEf(() => {
    setShown('');
    if (!text) return;
    let i = 0;
    const id = setInterval(() => {
      i++;
      setShown(text.slice(0, i));
      if (i >= text.length) clearInterval(id);
    }, 28);
    return () => clearInterval(id);
  }, [text]);
  if (!text) return null;
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 18,
      display: 'flex', justifyContent: 'center', pointerEvents: 'none', zIndex: 4,
    }}>
      <div style={{
        maxWidth: '88%', padding: '14px 22px', borderRadius: 22,
        background: 'rgba(15, 18, 30, 0.72)', color: '#fff',
        backdropFilter: 'blur(14px)', WebkitBackdropFilter: 'blur(14px)',
        fontSize: 16.5, lineHeight: 1.45, fontWeight: 500,
        boxShadow: '0 10px 30px rgba(0,0,0,.25), 0 0 0 1px rgba(255,255,255,.08)',
        textAlign: 'center',
      }}>
        {shown}
        <span style={{ display: 'inline-block', width: 7, height: 18, background: color, marginLeft: 4, transform: 'translateY(3px)', animation: 'ftf-caret 1s steps(2) infinite', borderRadius: 1 }} />
      </div>
    </div>
  );
}

// Big stage where the tutor lives. Stage background uses persona accent.
function TutorStage({ persona, mode, theme, isDesktop, scenario }) {
  const p = PERSONAS[persona] || PERSONAS.maya;
  // mood-driven background tint
  const stageBg = mode === 'listening'
    ? `radial-gradient(120% 80% at 50% 110%, ${p.accent}33, transparent 70%), ${theme.surfaceAlt}`
    : mode === 'speaking'
      ? `radial-gradient(120% 80% at 50% 110%, ${p.accent}55, transparent 70%), ${theme.surfaceAlt}`
      : `radial-gradient(120% 80% at 50% 110%, ${p.accent}22, transparent 70%), ${theme.surfaceAlt}`;

  // Floating ambient orbs in background
  const orbs = [
    { x: 8,  y: 14, size: 64, delay: 0,    color: p.accent + '33' },
    { x: 84, y: 22, size: 48, delay: -2.4, color: p.accent + '22' },
    { x: 14, y: 70, size: 90, delay: -4.8, color: p.accent + '1a' },
    { x: 78, y: 76, size: 56, delay: -1.6, color: p.accent + '22' },
  ];

  return (
    <div style={{
      flex: 1, minHeight: 0, position: 'relative', overflow: 'hidden',
      background: stageBg, transition: 'background .6s ease',
    }}>
      {/* Ambient floating orbs */}
      {orbs.map((o, i) => (
        <div key={i} style={{
          position: 'absolute', left: `${o.x}%`, top: `${o.y}%`,
          width: o.size, height: o.size, borderRadius: '50%',
          background: o.color, filter: 'blur(1px)',
          animation: `ftf-orb-drift 8s ease-in-out ${o.delay}s infinite`,
          pointerEvents: 'none',
        }} />
      ))}

      {/* Top-left scene context pill */}
      <div style={{
        position: 'absolute', top: 14, left: 14, zIndex: 3,
        padding: '7px 12px 7px 8px', borderRadius: 999,
        background: 'rgba(15,18,30,.45)', color: '#fff',
        backdropFilter: 'blur(10px)', WebkitBackdropFilter: 'blur(10px)',
        display: 'flex', alignItems: 'center', gap: 8,
        fontSize: 12, fontWeight: 500,
      }}>
        <span style={{ width: 7, height: 7, borderRadius: 4, background: theme.good, boxShadow: `0 0 0 0 ${theme.good}77`, animation: 'ftf-rec 1.8s ease-out infinite' }} />
        <span style={{ opacity: .9 }}>{(scenario && scenario.title) || 'Free chat'}</span>
      </div>

      {/* Top-right session timer */}
      <div style={{
        position: 'absolute', top: 14, right: 14, zIndex: 3,
        padding: '6px 10px', borderRadius: 8,
        background: 'rgba(15,18,30,.45)', color: '#fff',
        backdropFilter: 'blur(10px)', WebkitBackdropFilter: 'blur(10px)',
        fontFamily: 'JetBrains Mono, monospace', fontSize: 12, letterSpacing: '.04em',
      }}>02:14</div>

      {/* Tutor portrait centered, slightly above middle */}
      <div style={{
        position: 'absolute', left: 0, right: 0, top: '8%', bottom: '20%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        zIndex: 2,
      }}>
        <div style={{
          position: 'relative',
          animation: mode === 'idle' ? 'ftf-body-breathe 4s ease-in-out infinite' : 'none',
        }}>
          {/* Glow halo */}
          <div style={{
            position: 'absolute', inset: -30, borderRadius: '50%',
            background: `radial-gradient(circle, ${p.accent}44 0%, transparent 65%)`,
            filter: 'blur(8px)', zIndex: -1,
            animation: mode === 'speaking' ? 'ftf-halo-pulse 1.4s ease-in-out infinite' : 'none',
          }} />
          <TalkingAvatar persona={persona} mode={mode} size={isDesktop ? 380 : 280} theme={theme} />
        </div>
      </div>

      {/* Greeting wave (only when idle and tutor hasn't spoken yet — purely decorative cue) */}
      {mode === 'idle' && (
        <div style={{
          position: 'absolute', right: '14%', bottom: '30%', zIndex: 2,
          animation: 'ftf-bob 3s ease-in-out infinite',
        }}>
          <WaveHand size={isDesktop ? 92 : 64} color="#f4cba3" />
        </div>
      )}

      {/* Mode badge ribbon (bottom-left) */}
      <div style={{
        position: 'absolute', left: 14, bottom: 14, zIndex: 3,
        padding: '8px 14px', borderRadius: 999,
        background: mode === 'listening' ? theme.bad : (mode === 'speaking' ? p.accent : 'rgba(15,18,30,.5)'),
        color: '#fff', fontSize: 12, fontWeight: 600,
        display: 'flex', alignItems: 'center', gap: 8,
        boxShadow: '0 4px 14px rgba(0,0,0,.18)',
        transition: 'background .3s ease',
      }}>
        {mode === 'listening' && (<><span style={{ display: 'inline-flex', gap: 2 }}>
          {[0,1,2].map(i => <span key={i} style={{ width: 3, height: 12, background: '#fff', borderRadius: 1, animation: `ft-wave .8s ease-in-out ${i*.15}s infinite` }} />)}
        </span> Listening…</>)}
        {mode === 'speaking' && (<><span style={{ width: 8, height: 8, borderRadius: 4, background: '#fff', animation: 'ftf-rec 1s ease-out infinite' }} /> {p.name} is speaking</>)}
        {mode === 'thinking' && (<><span style={{ display: 'flex', gap: 2 }}>{[0,1,2].map(i => <span key={i} style={{ width: 5, height: 5, borderRadius: 3, background: '#fff', animation: `ft-float 1s ease-in-out ${i*.15}s infinite` }} />)}</span> Thinking…</>)}
        {mode === 'idle' && (<><span style={{ width: 7, height: 7, borderRadius: 4, background: theme.good }} /> Live call</>)}
      </div>
    </div>
  );
}

// ── Press-and-hold record button ─────────────────────────────────────
// Hold to record; releasing commits the turn. Animates a growing ring,
// pulsing dot and live waveform bars while held.
function PressToRecord({ theme, accent, isDesktop, mode, onCommit, onEnd }) {
  const [holding, setHolding] = uSf(false);
  const [elapsed, setElapsed] = uSf(0);
  const startRef = uRf(null);
  const rafRef = uRf(null);

  uEf(() => {
    if (!holding) {
      cancelAnimationFrame(rafRef.current);
      return;
    }
    startRef.current = performance.now();
    const tick = (t) => {
      setElapsed((t - startRef.current) / 1000);
      rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
  }, [holding]);

  const start = (e) => { e.preventDefault(); if (mode !== 'idle') return; setHolding(true); setElapsed(0); };
  const stop = (e) => {
    if (!holding) return;
    e && e.preventDefault();
    setHolding(false);
    // Require at least 300ms of hold to count as a take
    if (elapsed >= 0.3) onCommit && onCommit();
    setElapsed(0);
  };

  // Format mm:ss
  const t = elapsed;
  const m = Math.floor(t / 60);
  const s = Math.floor(t % 60);
  const ms = Math.floor((t % 1) * 10);
  const timeStr = `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}.${ms}`;

  const wavebars = 18;
  return (
    <div style={{
      padding: isDesktop ? '14px 24px 22px' : '10px 16px 18px',
      background: theme.bg, borderTop: `1px solid ${theme.border}`,
      flexShrink: 0, position: 'relative',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
    }}>
      {/* Live recording overlay panel */}
      {holding && (
        <div style={{
          position: 'absolute', left: 16, right: 16, bottom: 'calc(100% + 6px)',
          background: 'rgba(15,18,30,.85)', color: '#fff',
          backdropFilter: 'blur(14px)', WebkitBackdropFilter: 'blur(14px)',
          padding: '14px 18px', borderRadius: 16,
          display: 'flex', alignItems: 'center', gap: 14,
          boxShadow: '0 12px 36px rgba(0,0,0,.28)',
          animation: 'ft-slide-up .25s ease both',
          zIndex: 4,
        }}>
          {/* Red rec dot */}
          <span style={{
            width: 10, height: 10, borderRadius: 5, background: '#ff5a4d',
            animation: 'ftf-rec 1s ease-out infinite', flexShrink: 0,
          }} />
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 3, height: 22 }}>
            {Array.from({ length: wavebars }).map((_, i) => {
              const baseH = 4 + (Math.sin(i * 1.7 + elapsed * 6) * 0.5 + 0.5) * 18;
              return <div key={i} style={{
                width: 3, height: baseH, background: accent,
                borderRadius: 2, transition: 'height .08s linear',
              }} />;
            })}
          </div>
          <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 13, fontWeight: 600, color: '#fff', minWidth: 70, textAlign: 'right' }}>{timeStr}</span>
        </div>
      )}

      {/* Button row: end-call · big record · skip turn */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 28, width: '100%' }}>
        {/* End call */}
        <button onClick={onEnd} title="End call" style={{
          width: 46, height: 46, borderRadius: '50%', border: 'none',
          background: theme.bad, color: '#fff', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 6px 16px ${theme.bad}66`,
        }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" style={{ transform: 'rotate(135deg)' }}>
            <path d="M4.5 3.5h2.8l1.2 3-1.6 1.2a9 9 0 0 0 4.4 4.4l1.2-1.6 3 1.2v2.8a1 1 0 0 1-1.1 1A12 12 0 0 1 3.5 4.6a1 1 0 0 1 1-1.1z" stroke="#fff" strokeWidth="1.7" strokeLinejoin="round"/>
          </svg>
        </button>

        {/* Big record */}
        <button
          onMouseDown={start} onMouseUp={stop} onMouseLeave={stop}
          onTouchStart={start} onTouchEnd={stop} onTouchCancel={stop}
          onContextMenu={(e) => e.preventDefault()}
          title="Hold to speak"
          style={{
            width: holding ? 96 : 84, height: holding ? 96 : 84, borderRadius: '50%',
            border: 'none',
            background: holding ? '#ff5a4d' : accent,
            color: '#fff', cursor: holding ? 'grabbing' : (mode === 'idle' ? 'pointer' : 'not-allowed'),
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            position: 'relative',
            boxShadow: holding
              ? `0 0 0 8px ${accent}33, 0 0 0 18px ${accent}1a, 0 18px 40px #ff5a4d99`
              : `0 14px 36px ${accent}77`,
            transition: 'width .2s ease, height .2s ease, background .2s ease, box-shadow .25s ease',
            userSelect: 'none', WebkitUserSelect: 'none', touchAction: 'none',
          }}>
          {/* Outer pulse ring */}
          {holding && (
            <>
              <span style={{
                position: 'absolute', inset: -2, borderRadius: '50%',
                border: `2px solid ${accent}`, opacity: .6,
                animation: 'ft-pulse 1.4s ease-out infinite', pointerEvents: 'none',
              }} />
              <span style={{
                position: 'absolute', inset: -2, borderRadius: '50%',
                border: `2px solid ${accent}`, opacity: .6,
                animation: 'ft-pulse 1.4s ease-out infinite .6s', pointerEvents: 'none',
              }} />
            </>
          )}
          {holding ? (
            // Stop-square icon while holding
            <span style={{ width: 22, height: 22, background: '#fff', borderRadius: 5 }} />
          ) : (
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
              <rect x="9" y="3" width="6" height="11" rx="3" stroke="#fff" strokeWidth="1.9"/>
              <path d="M5 11a7 7 0 0 0 14 0M12 18v3" stroke="#fff" strokeWidth="1.9" strokeLinecap="round"/>
            </svg>
          )}
        </button>

        {/* Skip / Mute (placeholder) */}
        <button title="Mute" style={{
          width: 46, height: 46, borderRadius: '50%', border: `1px solid ${theme.border}`,
          background: theme.surface, color: theme.ink, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M3 9v6h4l5 4V5L7 9H3z" stroke={theme.ink} strokeWidth="1.7" strokeLinejoin="round"/>
            <path d="M16 8a5 5 0 0 1 0 8" stroke={theme.ink} strokeWidth="1.7" strokeLinecap="round"/>
          </svg>
        </button>
      </div>

      {/* Hint label */}
      <div style={{
        fontSize: 11.5, color: holding ? '#ff5a4d' : theme.inkSoft,
        fontFamily: 'JetBrains Mono, monospace', letterSpacing: '.08em',
        transition: 'color .2s ease',
      }}>
        {holding ? 'RELEASE TO SEND' : (mode === 'idle' ? 'HOLD TO SPEAK' : mode.toUpperCase() + '…')}
      </div>
    </div>
  );
}

Object.assign(window, { TutorStage, LiveCaption, WaveHand, PressToRecord });

// All screens for FreeTalk. Each receives { theme, persona, difficulty, feedback, nav, state, setState, layout }.
// layout: 'mobile' | 'desktop' — screens adapt density/typography but keep the same vocabulary.

const { useState: uS, useEffect: uE, useRef: uR, useMemo: uM } = React;

// ── Scenario catalog ─────────────────────────────────────────────────────
const SCENARIOS = [
  { cat: 'travel',  icon: 'plane',     titleKey: 'Airport check-in',     blurbKey: 'Find your gate, handle a flight delay.', mins: 7, tag: 'A2' },
  { cat: 'travel',  icon: 'globe',     titleKey: 'Lost in a new city',   blurbKey: 'Ask for directions, read a map.',         mins: 5, tag: 'A2' },
  { cat: 'travel',  icon: 'coffee',    titleKey: 'Order at a café',     blurbKey: 'Off-menu requests, dietary swaps.',       mins: 6, tag: 'A2' },
  { cat: 'biz',     icon: 'briefcase', titleKey: 'Job interview',        blurbKey: 'Walk me through your resume.',            mins: 12, tag: 'B2' },
  { cat: 'biz',     icon: 'chart',     titleKey: 'Quarterly review',     blurbKey: 'Defend your numbers in a meeting.',       mins: 10, tag: 'C1' },
  { cat: 'biz',     icon: 'bolt',      titleKey: 'Pitch the idea',       blurbKey: 'Sell a product in 60 seconds.',           mins: 4, tag: 'B2' },
  { cat: 'daily',   icon: 'heart',     titleKey: 'First date',           blurbKey: 'Light, fun back-and-forth.',              mins: 8, tag: 'B1' },
  { cat: 'daily',   icon: 'home',      titleKey: 'Renting an apartment', blurbKey: 'Negotiate, ask about utilities.',         mins: 9, tag: 'B1' },
  { cat: 'daily',   icon: 'bell',      titleKey: 'Doctor’s visit',      blurbKey: 'Describe symptoms, follow advice.',       mins: 8, tag: 'B1' },
  { cat: 'school',  icon: 'grad',      titleKey: 'University debate',    blurbKey: 'Defend a position on climate policy.',    mins: 14, tag: 'C1' },
  { cat: 'school',  icon: 'book',      titleKey: 'Discuss a novel',      blurbKey: 'Talk themes, characters, your take.',     mins: 11, tag: 'B2' },
  { cat: 'roleplay',icon: 'sparkle',   titleKey: 'Negotiate a raise',    blurbKey: 'Stay firm, stay friendly.',               mins: 9, tag: 'B2' },
  { cat: 'roleplay',icon: 'flag',      titleKey: 'Refund a bad order',   blurbKey: 'Be assertive without being rude.',        mins: 6, tag: 'B1' },
  { cat: 'free',    icon: 'chat',      titleKey: 'Free chat',            blurbKey: 'Just talk. Anything goes.',               mins: 15, tag: 'any' },
];
// Back-compat: keep .title/.blurb as live getters
SCENARIOS.forEach(s => { Object.defineProperty(s, 'title', { get: () => t(s.titleKey) }); Object.defineProperty(s, 'blurb', { get: () => t(s.blurbKey) }); });

const CATS = [
  { id: 'all',      labelKey: 'All',          icon: 'sparkle' },
  { id: 'travel',   labelKey: 'Travel',       icon: 'plane' },
  { id: 'biz',      labelKey: 'Business',     icon: 'briefcase' },
  { id: 'daily',    labelKey: 'Daily life',   icon: 'home' },
  { id: 'school',   labelKey: 'Academic',     icon: 'grad' },
  { id: 'roleplay', labelKey: 'Roleplay',     icon: 'sparkle' },
  { id: 'free',     labelKey: 'Free chat',    icon: 'chat' },
];
CATS.forEach(c => { Object.defineProperty(c, 'label', { get: () => t(c.labelKey) }); });

// ═════════════════════════════════════════════════════════════════════════
// ONBOARDING — placement test
// ═════════════════════════════════════════════════════════════════════════
function OnboardScreen({ theme, persona, nav, layout, state, setState }) {
  const step = state.onboardStep ?? 0;
  const setStep = (s) => setState({ ...state, onboardStep: s });
  const isDesktop = layout === 'desktop';

  const steps = [
    {
      title: t('Hi! I’m FreeTalk.'),
      sub: t('A patient English tutor that lives in your pocket — and on your desktop.'),
      body: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, alignItems: 'center' }}>
          <div style={{ position: 'relative' }}>
            <Avatar persona={persona} size={isDesktop ? 140 : 110} pulse />
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
            {['Maya','Leo','Sofia','Theo'].map((n, i) => (
              <div key={n} style={{ fontSize: 11, color: theme.inkFaint, animation: `ft-float 3s ease-in-out ${i*.3}s infinite` }}>· {n}</div>
            ))}
          </div>
        </div>
      ),
      cta: t('Continue'),
    },
    {
      title: t('Why are you here?'),
      sub: t('Pick one — you can change this any time.'),
      body: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[
            { id: 'travel',  icon: 'plane',     t: t('Travel & make friends abroad'), s: t('Café orders, small talk, directions.') },
            { id: 'biz',     icon: 'briefcase', t: t('Land a job or promotion'),      s: t('Interviews, meetings, presenting.') },
            { id: 'school',  icon: 'grad',      t: t('Ace exams & uni classes'),      s: t('IELTS, TOEFL, debate, essays.') },
            { id: 'fun',     icon: 'heart',     t: t('Just for fun'),                 s: t('Movies, music, talking to people online.') },
          ].map(opt => (
            <Card key={opt.id} theme={theme} padding={14} hoverable
              onClick={() => setState({ ...state, goal: opt.id, onboardStep: 2 })}
              style={{ display: 'flex', alignItems: 'center', gap: 14, border: state.goal === opt.id ? `1.5px solid ${theme.accent}` : `1px solid ${theme.border}` }}>
              <div style={{ width: 40, height: 40, borderRadius: 10, background: theme.accentSoft, color: theme.accentInk, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name={opt.icon} size={18} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14, color: theme.ink }}>{opt.t}</div>
                <div style={{ fontSize: 12, color: theme.inkSoft, marginTop: 1 }}>{opt.s}</div>
              </div>
              <Icon name="arrow" size={16} stroke={theme.inkFaint} />
            </Card>
          ))}
        </div>
      ),
      noCta: true,
    },
    {
      title: t('Quick voice check'),
      sub: t('Read this aloud so we can place you. Don’t worry — it’s just a sample.'),
      body: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 18, alignItems: 'center' }}>
          <Card theme={theme} padding={18} style={{ width: '100%', textAlign: 'center', background: theme.surfaceAlt }}>
            <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 26 : 21, lineHeight: 1.3, color: theme.ink }}>
              “Yesterday I walked to the park and noticed how the maple leaves had finally turned amber.”
            </div>
          </Card>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
            <button onClick={() => setStep(3)} style={{
              width: 88, height: 88, borderRadius: 44, border: 'none', cursor: 'pointer',
              background: theme.accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: `0 14px 36px ${theme.accent}66`, position: 'relative',
            }}>
              <div style={{ position: 'absolute', inset: 0, borderRadius: 44, background: theme.accent, opacity: .4, animation: 'ft-pulse 1.8s ease-out infinite' }} />
              <Icon name="mic" size={32} stroke="#fff" />
            </button>
            <div style={{ fontSize: 12, color: theme.inkSoft }}>{t('Tap to record')}</div>
          </div>
        </div>
      ),
      noCta: true,
    },
    {
      title: t('You’re at B1 · Intermediate'),
      sub: t('Comfortable with daily life. Ready to push into nuance.'),
      body: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, alignItems: 'center' }}>
          <ScoreRing value={64} size={isDesktop ? 160 : 130} stroke={12} color={theme.accent} track={theme.accentSoft} ink={theme.ink} sub="CEFR B1" />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center', maxWidth: 320 }}>
            {[[t('Fluency'), 72],[t('Grammar'), 58],[t('Vocabulary'), 66],[t('Pronunciation'), 60]].map(([l, v]) => (
              <div key={l} style={{ background: theme.surfaceAlt, padding: '6px 12px', borderRadius: 999, fontSize: 11, color: theme.inkSoft, display: 'flex', alignItems: 'center', gap: 6 }}>
                {l} <strong style={{ color: theme.ink, fontFamily: 'JetBrains Mono, monospace' }}>{v}</strong>
              </div>
            ))}
          </div>
        </div>
      ),
      cta: t('Build my course'),
    },
  ];

  const cur = steps[step];

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, position: 'relative', overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0, background: theme.glow, pointerEvents: 'none' }} />
      <div style={{ position: 'relative', height: '100%', display: 'flex', flexDirection: 'column', padding: isDesktop ? '40px 80px' : '24px 22px' }}>
        {/* progress dots */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 28, justifyContent: 'center' }}>
          {steps.map((_, i) => (
            <div key={i} style={{
              height: 4, width: i === step ? 28 : 14, borderRadius: 2,
              background: i <= step ? theme.accent : theme.border, transition: 'all .3s ease',
            }} />
          ))}
        </div>
        <div className="ft-fade-in" key={step} style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', maxWidth: 520, margin: '0 auto', width: '100%' }}>
          <div style={{ textAlign: 'center', marginBottom: 28 }}>
            <h1 style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 48 : 34, fontWeight: 400, lineHeight: 1.05, margin: 0, letterSpacing: '-0.02em' }}>{cur.title}</h1>
            <p style={{ fontSize: isDesktop ? 16 : 14, color: theme.inkSoft, marginTop: 10, maxWidth: 380, marginLeft: 'auto', marginRight: 'auto', lineHeight: 1.5 }}>{cur.sub}</p>
          </div>
          {cur.body}
        </div>
        <div style={{ marginTop: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
          {step > 0 ? <Button theme={theme} variant="ghost" size="md" onClick={() => setStep(step - 1)}>{t('Back')}</Button> : <span />}
          {!cur.noCta && (
            step === steps.length - 1
              ? <Button theme={theme} size="md" iconRight={<Icon name="arrow" size={16} stroke="#fff" />} onClick={() => nav('home')}>{cur.cta}</Button>
              : <Button theme={theme} size="md" iconRight={<Icon name="arrow" size={16} stroke="#fff" />} onClick={() => setStep(step + 1)}>{cur.cta}</Button>
          )}
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════
// HOME — daily dashboard
// ═════════════════════════════════════════════════════════════════════════
function HomeScreen({ theme, persona, nav, layout, difficulty }) {
  const p = PERSONAS[persona];
  const d = DIFFICULTIES[difficulty];
  const isDesktop = layout === 'desktop';
  const weekDays = ['M','T','W','T','F','S','S'];
  const streak = [1,1,1,1,1,0,0]; // mon-sun
  const today = 4;

  // News notification state
  const [notifOpen, setNotifOpen] = uS(false);
  const [activeNews, setActiveNews] = uS(null); // null = show list, otherwise = detail
  const NEWS = [
    {
      id: 1, badge: 'New',
      title: 'Maya gets new café scenarios',
      preview: 'Order an oat-milk macchiato, ask about the wifi password, and split the bill — three new short scenarios are live today.',
      time: '2h ago',
      body: 'We just shipped three short café scenarios with Maya. Each runs about 4 minutes and focuses on conversational confidence, not vocabulary drills.\n\nWhat\u2019s new:\n• "Order off-menu" — handle the alt-milk surcharge gracefully\n• "Ask for wifi" — small-talk while you wait\n• "Split the bill" — be polite but specific\n\nFind them under Scenarios → Daily life.',
    },
    {
      id: 2, badge: 'Update',
      title: 'Face-to-face mode is now smoother',
      preview: 'We tuned the tutor\u2019s mouth animation and added live captions. Toggle it from any conversation header.',
      time: 'Yesterday',
      body: 'Face-to-face mode now feels more like a real call:\n\n• Lip-sync is tighter when the tutor speaks\n• Closed-caption band at the bottom is typed in character-by-character\n• Persona breathes gently while listening to you\n• Press the call icon in the header to flip into face mode mid-chat',
    },
    {
      id: 3, badge: 'Tip',
      title: '7-day streak unlocks the Café Master badge',
      preview: 'Five more practice sessions and your trophy shelf earns a new sticker. Keep going!',
      time: '2 days ago',
      body: 'Streaks are about consistency, not minutes. Five more daily sessions of any length will unlock the Café Master badge.\n\nThings that count toward streak:\n• Any conversation (chat or face mode) \u2265 90 seconds\n• Completing today\u2019s recommended session\n• Practising a phrase from the Report screen\n\nYou\u2019ve got this.',
    },
    {
      id: 4, badge: 'Community',
      title: 'New leaderboard launches next week',
      preview: 'We\u2019re piloting a weekly speak-time leaderboard for friends. Opt in from Settings → Privacy.',
      time: '4 days ago',
      body: 'Next Monday we\u2019re rolling out friendly weekly leaderboards. Compete on minutes spoken, words spoken, or scenarios completed.\n\n• Opt-in only \u2014 default is off\n• Visible only to people you add as friends\n• Resets every Monday 00:00 local',
    },
  ];

  const NotifModal = () => (
    <div onClick={() => { setNotifOpen(false); setActiveNews(null); }} style={{
      position: 'absolute', inset: 0, zIndex: 50,
      background: 'rgba(15,18,30,.45)', backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
      display: 'flex', alignItems: 'flex-start', justifyContent: 'center',
      padding: isDesktop ? '60px 20px 20px' : '60px 14px 14px',
      animation: 'ft-fade-in .25s ease both',
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        background: theme.surface, color: theme.ink,
        width: '100%', maxWidth: isDesktop ? 480 : '100%',
        borderRadius: 22, overflow: 'hidden',
        boxShadow: '0 24px 60px rgba(0,0,0,.28), 0 0 0 1px ' + theme.border,
        animation: 'ft-pop-in .35s cubic-bezier(.34,1.56,.64,1) both',
        display: 'flex', flexDirection: 'column',
        maxHeight: isDesktop ? 'min(80vh, 640px)' : 'calc(100% - 0px)',
      }}>
        {/* Header */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '14px 14px 14px 16px',
          borderBottom: `1px solid ${theme.border}`,
        }}>
          {activeNews && (
            <button onClick={() => setActiveNews(null)} title="Back" style={{
              width: 32, height: 32, borderRadius: 8, border: 'none',
              background: theme.surfaceAlt, color: theme.ink, cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0,
            }}>
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                <path d="M10 3l-5 5 5 5" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </button>
          )}
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontWeight: 700, fontSize: 15, color: theme.ink, lineHeight: 1.2 }}>
              {activeNews ? 'News' : 'Notifications'}
            </div>
            <div style={{ fontSize: 11.5, color: theme.inkFaint, marginTop: 1 }}>
              {activeNews ? activeNews.time : `${NEWS.length} updates`}
            </div>
          </div>
          <button onClick={() => { setNotifOpen(false); setActiveNews(null); }} title="Close" style={{
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

        {/* Body — list or detail */}
        <div style={{ flex: 1, overflowY: 'auto' }}>
          {!activeNews ? (
            <div>
              {NEWS.map((n, i) => (
                <button key={n.id} onClick={() => setActiveNews(n)} style={{
                  display: 'flex', width: '100%', alignItems: 'flex-start', gap: 12,
                  padding: '14px 16px',
                  border: 'none', borderBottom: i < NEWS.length - 1 ? `1px solid ${theme.border}` : 'none',
                  background: 'transparent', color: theme.ink, cursor: 'pointer',
                  textAlign: 'left', fontFamily: 'inherit',
                  transition: 'background .12s ease',
                }}
                onMouseEnter={e => e.currentTarget.style.background = theme.surfaceAlt}
                onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
                  <div style={{
                    flexShrink: 0, width: 36, height: 36, borderRadius: 10,
                    background: theme.accentSoft, color: theme.accent,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                      <path d="M6 8a6 6 0 0 1 12 0v5l2 3H4l2-3V8z" stroke="currentColor" strokeWidth="1.7" strokeLinejoin="round"/>
                      <path d="M10 19a2 2 0 0 0 4 0" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                      <span style={{
                        fontSize: 9.5, fontWeight: 700, letterSpacing: '.08em', textTransform: 'uppercase',
                        padding: '2px 6px', borderRadius: 4,
                        background: theme.accent, color: '#fff',
                      }}>{n.badge}</span>
                      <span style={{ fontSize: 11, color: theme.inkFaint }}>{n.time}</span>
                    </div>
                    <div style={{ fontSize: 14, fontWeight: 600, color: theme.ink, lineHeight: 1.3, marginBottom: 3 }}>{n.title}</div>
                    <div style={{ fontSize: 12.5, color: theme.inkSoft, lineHeight: 1.4, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{n.preview}</div>
                  </div>
                  <svg width="14" height="14" viewBox="0 0 16 16" fill="none" style={{ flexShrink: 0, marginTop: 12 }}>
                    <path d="M6 3l5 5-5 5" stroke={theme.inkFaint} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </button>
              ))}
            </div>
          ) : (
            <div className="ft-fade-in" style={{ padding: isDesktop ? '20px 22px 24px' : '18px 18px 22px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                <span style={{
                  fontSize: 9.5, fontWeight: 700, letterSpacing: '.08em', textTransform: 'uppercase',
                  padding: '3px 7px', borderRadius: 4,
                  background: theme.accent, color: '#fff',
                }}>{activeNews.badge}</span>
                <span style={{ fontSize: 11.5, color: theme.inkFaint, fontFamily: 'JetBrains Mono, monospace' }}>{activeNews.time}</span>
              </div>
              <h2 className="ft-serif" style={{
                fontFamily: 'Instrument Serif, serif', fontSize: 24, fontWeight: 400,
                lineHeight: 1.2, margin: '0 0 14px', letterSpacing: '-0.01em', color: theme.ink,
              }}>{activeNews.title}</h2>
              <div style={{ fontSize: 14, lineHeight: 1.65, color: theme.inkSoft, whiteSpace: 'pre-line' }}>
                {activeNews.body}
              </div>
              <div style={{ marginTop: 22, display: 'flex', justifyContent: 'flex-start' }}>
                <button onClick={() => setActiveNews(null)} style={{
                  display: 'flex', alignItems: 'center', gap: 6,
                  padding: '9px 14px', borderRadius: 999,
                  border: `1px solid ${theme.border}`, background: theme.surface,
                  color: theme.ink, fontSize: 13, fontWeight: 600, cursor: 'pointer',
                  fontFamily: 'inherit',
                }}>
                  <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
                    <path d="M10 3l-5 5 5 5" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                  Back to news
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, overflow: 'auto', position: 'relative' }}>
      <div style={{ position: 'absolute', inset: 0, background: theme.glow, pointerEvents: 'none', zIndex: 0 }} />
      <div style={{ position: 'relative', padding: isDesktop ? '32px 48px 48px' : '20px 18px 32px', maxWidth: isDesktop ? 920 : '100%', margin: '0 auto' }}>

        {/* Greeting */}
        <div className="ft-fade-in" style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 22, gap: 14 }}>
          <div style={{ minWidth: 0, flex: 1 }}>
            <div style={{ fontSize: 12, color: theme.inkFaint, letterSpacing: '.04em' }}>{t('Tuesday · evening')}</div>
            <h1 style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 44 : 28, margin: '4px 0 0', fontWeight: 400, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
              {t('Hey Jamie.')} <span style={{ fontStyle: 'italic', color: theme.accent, whiteSpace: 'nowrap' }}>{t('Talk to me?')}</span>
            </h1>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0, marginTop: 4 }}>
            <button onClick={() => { setNotifOpen(true); setActiveNews(null); }} title="Notifications" style={{
              position: 'relative',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              width: 38, height: 38, borderRadius: 999,
              border: `1px solid ${theme.border}`, background: theme.surface,
              color: theme.ink, fontFamily: 'inherit',
              cursor: 'pointer', transition: 'all .15s ease', padding: 0,
            }}
            onMouseEnter={e => { e.currentTarget.style.background = theme.surfaceAlt; }}
            onMouseLeave={e => { e.currentTarget.style.background = theme.surface; }}>
              <Icon name="bell" size={18} />
              {/* Unread dot */}
              <span style={{
                position: 'absolute', top: 8, right: 8,
                width: 8, height: 8, borderRadius: 4,
                background: theme.bad, border: `2px solid ${theme.surface}`,
                boxShadow: `0 0 0 0 ${theme.bad}aa`, animation: 'ftf-rec 1.8s ease-out infinite',
              }} />
            </button>
            <button onClick={() => nav('signin')} title="Sign out" style={{
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              width: 38, height: 38, borderRadius: 999,
              border: `1px solid ${theme.border}`, background: theme.surface,
              color: theme.ink, fontFamily: 'inherit',
              cursor: 'pointer', transition: 'all .15s ease', padding: 0,
            }}
            onMouseEnter={e => { e.currentTarget.style.background = theme.bad + '14'; e.currentTarget.style.borderColor = theme.bad + '55'; e.currentTarget.style.color = theme.bad; }}
            onMouseLeave={e => { e.currentTarget.style.background = theme.surface; e.currentTarget.style.borderColor = theme.border; e.currentTarget.style.color = theme.ink; }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M10 17l-5-5 5-5M5 12h11" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </button>
          </div>
        </div>

        {notifOpen && <NotifModal />}

        {/* Hero: Start a conversation */}
        <Card theme={theme} padding={0} style={{
          background: `linear-gradient(135deg, ${theme.accent} 0%, ${theme.accent}cc 100%)`,
          border: 'none', marginBottom: 22, overflow: 'hidden', position: 'relative',
          boxShadow: `0 16px 40px ${theme.accent}33`,
        }}>
          <div className="ft-fade-in" style={{ padding: isDesktop ? '28px 32px' : '22px 22px', display: 'flex', alignItems: 'center', gap: 18, position: 'relative', zIndex: 1 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 11, color: '#fff', opacity: .8, letterSpacing: '.16em', textTransform: 'uppercase', marginBottom: 6 }}>{t('Today’s session')} · {d.cefr}</div>
              <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 32 : 24, color: '#fff', lineHeight: 1.1 }}>{t('Walk me through your morning routine.')}</div>
              <div style={{ fontSize: 13, color: '#fff', opacity: .85, marginTop: 6 }}>~7 {t('min')} · {t('with')} {p.name}</div>
              <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
                <Button theme={theme} variant="soft" size="md" icon={<Icon name="mic" size={16} />} onClick={() => nav('brief')}
                  style={{ background: '#fff', color: theme.accentInk, border: 'none' }}>
                  {t('Start talking')}
                </Button>
                <Button theme={theme} variant="ghost" size="md" style={{ color: '#fff', border: '1px solid rgba(255,255,255,.4)' }} onClick={() => nav('scenarios')}>{t('Pick a topic')}</Button>
              </div>
            </div>
            {isDesktop && <Avatar persona={persona} size={96} pulse ring ringColor="rgba(255,255,255,.5)" />}
          </div>
          {/* Decoration */}
          <div style={{ position: 'absolute', right: -40, top: -40, width: 240, height: 240, borderRadius: '50%', background: 'rgba(255,255,255,.08)' }} />
          <div style={{ position: 'absolute', right: 80, bottom: -60, width: 140, height: 140, borderRadius: '50%', background: 'rgba(255,255,255,.06)' }} />
        </Card>

        {/* My course quick-access card */}
        <Card theme={theme} padding={isDesktop ? 18 : 16} hoverable onClick={() => nav('course')}
          style={{
            display: 'flex', alignItems: 'center', gap: 14, marginBottom: 14,
            background: `linear-gradient(135deg, ${theme.surfaceAlt} 0%, ${theme.surface} 100%)`,
            cursor: 'pointer',
          }}>
          <div style={{
            width: 46, height: 46, borderRadius: 12,
            background: theme.accent + '22', color: theme.accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <Icon name="book" size={22} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.08em', textTransform: 'uppercase' }}>{t('My course')}</div>
            <div style={{ fontWeight: 600, fontSize: 14.5, color: theme.ink, marginTop: 1, lineHeight: 1.3 }}>{t('Continue your course')}</div>
            <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ flex: 1, height: 5, background: theme.accentSoft, borderRadius: 999, overflow: 'hidden' }}>
                <div style={{ width: '42%', height: '100%', background: theme.accent, borderRadius: 999 }} />
              </div>
              <span style={{ fontSize: 11, color: theme.inkSoft, fontFamily: 'JetBrains Mono, monospace' }}>Week 2 · 3/7</span>
            </div>
          </div>
          <Icon name="arrow" size={16} stroke={theme.inkFaint} />
        </Card>

        {/* Streak + stats */}
        <div style={{ display: 'grid', gridTemplateColumns: isDesktop ? '1.4fr 1fr' : '1fr', gap: 14, marginBottom: 22 }}>
          <Card theme={theme} padding={18}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <div>
                <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.08em', textTransform: 'uppercase' }}>{t('Streak')}</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 4, flexWrap: 'wrap' }}>
                  <span style={{ fontFamily: 'Instrument Serif, serif', fontSize: 38, color: theme.ink, lineHeight: 1.1 }}>12</span>
                  <span style={{ fontSize: 12, color: theme.inkSoft }}>{t('days in a row')}</span>
                </div>
              </div>
              <div style={{ width: 44, height: 44, borderRadius: 12, background: theme.accentSoft, color: theme.accent, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="flame" size={22} fill={theme.accent} stroke={theme.accent} />
              </div>
            </div>
            <div style={{ display: 'flex', gap: 6, justifyContent: 'space-between' }}>
              {weekDays.map((d, i) => (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                  <div style={{
                    width: '100%', maxWidth: 36, aspectRatio: '1', borderRadius: 8,
                    background: streak[i] ? theme.accent : theme.surfaceAlt,
                    color: streak[i] ? '#fff' : theme.inkFaint,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    border: i === today ? `2px solid ${theme.accent}` : 'none',
                    fontSize: 13, fontWeight: 600,
                  }}>
                    {streak[i] ? <Icon name="check" size={14} stroke="#fff" /> : ''}
                  </div>
                  <div style={{ fontSize: 10, color: theme.inkFaint }}>{d}</div>
                </div>
              ))}
            </div>
          </Card>

          <Card theme={theme} padding={18}>
            <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.08em', textTransform: 'uppercase', marginBottom: 10 }}>{t('This week')}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                <span style={{ fontSize: 13, color: theme.inkSoft }}>{t('Speak time')}</span>
                <span style={{ fontFamily: 'JetBrains Mono, monospace', color: theme.ink }}>1h 42m</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                <span style={{ fontSize: 13, color: theme.inkSoft }}>{t('Words spoken')}</span>
                <span style={{ fontFamily: 'JetBrains Mono, monospace', color: theme.ink }}>4,238</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                <span style={{ fontSize: 13, color: theme.inkSoft }}>{t('New phrases')}</span>
                <span style={{ fontFamily: 'JetBrains Mono, monospace', color: theme.ink }}>+27</span>
              </div>
            </div>
          </Card>
        </div>

        {/* Recommended */}
        <SectionHead theme={theme} kicker={t('Recommended')} title={t('Pick where you left off')}
          action={<Button theme={theme} variant="ghost" size="sm" onClick={() => nav('scenarios')} iconRight={<Icon name="arrow" size={14} />}>{t('All scenarios')}</Button>} />
        <div style={{ display: 'grid', gridTemplateColumns: isDesktop ? 'repeat(3, 1fr)' : '1fr 1fr', gap: 12 }}>
          {SCENARIOS.slice(0, isDesktop ? 6 : 4).map((s, i) => (
            <Card key={s.title} theme={theme} padding={14} hoverable onClick={() => nav('brief', { scenario: s })}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: theme.accentSoft, color: theme.accent, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Icon name={s.icon} size={18} />
                </div>
                <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 10, color: theme.inkFaint, padding: '2px 6px', border: `1px solid ${theme.border}`, borderRadius: 4 }}>{s.tag}</div>
              </div>
              <div style={{ fontWeight: 600, fontSize: 14, color: theme.ink }}>{s.title}</div>
              <div style={{ fontSize: 12, color: theme.inkSoft, marginTop: 2, lineHeight: 1.4 }}>{s.blurb}</div>
              <div style={{ fontSize: 11, color: theme.inkFaint, marginTop: 10 }}>~{s.mins} {t('min')}</div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════
// SCENARIOS — topic & scenario picker
// ═════════════════════════════════════════════════════════════════════════
function ScenarioScreen({ theme, nav, layout }) {
  const [cat, setCat] = uS('all');
  const [q, setQ] = uS('');
  const isDesktop = layout === 'desktop';
  const filtered = SCENARIOS.filter(s => (cat === 'all' || s.cat === cat) && s.title.toLowerCase().includes(q.toLowerCase()));

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, overflow: 'auto' }}>
      <div style={{ padding: isDesktop ? '32px 48px 48px' : '20px 18px 32px', maxWidth: isDesktop ? 920 : '100%', margin: '0 auto' }}>
        <h1 style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 40 : 28, fontWeight: 400, margin: '0 0 6px', letterSpacing: '-0.02em' }}>{t('What do you want to')} <span style={{ fontStyle: 'italic', color: theme.accent }}>{t('practice')}</span>?</h1>
        <p style={{ color: theme.inkSoft, fontSize: 13, margin: '0 0 18px' }}>{t('Pick a scenario or just start talking — your tutor will improvise.')}</p>

        {/* Search */}
        <div style={{ position: 'relative', marginBottom: 14 }}>
          <Icon name="search" size={16} stroke={theme.inkFaint} />
          <div style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)' }}>
            <Icon name="search" size={16} stroke={theme.inkFaint} />
          </div>
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={t('Search scenarios…')} style={{
            width: '100%', padding: '12px 14px 12px 40px', fontSize: 13, fontFamily: 'inherit',
            border: `1px solid ${theme.border}`, borderRadius: 12, background: theme.surface, color: theme.ink, outline: 'none',
          }} />
        </div>

        {/* Categories */}
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4, marginBottom: 18, scrollbarWidth: 'none' }}>
          {CATS.map(c => (
            <Chip key={c.id} theme={theme} active={cat === c.id} onClick={() => setCat(c.id)} icon={<Icon name={c.icon} size={13} />}>{c.label}</Chip>
          ))}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: isDesktop ? 'repeat(3, 1fr)' : '1fr', gap: 12 }}>
          {filtered.map((s, i) => (
            <Card key={s.title} theme={theme} padding={16} hoverable onClick={() => nav('brief', { scenario: s })} style={{ animation: `ft-fade-in .4s both ${i * 0.04}s` }}>
              <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
                <div style={{ width: 44, height: 44, borderRadius: 12, background: theme.accentSoft, color: theme.accent, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Icon name={s.icon} size={20} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 6 }}>
                    <div style={{ fontWeight: 600, fontSize: 14, color: theme.ink }}>{s.title}</div>
                    <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 10, color: theme.inkFaint }}>{s.tag}</div>
                  </div>
                  <div style={{ fontSize: 12.5, color: theme.inkSoft, marginTop: 4, lineHeight: 1.45 }}>{s.blurb}</div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 10 }}>
                    <div style={{ fontSize: 11, color: theme.inkFaint }}>~{s.mins} {t('min')}</div>
                    <Icon name="arrow" size={14} stroke={theme.accent} />
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════
// CONVERSATION — live talk with tutor
// ═════════════════════════════════════════════════════════════════════════
function ConvoScreen({ theme, persona, feedback, nav, layout, state, setState, tweaks }) {
  const p = PERSONAS[persona];
  const isDesktop = layout === 'desktop';
  const scenario = state.scenario || SCENARIOS[6];
  const [turn, setTurn] = uS(0);
  const [mode, setMode] = uS('idle');
  // chat | face — toggleable on the header
  const [convoMode, setConvoMode] = uS(state.convoMode || 'chat');
  const scrollerRef = uR(null);

  // Mock transcript: tutor & user with timestamps, optional voice, optional tip
  const turns = [
    { who: 'tutor', text: 'Hi Alex! 👋 Ready to practice English today? Let\u2019s chat about your weekend.', time: '10:24 AM' },
    { who: 'me',    text: 'Hi ' + p.name + '! I went hiking with my friends on Saturday.', time: '10:25 AM' },
    { who: 'tutor', text: 'That sounds wonderful! Where did you go hiking? Tell me more about the experience.', time: '10:25 AM', voice: { dur: '0:08' } },
    { who: 'me',    text: 'We went to Mount Tamalpais. The view was amazing!', time: '10:26 AM',
      tip: { from: p.name, text: 'Try: "The view was breathtaking!" \u2014 more natural' } },
  ];

  uE(() => {
    if (scrollerRef.current) scrollerRef.current.scrollTop = scrollerRef.current.scrollHeight;
  }, [turn, mode]);

  const advance = () => {
    if (turn >= turns.length - 1) { nav('report'); return; }
    setMode('thinking');
    setTimeout(() => { setMode('idle'); setTurn(x => Math.min(x + 1, turns.length - 1)); }, 1400);
  };

  // Tutor accent palette (kept blue-ish to match the reference)
  const tutorBlue = persona === 'maya' ? theme.accent : '#3B7BFF';
  const meBubble = tutorBlue;
  const tipBg = theme.warn + '22';
  const tipBorder = theme.warn + '66';
  const tipInk = theme.warn;

  const PersonaChip = ({ size = 36 }) => {
    const initials = (p.name || 'EM').slice(0, 2).toUpperCase();
    return (
      <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
        <div style={{
          width: size, height: size, borderRadius: '50%', background: tutorBlue,
          color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontWeight: 700, fontSize: size * 0.36, letterSpacing: '-.02em',
        }}>{initials}</div>
        <div style={{
          position: 'absolute', right: -1, bottom: -1, width: size * 0.28, height: size * 0.28,
          borderRadius: '50%', background: theme.good, border: `2px solid ${theme.bg}`,
        }} />
      </div>
    );
  };

  const DoubleCheck = ({ color }) => (
    <svg width="14" height="10" viewBox="0 0 14 10" fill="none">
      <path d="M1 5.5l2.5 2.5L8.5 3" stroke={color} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M5 5.5l2.5 2.5L13 3" stroke={color} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );

  const VoiceBubble = ({ dur }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      background: theme.surface, border: `1px solid ${theme.border}`,
      padding: '12px 16px', borderRadius: 18, marginTop: 8, maxWidth: 320,
      boxShadow: '0 1px 2px rgba(0,0,0,.04)',
    }}>
      <button style={{
        width: 38, height: 38, borderRadius: '50%',
        background: tutorBlue + '22', border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="14" height="14" viewBox="0 0 14 14" fill={tutorBlue}>
          <path d="M3 1.5v11l9-5.5z" />
        </svg>
      </button>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 2, height: 24 }}>
        {Array.from({ length: 22 }).map((_, i) => {
          const h = 4 + Math.abs(Math.sin(i * 1.3)) * 18;
          return <div key={i} style={{ width: 3, height: h, background: tutorBlue, opacity: 0.45 + (i % 3) * 0.18, borderRadius: 2 }} />;
        })}
      </div>
      <div style={{ fontSize: 13, color: theme.inkSoft, fontVariantNumeric: 'tabular-nums' }}>{dur}</div>
    </div>
  );

  const TipCard = ({ from, text }) => (
    <div style={{
      background: tipBg, border: `1px solid ${tipBorder}`,
      borderRadius: 16, padding: '12px 14px', marginTop: 8,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
          <path d="M8 1.5a4.5 4.5 0 0 0-3 7.85V11a1 1 0 0 0 1 1h4a1 1 0 0 0 1-1V9.35A4.5 4.5 0 0 0 8 1.5z" stroke={tipInk} strokeWidth="1.4" strokeLinejoin="round" />
          <path d="M6 13.5h4M6.5 15h3" stroke={tipInk} strokeWidth="1.4" strokeLinecap="round" />
        </svg>
        <span style={{ fontWeight: 700, fontSize: 13, color: tipInk }}>Tip from {from}</span>
      </div>
      <div style={{ fontSize: 13.5, color: tipInk, lineHeight: 1.45, paddingLeft: 24 }}>{text}</div>
    </div>
  );

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, display: 'flex', flexDirection: 'column', position: 'relative' }}>
      {/* Header */}
      <div style={{
        padding: isDesktop ? '14px 24px' : '12px 14px',
        display: 'flex', alignItems: 'center', gap: 12,
        borderBottom: `1px solid ${theme.border}`, background: theme.surface,
        zIndex: 3, flexShrink: 0,
      }}>
        <button onClick={() => nav('home')} style={{
          width: 36, height: 36, borderRadius: 8, border: 'none',
          background: 'transparent', color: theme.ink, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
            <path d="M12.5 4l-6 6 6 6" stroke={theme.ink} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
        <PersonaChip size={42} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 700, fontSize: 16, color: theme.ink, lineHeight: 1.1 }}>{p.name}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 2, fontSize: 12.5, color: tutorBlue }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill={tutorBlue}>
              <path d="M7 1l1.2 3.4L11.6 5l-2.7 2 1 3.5L7 8.7 4.1 10.5l1-3.5L2.4 5l3.4-.6L7 1z" />
            </svg>
            <span>AI Tutor</span>
            <span style={{ color: theme.inkSoft }}>· Online</span>
          </div>
        </div>
        {/* Mode toggle: chat ⇄ face */}
        <div style={{
          display: 'flex', background: theme.surfaceAlt, borderRadius: 999, padding: 3,
          marginLeft: 4, flexShrink: 0,
        }} title="Switch mode">
          {[
            { id: 'chat', icon: (c) => (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M21 12a8 8 0 0 1-11.7 7.1L4 20l1-4.2A8 8 0 1 1 21 12z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/></svg>
            ) },
            { id: 'face', icon: (c) => (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="9" r="4" stroke={c} strokeWidth="1.7"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6" stroke={c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/></svg>
            ) },
          ].map(o => {
            const active = convoMode === o.id;
            return (
              <button key={o.id} onClick={() => setConvoMode(o.id)} title={o.id === 'chat' ? 'Chat mode' : 'Face-to-face'} style={{
                width: 32, height: 28, borderRadius: 999, border: 'none', cursor: 'pointer',
                background: active ? theme.surface : 'transparent',
                color: active ? tutorBlue : theme.inkSoft,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: active ? '0 1px 4px rgba(0,0,0,.1)' : 'none',
                transition: 'all .18s ease',
              }}>
                {o.icon(active ? tutorBlue : theme.inkSoft)}
              </button>
            );
          })}
        </div>
        <button title="More" onClick={() => nav('report')} style={{ width: 36, height: 36, borderRadius: 8, border: 'none', background: 'transparent', cursor: 'pointer', color: theme.ink, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="4" height="18" viewBox="0 0 4 18">
            <circle cx="2" cy="3" r="1.6" fill={theme.ink} />
            <circle cx="2" cy="9" r="1.6" fill={theme.ink} />
            <circle cx="2" cy="15" r="1.6" fill={theme.ink} />
          </svg>
        </button>
      </div>

      {/* Body switches between chat transcript and face-to-face stage */}
      {convoMode === 'face' ? (
        <div style={{ flex: 1, minHeight: 0, position: 'relative', display: 'flex', flexDirection: 'column', animation: 'ftf-mode-fade .35s ease both' }}>
          {/* Character stage — fills remaining space, never shrinks below stage minHeight */}
          <div style={{ flex: 1, minHeight: 0, position: 'relative', display: 'flex' }}>
            <TutorStage persona={persona} mode={mode} theme={theme} isDesktop={isDesktop} scenario={scenario} />
          </div>

          {/* Recent transcript — fixed-height area, 2 slots; bubbles slide in & push older content out */}
          {(() => {
            const visible = turns.slice(0, turn + 1);
            const lastTutor = [...visible].reverse().find(x => x.who === 'tutor');
            const lastMe = [...visible].reverse().find(x => x.who === 'me');
            const Slot = ({ side, msg }) => (
              <div style={{
                height: 56,
                display: 'flex', alignItems: 'center',
                justifyContent: side === 'me' ? 'flex-end' : 'flex-start',
                overflow: 'hidden',
              }}>
                {msg && (
                  <div key={msg.text} style={{
                    maxWidth: '82%', padding: '9px 14px', borderRadius: 16,
                    background: side === 'me' ? p.accent : theme.surface,
                    color: side === 'me' ? '#fff' : theme.ink,
                    border: side === 'me' ? 'none' : `1px solid ${theme.border}`,
                    fontSize: 13, lineHeight: 1.4,
                    boxShadow: side === 'me' ? `0 4px 14px ${p.accent}33` : '0 1px 2px rgba(0,0,0,.04)',
                    animation: 'ft-slide-up .35s cubic-bezier(.22,.61,.36,1) both',
                    overflow: 'hidden', display: '-webkit-box',
                    WebkitLineClamp: 2, WebkitBoxOrient: 'vertical',
                  }}>
                    <div style={{ fontSize: 9.5, opacity: .65, marginBottom: 2, letterSpacing: '.08em', textTransform: 'uppercase', fontWeight: 700 }}>
                      {side === 'me' ? 'You' : p.name}
                    </div>
                    {msg.text}
                  </div>
                )}
              </div>
            );
            return (
              <div style={{
                flexShrink: 0,
                padding: isDesktop ? '10px 28px' : '8px 16px',
                background: theme.bg, borderTop: `1px solid ${theme.border}`,
                display: 'flex', flexDirection: 'column', gap: 6,
                height: 132, boxSizing: 'border-box',
              }}>
                <Slot side="tutor" msg={lastTutor} />
                <Slot side="me" msg={lastMe} />
              </div>
            );
          })()}

          {/* Press-and-hold record button */}
          <PressToRecord
            theme={theme} accent={p.accent}
            isDesktop={isDesktop}
            mode={mode}
            onCommit={advance}
            onEnd={() => nav('report')}
          />
        </div>
      ) : (
      <>

      {/* Transcript */}
      <div ref={scrollerRef} style={{ flex: 1, overflowY: 'auto', padding: isDesktop ? '20px 28px' : '16px 14px', background: theme.bg }}>
        <div style={{ maxWidth: 640, margin: '0 auto', display: 'flex', flexDirection: 'column' }}>

          {/* Date pill */}
          <div className="ft-fade-in" style={{ display: 'flex', justifyContent: 'center', marginBottom: 18 }}>
            <div style={{
              padding: '6px 16px', borderRadius: 999,
              background: theme.surfaceAlt, color: theme.inkSoft,
              fontSize: 12.5, fontWeight: 500,
            }}>Today, 10:24 AM</div>
          </div>

          {turns.slice(0, turn + 1).map((m, i) => {
            const mine = m.who === 'me';
            return (
              <div key={i} className="ft-fade-in" style={{ display: 'flex', flexDirection: 'column', alignItems: mine ? 'flex-end' : 'flex-start', marginBottom: 18, animationDelay: i === turn ? '.1s' : '0s' }}>
                <div style={{
                  background: mine ? meBubble : theme.surface,
                  color: mine ? '#fff' : theme.ink,
                  border: mine ? 'none' : `1px solid ${theme.border}`,
                  padding: '14px 18px', borderRadius: 22,
                  fontSize: 15, lineHeight: 1.5,
                  maxWidth: '82%',
                  boxShadow: mine ? `0 4px 14px ${meBubble}33` : '0 1px 2px rgba(0,0,0,.04)',
                }}>{m.text}</div>

                {m.voice && <VoiceBubble dur={m.voice.dur} />}

                {!mine && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 8 }}>
                    <PersonaChip size={28} />
                    <span style={{ fontSize: 12, color: theme.inkSoft }}>{m.time}</span>
                  </div>
                )}
                {mine && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 6 }}>
                    <span style={{ fontSize: 12, color: theme.inkSoft }}>{m.time}</span>
                    <DoubleCheck color={meBubble} />
                  </div>
                )}

                {m.tip && (
                  <div style={{ width: '100%' }}>
                    <TipCard from={m.tip.from} text={m.tip.text} />
                  </div>
                )}
              </div>
            );
          })}

          {/* Typing indicator */}
          {(mode === 'thinking' || turn < turns.length - 1) && mode !== 'thinking' ? null : null}
          {mode === 'thinking' && (
            <div className="ft-fade-in" style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
              <PersonaChip size={28} />
              <div style={{
                background: theme.surface, border: `1px solid ${theme.border}`,
                padding: '12px 18px', borderRadius: 22,
                display: 'flex', gap: 5,
              }}>
                {[0, 1, 2].map(i => (
                  <div key={i} style={{ width: 6, height: 6, borderRadius: 3, background: theme.inkFaint, animation: `ft-float 1s ease-in-out ${i * .15}s infinite` }} />
                ))}
              </div>
            </div>
          )}

          {/* Last-message typing placeholder (matches reference) */}
          {mode === 'idle' && turn === turns.length - 1 && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
              <PersonaChip size={28} />
              <div style={{
                background: theme.surface, border: `1px solid ${theme.border}`,
                padding: '10px 18px', borderRadius: 22,
                display: 'flex', gap: 4,
              }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: theme.inkFaint }} />
                <div style={{ width: 4, height: 4, borderRadius: 2, background: theme.inkFaint }} />
                <div style={{ width: 4, height: 4, borderRadius: 2, background: theme.inkFaint }} />
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Quick-reply chips */}
      <div style={{
        padding: isDesktop ? '6px 28px 10px' : '6px 14px 10px',
        display: 'flex', gap: 8, overflowX: 'auto', flexShrink: 0,
        background: theme.bg, borderTop: `1px solid ${theme.border}`,
      }}>
        {[
          { icon: '✨', text: 'Suggest reply' },
          { text: 'It was sunny' },
          { text: 'About 3 hours' },
        ].map((q, i) => (
          <button key={i} onClick={advance} style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '9px 16px', borderRadius: 999,
            border: `1px solid ${theme.border}`, background: theme.surface,
            color: theme.ink, fontSize: 13.5, fontWeight: 500,
            cursor: 'pointer', whiteSpace: 'nowrap', flexShrink: 0,
            transition: 'background .15s ease',
          }}
          onMouseEnter={e => e.currentTarget.style.background = theme.surfaceAlt}
          onMouseLeave={e => e.currentTarget.style.background = theme.surface}>
            {q.icon && <span style={{ color: tutorBlue }}>{q.icon}</span>}
            {q.text}
          </button>
        ))}
      </div>

      {/* Input bar */}
      <div style={{
        padding: isDesktop ? '10px 24px 16px' : '10px 14px 14px',
        display: 'flex', alignItems: 'center', gap: 10,
        background: theme.surface, borderTop: `1px solid ${theme.border}`,
        flexShrink: 0,
      }}>
        <button title="Attach" style={{ width: 38, height: 38, borderRadius: '50%', border: 'none', background: 'transparent', cursor: 'pointer', color: theme.inkSoft, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
            <path d="M11 4v14M4 11h14" stroke={theme.inkSoft} strokeWidth="2" strokeLinecap="round" />
          </svg>
        </button>
        <div style={{
          flex: 1, display: 'flex', alignItems: 'center', gap: 8,
          background: theme.surfaceAlt, borderRadius: 999, padding: '0 14px',
          height: 44,
        }}>
          <input
            placeholder="Type a message..."
            style={{
              flex: 1, border: 'none', outline: 'none', background: 'transparent',
              fontSize: 14.5, color: theme.ink, fontFamily: 'inherit',
            }}
          />
          <button title="Emoji" style={{ width: 28, height: 28, borderRadius: '50%', border: 'none', background: 'transparent', cursor: 'pointer', color: theme.inkSoft, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0 }}>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
              <circle cx="10" cy="10" r="8" stroke={theme.inkSoft} strokeWidth="1.6" />
              <circle cx="7.3" cy="8.5" r=".9" fill={theme.inkSoft} />
              <circle cx="12.7" cy="8.5" r=".9" fill={theme.inkSoft} />
              <path d="M7 12.5c.8 1 1.8 1.5 3 1.5s2.2-.5 3-1.5" stroke={theme.inkSoft} strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          </button>
        </div>
        <button onClick={advance} title="Speak" style={{
          width: 44, height: 44, borderRadius: '50%',
          background: meBubble, border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#fff', flexShrink: 0,
          boxShadow: `0 4px 12px ${meBubble}55`,
        }}>
          <Icon name="mic" size={20} stroke="#fff" />
        </button>
      </div>
      </>
      )}
    </div>
  );
}

Object.assign(window, { OnboardScreen, HomeScreen, ScenarioScreen, ConvoScreen, SCENARIOS, CATS });

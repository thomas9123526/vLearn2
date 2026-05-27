// FreeTalk app shell — nav, frames, canvas wiring, tweaks.

const { useState: uSa, useEffect: uEa, useMemo: uMa, useRef: uRa } = React;

// ── Windows-style desktop window chrome ─────────────────────────────────
function DesktopWindow({ children, theme, width = 1120, height = 720 }) {
  return (
    <div style={{
      width, height, borderRadius: 12, overflow: 'hidden',
      background: theme.surface, color: theme.ink,
      border: `1px solid ${theme.border}`,
      boxShadow: '0 30px 80px rgba(0,0,0,.22), 0 1px 0 rgba(255,255,255,.6) inset',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Title bar — Windows 11 style */}
      <div style={{
        height: 38, background: theme.surface, color: theme.ink,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        paddingLeft: 14, borderBottom: `1px solid ${theme.border}`, flexShrink: 0,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 18, height: 18, borderRadius: 5, background: theme.accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Instrument Serif, serif', fontSize: 13 }}>F</div>
          <div style={{ fontSize: 12, fontWeight: 500, color: theme.inkSoft, letterSpacing: '.01em' }}>FreeTalk · Speak English with confidence</div>
        </div>
        <div style={{ display: 'flex' }}>
          {['min', 'max', 'x'].map((b) => (
            <div key={b} style={{
              width: 46, height: 38, display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: theme.inkSoft, fontSize: 10, cursor: 'default',
            }}>
              {b === 'min' && <div style={{ width: 10, height: 1, background: theme.inkSoft }} />}
              {b === 'max' && <div style={{ width: 10, height: 10, border: `1px solid ${theme.inkSoft}` }} />}
              {b === 'x' && <svg width="10" height="10" viewBox="0 0 10 10" stroke={theme.inkSoft} strokeWidth="1"><path d="M1 1L9 9M9 1L1 9"/></svg>}
            </div>
          ))}
        </div>
      </div>
      {/* Body */}
      <div style={{ flex: 1, minHeight: 0, display: 'flex' }}>
        {children}
      </div>
    </div>
  );
}

// ── Desktop sidebar nav ─────────────────────────────────────────────────
function Sidebar({ screen, nav, theme, persona }) {
  const items = [
    { id: 'home',      label: t('Home'),      icon: 'home' },
    { id: 'scenarios', label: t('Scenarios'), icon: 'sparkle' },
    { id: 'course',    label: t('My course'), icon: 'book' },
    { id: 'progress',  label: t('Progress'),  icon: 'chart' },
    { id: 'settings',  label: t('Settings'),  icon: 'cog' },
  ];
  return (
    <div style={{
      width: 220, background: theme.bg, borderRight: `1px solid ${theme.border}`,
      display: 'flex', flexDirection: 'column', padding: '18px 12px',
      flexShrink: 0,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 8px 16px' }}>
        <div style={{ width: 28, height: 28, borderRadius: 8, background: theme.accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Instrument Serif, serif', fontSize: 18 }}>F</div>
        <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 20, color: theme.ink, letterSpacing: '-0.01em' }}>FreeTalk</div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {items.map(it => {
          const active = screen === it.id;
          return (
            <button key={it.id} onClick={() => nav(it.id)} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '9px 12px', borderRadius: 10, border: 'none',
              background: active ? theme.accent : 'transparent',
              color: active ? '#fff' : theme.inkSoft,
              cursor: 'pointer', fontSize: 13, fontWeight: 500, textAlign: 'left',
              transition: 'all .15s ease', fontFamily: 'inherit',
            }}
            onMouseEnter={(e) => { if (!active) e.currentTarget.style.background = theme.surfaceAlt; }}
            onMouseLeave={(e) => { if (!active) e.currentTarget.style.background = 'transparent'; }}>
              <Icon name={it.icon} size={16} stroke={active ? '#fff' : theme.inkSoft} />
              {it.label}
            </button>
          );
        })}
      </div>
      {/* Big talk button */}
      <button onClick={() => nav('convo')} style={{
        marginTop: 14, padding: '11px 14px', borderRadius: 12, border: 'none',
        background: `linear-gradient(135deg, ${theme.accent}, ${theme.accent}cc)`,
        color: '#fff', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 10, fontWeight: 600, fontSize: 13,
        boxShadow: `0 8px 20px ${theme.accent}44`,
      }}>
        <Icon name="mic" size={16} stroke="#fff" />
        Quick talk
      </button>

      <div style={{ flex: 1 }} />
      <div style={{ padding: '10px 8px', borderTop: `1px solid ${theme.border}`, display: 'flex', alignItems: 'center', gap: 10 }}>
        <Avatar persona={persona} size={32} />
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 12.5, fontWeight: 600, color: theme.ink, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Jamie Chen</div>
          <div style={{ fontSize: 10, color: theme.inkFaint, fontFamily: 'JetBrains Mono, monospace' }}>B1 · 12🔥</div>
        </div>
      </div>
    </div>
  );
}

// ── Mobile bottom nav ───────────────────────────────────────────────────
function MobileTabs({ screen, nav, theme }) {
  const items = [
    { id: 'home',      label: 'Home',     icon: 'home' },
    { id: 'scenarios', label: 'Topics',   icon: 'sparkle' },
    { id: 'progress',  label: 'Progress', icon: 'chart' },
    { id: 'settings',  label: 'You',      icon: 'user' },
  ];
  return (
    <div style={{
      display: 'flex', background: theme.surface, borderTop: `1px solid ${theme.border}`,
      padding: '6px 4px 4px', flexShrink: 0, justifyContent: 'space-around', position: 'relative',
    }}>
      {items.map(it => {
        const active = screen === it.id;
        return (
          <button key={it.id} onClick={() => nav(it.id)} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '6px 12px', color: active ? theme.accent : theme.inkFaint, fontFamily: 'inherit',
          }}>
            <Icon name={it.icon} size={20} stroke={active ? theme.accent : theme.inkFaint} />
            <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '.02em' }}>{it.label}</div>
          </button>
        );
      })}
    </div>
  );
}

// ── Screen router ───────────────────────────────────────────────────────
function ScreenRouter({ ctx, layout, tweaks, setTweak }) {
  const { screen, navTo, navState, setNavState, persona, difficulty, feedback } = ctx;
  const theme = THEMES[tweaks.theme] || THEMES.sunrise;

  const props = { theme, persona, difficulty, feedback, nav: navTo, layout, state: navState, setState: setNavState, tweaks, setTweak };

  return (
    <div data-screen-label={`Mobile · ${screen}`} style={{ flex: 1, minHeight: 0, position: 'relative', overflow: 'hidden' }}>
      <div key={screen} className="ft-fade-in" style={{ position: 'absolute', inset: 0 }}>
        {screen === 'splash'    && <SplashScreen    {...props} />}
        {screen === 'signin'    && <SigninScreen    {...props} />}
        {screen === 'signup'    && <SignupScreen    {...props} />}
        {screen === 'onboard'   && <OnboardScreen   {...props} />}
        {screen === 'home'      && <HomeScreen      {...props} />}
        {screen === 'scenarios' && <ScenarioScreen  {...props} />}
        {screen === 'brief'     && <ScenarioDetailScreen {...props} />}
        {screen === 'convo'     && <ConvoScreen     {...props} />}
        {screen === 'report'    && <ReportScreen    {...props} />}
        {screen === 'progress'  && <ProgressScreen  {...props} />}
        {screen === 'course'    && <CourseScreen    {...props} />}
        {screen === 'settings'  && <SettingsScreen  {...props} />}
      </div>
    </div>
  );
}

// ── Mobile shell (inside Android frame) ─────────────────────────────────
function MobileShell({ ctx, tweaks, setTweak }) {
  const theme = THEMES[tweaks.theme] || THEMES.sunrise;
  const hideTabs = ctx.screen === 'onboard' || ctx.screen === 'convo' || ctx.screen === 'splash' || ctx.screen === 'brief' || ctx.screen === 'signin' || ctx.screen === 'signup';
  return (
    <div data-screen-label="Mobile shell" style={{ width: '100%', height: '100%', background: theme.bg, color: theme.ink, display: 'flex', flexDirection: 'column' }}>
      <ScreenRouter ctx={ctx} layout="mobile" tweaks={tweaks} setTweak={setTweak} />
      {!hideTabs && <MobileTabs screen={ctx.screen} nav={ctx.navTo} theme={theme} />}
    </div>
  );
}

// ── Desktop shell ────────────────────────────────────────────────────────
function DesktopShell({ ctx, tweaks, setTweak }) {
  const theme = THEMES[tweaks.theme] || THEMES.sunrise;
  const showSidebar = ctx.screen !== 'onboard' && ctx.screen !== 'convo' && ctx.screen !== 'splash' && ctx.screen !== 'brief' && ctx.screen !== 'signin' && ctx.screen !== 'signup';
  return (
    <div data-screen-label="Desktop shell" style={{ width: '100%', height: '100%', background: theme.bg, color: theme.ink, display: 'flex' }}>
      {showSidebar && <Sidebar screen={ctx.screen} nav={ctx.navTo} theme={theme} persona={ctx.persona} />}
      <ScreenRouter ctx={ctx} layout="desktop" tweaks={tweaks} setTweak={setTweak} />
    </div>
  );
}

// ── Root: shared nav state across both frames ────────────────────────────
function FreeTalkRoot() {
  const [tweaks, setTweak] = useTweaks(window.TWEAK_DEFAULTS);
  const [screen, setScreen] = uSa('splash');
  const [navState, setNavState] = uSa({});
  const theme = THEMES[tweaks.theme] || THEMES.sunrise;

  // Wire window.__lang from tweaks so t() picks up the language live.
  window.__lang = tweaks.lang || 'en';
  uEa(() => {
    document.documentElement.lang = tweaks.lang || 'en';
  }, [tweaks.lang]);

  const navTo = (s, patch) => {
    if (patch) setNavState((x) => ({ ...x, ...patch }));
    setScreen(s);
  };

  const ctx = { screen, navTo, navState, setNavState, persona: tweaks.persona, difficulty: tweaks.difficulty, feedback: tweaks.feedback };

  return (
    <>
      <DesignCanvas>
        <DCSection id="prototypes" title="FreeTalk" subtitle="An English speaking app — Android + Windows desktop · drag headers to reorder · click any to focus">
          {tweaks.showMobile && (
            <DCArtboard id="mobile" label="Android · mobile" width={412} height={892}>
              <AndroidDevice width={412} height={892}>
                <MobileShell ctx={ctx} tweaks={tweaks} setTweak={setTweak} />
              </AndroidDevice>
            </DCArtboard>
          )}
          {tweaks.showDesktop && (
            <DCArtboard id="desktop" label="Windows · desktop" width={1120} height={720}>
              <DesktopWindow theme={theme} width={1120} height={720}>
                <DesktopShell ctx={ctx} tweaks={tweaks} setTweak={setTweak} />
              </DesktopWindow>
            </DCArtboard>
          )}
        </DCSection>

        <DCSection id="entry" title="First-run · onboarding" subtitle="Placement test before reaching home">
          <DCArtboard id="onb-mobile" label="Onboarding · mobile" width={412} height={892}>
            <AndroidDevice width={412} height={892}>
              <OnboardingPreview tweaks={tweaks} setTweak={setTweak} />
            </AndroidDevice>
          </DCArtboard>
        </DCSection>

        <DCPostIt top={130} right={36} rotate={3} width={210}>
          Tap <strong>mic</strong> in the conversation to advance — both frames share state.
        </DCPostIt>
      </DesignCanvas>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Language" />
        <TweakRadio   label="App language" value={tweaks.lang || 'en'} options={[{ value: 'en', label: 'EN' }, { value: 'zh', label: '中文' }, { value: 'ko', label: '조선어' }]} onChange={(v) => setTweak('lang', v)} />
        <TweakSection label="Theme" />
        <TweakRadio   label="Palette"    value={tweaks.theme}      options={Object.entries(THEMES).map(([v, t]) => ({ value: v, label: t.name }))}      onChange={(v) => setTweak('theme', v)} />
        <TweakSection label="Tutor persona" />
        <TweakRadio   label="Show as" value={tweaks.tutorVisual || 'avatar'} options={['avatar', 'orb']} onChange={(v) => setTweak('tutorVisual', v)} />
        <TweakSelect  label="Speaking with" value={tweaks.persona}   options={Object.keys(PERSONAS).filter(k => PERSONAS[k].enabled !== false).map((k) => ({ value: k, label: `${PERSONAS[k].name} — ${PERSONAS[k].role}` }))} onChange={(v) => setTweak('persona', v)} />
        <TweakSection label="Learning" />
        <TweakRadio   label="Difficulty" value={tweaks.difficulty} options={Object.keys(DIFFICULTIES)} onChange={(v) => setTweak('difficulty', v)} />
        <TweakSelect  label="Feedback intensity" value={tweaks.feedback} options={Object.keys(FEEDBACKS).map(k => ({ value: k, label: FEEDBACKS[k].label }))} onChange={(v) => setTweak('feedback', v)} />
        <TweakSection label="Show frames" />
        <TweakToggle  label="Mobile (Android)" value={tweaks.showMobile} onChange={(v) => setTweak('showMobile', v)} />
        <TweakToggle  label="Desktop (Windows)" value={tweaks.showDesktop} onChange={(v) => setTweak('showDesktop', v)} />
      </TweaksPanel>
    </>
  );
}

// Onboarding preview is a separate self-contained instance so it stays on
// the onboarding flow regardless of the main app's current screen.
function OnboardingPreview({ tweaks, setTweak }) {
  const [step, setStep] = uSa(0);
  const [navState, setNavState] = uSa({ onboardStep: 0 });
  uEa(() => { setNavState({ onboardStep: step }); }, [step]);
  const theme = THEMES[tweaks.theme] || THEMES.sunrise;
  return (
    <div data-screen-label="Onboarding preview" style={{ width: '100%', height: '100%' }}>
      <OnboardScreen theme={theme} persona={tweaks.persona} difficulty={tweaks.difficulty} feedback={tweaks.feedback}
        nav={() => setStep(0)} layout="mobile" state={navState} setState={(s) => { setNavState(s); setStep(s.onboardStep ?? 0); }} />
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<FreeTalkRoot />);

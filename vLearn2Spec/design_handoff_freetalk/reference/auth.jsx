// Auth screens for FreeTalk — Sign in + Sign up.
// Sign up captures: username, usernumber (10 digits), password, gender,
// and forwards into the 4-step onboarding (goal + voice check + placement).
// All field labels are i18n-ready via t().

const { useState: uSa2, useMemo: uMa2 } = React;

// ── Shared chrome (left-side brand panel on desktop) ─────────────────
function AuthSidePanel({ theme, isDesktop, persona }) {
  const p = PERSONAS[persona] || PERSONAS.maya;
  if (!isDesktop) return null;
  return (
    <div style={{
      width: 420, flexShrink: 0, position: 'relative', overflow: 'hidden',
      background: `linear-gradient(160deg, ${p.accent} 0%, ${theme.accent2 || p.accent}dd 50%, ${theme.ink} 130%)`,
      color: '#fff', display: 'flex', flexDirection: 'column', padding: '40px 36px',
    }}>
      {/* Decoration circles */}
      <div style={{ position: 'absolute', top: -120, right: -100, width: 320, height: 320, borderRadius: '50%', background: 'rgba(255,255,255,.10)' }} />
      <div style={{ position: 'absolute', bottom: -140, left: -80, width: 280, height: 280, borderRadius: '50%', background: 'rgba(255,255,255,.06)' }} />
      <div style={{ position: 'absolute', top: '40%', right: -40, width: 140, height: 140, borderRadius: '50%', background: 'rgba(255,255,255,.08)' }} />

      <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative', zIndex: 1 }}>
        <div style={{ width: 36, height: 36, borderRadius: 10, background: '#fff', color: p.accent, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Instrument Serif, serif', fontStyle: 'italic', fontSize: 22 }}>F</div>
        <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 22, letterSpacing: '-0.01em' }}>FreeTalk</div>
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', position: 'relative', zIndex: 1 }}>
        <h1 className="ft-serif" style={{
          fontFamily: 'Instrument Serif, serif', fontSize: 56, fontWeight: 400,
          lineHeight: 1.02, margin: 0, letterSpacing: '-0.02em',
        }}>
          Open your mouth. <em>Find your voice.</em>
        </h1>
        <p style={{ marginTop: 18, fontSize: 15.5, lineHeight: 1.55, opacity: .88, maxWidth: 320 }}>
          Practice real English conversations with a patient AI tutor — right now, on your phone or laptop.
        </p>
      </div>

      {/* Floating large persona portrait */}
      <div style={{
        position: 'absolute', bottom: 24, right: -40, opacity: .35,
        animation: 'ftf-body-breathe 5s ease-in-out infinite',
      }}>
        <TalkingAvatar persona={persona} mode="idle" size={220} theme={theme} />
      </div>

      <div style={{ position: 'relative', zIndex: 1, fontSize: 12, opacity: .7, letterSpacing: '.18em', textTransform: 'uppercase' }}>
        Windows · Android · 한국어 · 中文 · English
      </div>
    </div>
  );
}

// ── Inputs ───────────────────────────────────────────────────────────
// SyncIcon — small spinning ring used while a field auto-fetches from the API.
function SyncIcon({ size = 14, color }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      style={{ animation: 'ft-orbit 1s linear infinite' }}>
      <path d="M21 12a9 9 0 1 1-3.2-6.9M21 4v5h-5" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

// SyncButton — small icon-only round button to pull a value from the REST API.
function SyncButton({ onClick, syncing, ok, theme }) {
  return (
    <button type="button" onClick={onClick} disabled={syncing}
      title={ok ? 'Synced from server' : (syncing ? 'Syncing…' : 'Fetch from server')}
      style={{
        flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
        width: 32, height: 32, borderRadius: '50%',
        border: `1px solid ${ok ? theme.good : theme.border}`,
        background: ok ? theme.good + '1a' : theme.surfaceAlt,
        color: ok ? theme.good : theme.inkSoft,
        cursor: syncing ? 'wait' : 'pointer', fontFamily: 'inherit',
        transition: 'all .15s ease', padding: 0,
      }}>
      {syncing
        ? <SyncIcon size={14} color={theme.accent} />
        : ok
          ? <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M5 12 L10 17 L19 7" stroke={theme.good} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" /></svg>
          : <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M21 12a9 9 0 1 1-3.2-6.9M21 4v5h-5" stroke={theme.inkSoft} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /></svg>}
    </button>
  );
}

function AuthField({ label, value, onChange, type = 'text', placeholder, error, hint, theme, leadingIcon, trailing, autoComplete, inputMode, maxLength, pattern }) {
  return (
    <label style={{ display: 'block', marginBottom: 14 }}>
      <div style={{ fontSize: 12, fontWeight: 600, color: theme.inkSoft, marginBottom: 6, letterSpacing: '.02em' }}>{label}</div>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        height: 48, padding: '0 14px',
        background: theme.surface, borderRadius: 12,
        border: `1px solid ${error ? theme.bad : theme.border}`,
        transition: 'border-color .15s ease, box-shadow .15s ease',
        boxShadow: error ? `0 0 0 3px ${theme.bad}22` : 'none',
      }}
      onFocus={e => e.currentTarget.style.boxShadow = `0 0 0 3px ${theme.accent}33`}
      onBlur={e => e.currentTarget.style.boxShadow = error ? `0 0 0 3px ${theme.bad}22` : 'none'}>
        {leadingIcon}
        <input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          autoComplete={autoComplete}
          inputMode={inputMode}
          maxLength={maxLength}
          pattern={pattern}
          style={{
            flex: 1, border: 'none', outline: 'none', background: 'transparent',
            fontSize: 14.5, color: theme.ink, fontFamily: 'inherit',
            minWidth: 0,
          }}
        />
        {trailing}
      </div>
      {(error || hint) && (
        <div style={{ fontSize: 11.5, marginTop: 5, color: error ? theme.bad : theme.inkFaint, lineHeight: 1.4 }}>{error || hint}</div>
      )}
    </label>
  );
}

// ── SIGN IN ──────────────────────────────────────────────────────────
function SigninScreen({ theme, persona, nav, layout, state, setState }) {
  const isDesktop = layout === 'desktop';
  const [usernumber, setUsernumber] = uSa2(state.authUsernumber || '');
  const [username, setUsername] = uSa2(state.authUsername || '');
  const [password, setPassword] = uSa2('');
  const [showPwd, setShowPwd] = uSa2(false);
  const [remember, setRemember] = uSa2(true);
  const [error, setError] = uSa2(null);
  const [syncNum, setSyncNum] = uSa2({ loading: false, ok: false });
  const [syncName, setSyncName] = uSa2({ loading: false, ok: false });

  // Mock REST fetches — wire to your real endpoint later.
  const fetchUsernumber = () => {
    setSyncNum({ loading: true, ok: false });
    setTimeout(() => {
      setUsernumber('1029384756'); // mock
      setSyncNum({ loading: false, ok: true });
    }, 900);
  };
  const fetchUsername = () => {
    setSyncName({ loading: true, ok: false });
    setTimeout(() => {
      setUsername('Jamie Chen'); // mock
      setSyncName({ loading: false, ok: true });
    }, 900);
  };

  const submit = () => {
    if (usernumber.length !== 10 || !/^\d{10}$/.test(usernumber)) {
      setError('Please enter your 10-digit user ID.');
      return;
    }
    if (!username.trim()) {
      setError('Please enter your user name.');
      return;
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }
    setError(null);
    setState({ ...state, authUsernumber: usernumber, authUsername: username.trim() });
    nav('home');
  };

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, display: 'flex', overflow: 'hidden' }}>
      <AuthSidePanel theme={theme} isDesktop={isDesktop} persona={persona} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', overflowY: 'auto', padding: isDesktop ? '40px 56px' : '24px 22px' }}>
        <div style={{ maxWidth: 420, width: '100%', margin: '0 auto' }}>
          {/* Mobile mini logo */}
          {!isDesktop && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 28 }}>
              <div style={{ width: 32, height: 32, borderRadius: 9, background: theme.accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Instrument Serif, serif', fontStyle: 'italic', fontSize: 19 }}>F</div>
              <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 20, color: theme.ink, letterSpacing: '-0.01em' }}>FreeTalk</div>
            </div>
          )}

          <div className="ft-fade-in">
            <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.18em', textTransform: 'uppercase', marginBottom: 10 }}>Welcome back</div>
            <h1 className="ft-serif" style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 44 : 32, fontWeight: 400, letterSpacing: '-0.02em', margin: '0 0 8px', lineHeight: 1.1 }}>
              Sign in to <em style={{ color: theme.accent }}>FreeTalk</em>
            </h1>
            <p style={{ fontSize: 14, color: theme.inkSoft, margin: '0 0 24px' }}>Continue your daily practice.</p>
          </div>

          <div className="ft-fade-in" style={{ animationDelay: '.08s' }}>
            <AuthField
              theme={theme}
              label="User ID"
              value={usernumber}
              onChange={(v) => { setUsernumber(v.replace(/[^0-9]/g, '').slice(0, 10)); setSyncNum({ loading: false, ok: false }); }}
              placeholder="1234567890"
              inputMode="numeric"
              autoComplete="username"
              maxLength={10}
              hint={usernumber ? `${usernumber.length} / 10 digits` : 'Your 10-digit FreeTalk ID.'}
              leadingIcon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M4 7h16M4 12h16M4 17h10" stroke={theme.inkFaint} strokeWidth="1.7" strokeLinecap="round"/></svg>}
              trailing={<SyncButton theme={theme} onClick={fetchUsernumber} syncing={syncNum.loading} ok={syncNum.ok} />}
            />
            <AuthField
              theme={theme}
              label="User ID"
              value={username}
              onChange={(v) => { setUsername(v); setSyncName({ loading: false, ok: false }); }}
              placeholder="Your login ID"
              autoComplete="username"
              hint="Synced with your FreeTalk profile."
              leadingIcon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke={theme.inkFaint} strokeWidth="1.7"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6" stroke={theme.inkFaint} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/></svg>}
              trailing={<SyncButton theme={theme} onClick={fetchUsername} syncing={syncName.loading} ok={syncName.ok} />}
            />
            <AuthField
              theme={theme}
              label="Password"
              value={password}
              onChange={setPassword}
              type={showPwd ? 'text' : 'password'}
              placeholder="••••••••"
              autoComplete="current-password"
              leadingIcon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><rect x="4" y="11" width="16" height="10" rx="2" stroke={theme.inkFaint} strokeWidth="1.7"/><path d="M8 11V8a4 4 0 0 1 8 0v3" stroke={theme.inkFaint} strokeWidth="1.7"/></svg>}
              trailing={<button type="button" onClick={() => setShowPwd(s => !s)} style={{ border: 'none', background: 'transparent', color: theme.inkSoft, cursor: 'pointer', padding: 4, fontSize: 12, fontWeight: 500 }}>{showPwd ? 'Hide' : 'Show'}</button>}
              error={error}
            />

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: theme.inkSoft, cursor: 'pointer' }}>
                <span onClick={() => setRemember(r => !r)} style={{ width: 18, height: 18, borderRadius: 5, border: `1.5px solid ${remember ? theme.accent : theme.border}`, background: remember ? theme.accent : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all .15s' }}>
                  {remember && <Icon name="check" size={11} stroke="#fff" />}
                </span>
                Remember me
              </label>
              <a href="#" onClick={e => e.preventDefault()} style={{ fontSize: 13, color: theme.accent, fontWeight: 600, textDecoration: 'none' }}>Forgot password?</a>
            </div>

            <Button theme={theme} size="lg" onClick={submit} full
              style={{ width: '100%', justifyContent: 'center' }}
              iconRight={<Icon name="arrow" size={16} stroke="#fff" />}>
              Sign in
            </Button>

            <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '24px 0', color: theme.inkFaint, fontSize: 11.5, letterSpacing: '.08em' }}>
              <div style={{ flex: 1, height: 1, background: theme.border }} />
              OR
              <div style={{ flex: 1, height: 1, background: theme.border }} />
            </div>

            <div style={{ textAlign: 'center', fontSize: 14, color: theme.inkSoft }}>
              New to FreeTalk?{' '}
              <a href="#" onClick={e => { e.preventDefault(); nav('signup'); }} style={{ color: theme.accent, fontWeight: 700, textDecoration: 'none' }}>Create an account →</a>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ── SIGN UP ──────────────────────────────────────────────────────────
function SignupScreen({ theme, persona, nav, layout, state, setState }) {
  const isDesktop = layout === 'desktop';

  const [username, setUsername] = uSa2(state.authUsername || '');
  const [fullName, setFullName] = uSa2(state.authName || '');
  const [usernumber, setUsernumber] = uSa2(state.authUsernumber || '');
  const [password, setPassword] = uSa2('');
  const [confirm, setConfirm] = uSa2('');
  const [gender, setGender] = uSa2(state.authGender || '');
  const [agree, setAgree] = uSa2(false);
  const [errors, setErrors] = uSa2({});
  const [syncNum, setSyncNum] = uSa2({ loading: false, ok: false });
  const [syncName, setSyncName] = uSa2({ loading: false, ok: false });

  // Mock REST fetches — wire to your real endpoint later.
  const fetchUsernumber = () => {
    setSyncNum({ loading: true, ok: false });
    setTimeout(() => {
      setUsernumber('1029384756'); // mock
      setSyncNum({ loading: false, ok: true });
    }, 900);
  };
  const fetchUsername = () => {
    setSyncName({ loading: true, ok: false });
    setTimeout(() => {
      setUsername('Jamie Chen'); // mock
      setSyncName({ loading: false, ok: true });
    }, 900);
  };

  // Password strength meter
  const strength = uMa2(() => {
    let s = 0;
    if (password.length >= 6) s++;
    if (password.length >= 10) s++;
    if (/[A-Z]/.test(password) && /[a-z]/.test(password)) s++;
    if (/\d/.test(password) && /[^A-Za-z0-9]/.test(password)) s++;
    return s;  // 0–4
  }, [password]);
  const strengthLabel = ['Weak', 'Fair', 'Good', 'Strong', 'Excellent'][strength];
  const strengthColor = [theme.bad, theme.warn, theme.warn, theme.good, theme.good][strength];

  const submit = () => {
    const e = {};
    if (!username.trim() || username.trim().length < 2) e.username = 'Please enter your name.';
    if (!fullName.trim() || fullName.trim().length < 2) e.fullName = 'Please enter your full name.';
    if (!/^\d{10}$/.test(usernumber)) e.usernumber = 'Must be exactly 10 digits.';
    if (password.length < 6) e.password = 'At least 6 characters.';
    if (confirm !== password) e.confirm = 'Passwords don’t match.';
    if (!gender) e.gender = 'Please pick one.';
    if (!agree) e.agree = 'Please accept to continue.';
    setErrors(e);
    if (Object.keys(e).length) return;

    // Persist registration into navState; onboarding will continue from here.
    setState({
      ...state,
      authUsername: username.trim(),
      authName: fullName.trim(),
      authUsernumber: usernumber,
      authGender: gender,
      onboardStep: 1,         // skip the welcome step — we already have you
    });
    nav('onboard');
  };

  const GenderOpt = ({ id, label, icon }) => {
    const active = gender === id;
    return (
      <button onClick={() => setGender(id)} style={{
        flex: 1, padding: '12px 8px', borderRadius: 12,
        border: `1.5px solid ${active ? theme.accent : theme.border}`,
        background: active ? theme.accentSoft : theme.surface,
        color: active ? theme.accentInk : theme.ink,
        cursor: 'pointer', fontFamily: 'inherit',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
        fontSize: 13, fontWeight: 600,
        transition: 'all .15s ease',
      }}>
        {icon}
        {label}
      </button>
    );
  };

  return (
    <div style={{ height: '100%', background: theme.bg, color: theme.ink, display: 'flex', overflow: 'hidden' }}>
      <AuthSidePanel theme={theme} isDesktop={isDesktop} persona={persona} />
      <div style={{ flex: 1, overflowY: 'auto', padding: isDesktop ? '40px 56px' : '24px 22px' }}>
        <div style={{ maxWidth: 460, width: '100%', margin: '0 auto' }}>
          {!isDesktop && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 24 }}>
              <div style={{ width: 32, height: 32, borderRadius: 9, background: theme.accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Instrument Serif, serif', fontStyle: 'italic', fontSize: 19 }}>F</div>
              <div style={{ fontFamily: 'Instrument Serif, serif', fontSize: 20, color: theme.ink, letterSpacing: '-0.01em' }}>FreeTalk</div>
            </div>
          )}

          <div className="ft-fade-in">
            <div style={{ fontSize: 11, color: theme.inkFaint, letterSpacing: '.18em', textTransform: 'uppercase', marginBottom: 10 }}>Create account · Step 1 of 2</div>
            <h1 className="ft-serif" style={{ fontFamily: 'Instrument Serif, serif', fontSize: isDesktop ? 40 : 28, fontWeight: 400, letterSpacing: '-0.02em', margin: '0 0 6px', lineHeight: 1.1 }}>
              Make a <em style={{ color: theme.accent }}>FreeTalk</em> account
            </h1>
            <p style={{ fontSize: 13.5, color: theme.inkSoft, margin: '0 0 20px' }}>Takes 30 seconds. We’ll do your level test next.</p>

            <div style={{ display: 'flex', gap: 6, marginBottom: 22 }}>
              <div style={{ flex: 1, height: 4, borderRadius: 2, background: theme.accent }} />
              <div style={{ flex: 1, height: 4, borderRadius: 2, background: theme.border }} />
            </div>
          </div>

          <div className="ft-fade-in" style={{ animationDelay: '.08s' }}>
            <AuthField
              theme={theme}
              label="User ID (your unique login name)"
              value={username}
              onChange={(v) => { setUsername(v); setSyncName({ loading: false, ok: false }); }}
              placeholder="e.g. jamie_c"
              autoComplete="username"
              error={errors.username}
              leadingIcon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke={theme.inkFaint} strokeWidth="1.7"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6" stroke={theme.inkFaint} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/></svg>}
              trailing={<SyncButton theme={theme} onClick={fetchUsername} syncing={syncName.loading} ok={syncName.ok} />}
            />
            <AuthField
              theme={theme}
              label="Name"
              value={fullName}
              onChange={setFullName}
              placeholder="e.g. Jamie Chen"
              autoComplete="name"
              error={errors.fullName}
              leadingIcon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M6 4h12l-2 7 4 9H4l4-9-2-7z" stroke={theme.inkFaint} strokeWidth="1.7" strokeLinejoin="round"/></svg>}
            />
            <AuthField
              theme={theme}
              label="User ID (10 digits)"
              value={usernumber}
              onChange={(v) => { setUsernumber(v.replace(/[^0-9]/g, '').slice(0, 10)); setSyncNum({ loading: false, ok: false }); }}
              placeholder="1234567890"
              inputMode="numeric"
              maxLength={10}
              hint={usernumber && !errors.usernumber ? `${usernumber.length} / 10 digits` : 'Choose a unique 10-digit ID. Used to sign in.'}
              error={errors.usernumber}
              leadingIcon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M4 7h16M4 12h16M4 17h10" stroke={theme.inkFaint} strokeWidth="1.7" strokeLinecap="round"/></svg>}
              trailing={<SyncButton theme={theme} onClick={fetchUsernumber} syncing={syncNum.loading} ok={syncNum.ok} />}
            />
            <AuthField
              theme={theme}
              label="Password"
              value={password}
              onChange={setPassword}
              type="password"
              placeholder="Min 6 characters"
              autoComplete="new-password"
              error={errors.password}
              leadingIcon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><rect x="4" y="11" width="16" height="10" rx="2" stroke={theme.inkFaint} strokeWidth="1.7"/><path d="M8 11V8a4 4 0 0 1 8 0v3" stroke={theme.inkFaint} strokeWidth="1.7"/></svg>}
            />
            {/* strength meter */}
            {password && (
              <div style={{ marginTop: -8, marginBottom: 14, display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ flex: 1, display: 'flex', gap: 3 }}>
                  {[0,1,2,3].map(i => (
                    <div key={i} style={{ flex: 1, height: 4, borderRadius: 2, background: i < strength ? strengthColor : theme.border, transition: 'background .2s' }} />
                  ))}
                </div>
                <span style={{ fontSize: 11, fontWeight: 600, color: strengthColor, fontFamily: 'JetBrains Mono, monospace', letterSpacing: '.04em', minWidth: 72, textAlign: 'right' }}>{strengthLabel}</span>
              </div>
            )}
            <AuthField
              theme={theme}
              label="Confirm password"
              value={confirm}
              onChange={setConfirm}
              type="password"
              placeholder="Repeat password"
              autoComplete="new-password"
              error={errors.confirm}
              leadingIcon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M5 12l4.5 4.5L19 7" stroke={theme.inkFaint} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/></svg>}
            />

            <div style={{ marginBottom: 14 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: theme.inkSoft, marginBottom: 8, letterSpacing: '.02em' }}>Gender</div>
              <div style={{ display: 'flex', gap: 8 }}>
                <GenderOpt id="female" label="Female"
                  icon={<svg width="20" height="20" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="9" r="5" stroke="currentColor" strokeWidth="1.6"/><path d="M12 14v7m-3-3h6" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/></svg>}
                />
                <GenderOpt id="male" label="Male"
                  icon={<svg width="20" height="20" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="13" r="5" stroke="currentColor" strokeWidth="1.6"/><path d="M16 8l5-5m-5 0h5v5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/></svg>}
                />
              </div>
              {errors.gender && <div style={{ fontSize: 11.5, marginTop: 6, color: theme.bad }}>{errors.gender}</div>}
            </div>

            <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, marginBottom: 18, fontSize: 13, color: theme.inkSoft, lineHeight: 1.5, cursor: 'pointer' }}>
              <span onClick={() => setAgree(a => !a)} style={{ marginTop: 1, width: 18, height: 18, borderRadius: 5, border: `1.5px solid ${agree ? theme.accent : (errors.agree ? theme.bad : theme.border)}`, background: agree ? theme.accent : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                {agree && <Icon name="check" size={11} stroke="#fff" />}
              </span>
              <span>I agree to the <a href="#" onClick={e => e.preventDefault()} style={{ color: theme.accent, fontWeight: 600, textDecoration: 'none' }}>Terms</a> and <a href="#" onClick={e => e.preventDefault()} style={{ color: theme.accent, fontWeight: 600, textDecoration: 'none' }}>Privacy Policy</a>.</span>
            </label>

            <Button theme={theme} size="lg" onClick={submit} full
              style={{ width: '100%', justifyContent: 'center' }}
              iconRight={<Icon name="arrow" size={16} stroke="#fff" />}>
              Continue — set up my learning
            </Button>

            <div style={{ textAlign: 'center', fontSize: 13.5, color: theme.inkSoft, marginTop: 20 }}>
              Already have an account?{' '}
              <a href="#" onClick={e => { e.preventDefault(); nav('signin'); }} style={{ color: theme.accent, fontWeight: 700, textDecoration: 'none' }}>Sign in</a>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { SigninScreen, SignupScreen });

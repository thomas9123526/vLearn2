# FreeTalk — 디자인 설명서

> FreeTalk 영어 스피킹 앱의 **모든 화면**과 **모든 컨트롤**을 신규 개발자에게
> 안내하는 문서입니다. 처음부터 끝까지 읽으면 각 픽셀이 무엇을 하는지, 어떻게
> 구현되어 있는지 대략적으로 파악할 수 있습니다.

---

## 1. FreeTalk이란?

FreeTalk은 청년·청소년 학습자가 가상의 AI 튜터와 짧은 음성 대화를 나누며
**영어 말하기**를 연습하도록 돕는 앱입니다. 세션이 끝나면 발화 점수와 교정
사항을 제공합니다.

**핵심 컨셉**

| 컨셉 | 디자인적 표현 |
|---|---|
| 카드 암기가 아닌 "대화" | 실제처럼 느껴지는 캐릭터와 채팅합니다. 단순 드릴이 없습니다. |
| 장면을 고른 뒤 말한다 | 사용자는 시나리오(면접, 카페, 첫 데이트…)를 선택해 현실감 있게 연습합니다. |
| 칭찬이 우선 | 색종이, 카운트업, 코치의 목소리. 실수도 따뜻하게 다룹니다. |
| 하나의 제품, 두 디바이스 | 같은 디자인이 Android 폰과 Windows 데스크탑 창에서 반응형으로 작동합니다. |
| 다국어 UI | 앱 chrome은 EN / 中文 / 한국어로 번역됩니다. *학습 대상 언어*는 항상 영어입니다. |
| 변경 가능한 아이덴티티 | 테마(4가지 팔레트)와 튜터 페르소나(4명)를 실시간 전환할 수 있습니다. |

**Visual DNA**

- 디스플레이 타입: **Instrument Serif** (강조 구문은 이탤릭).
- UI 타입: **Plus Jakarta Sans** (CJK는 Noto Sans SC/KR).
- Mono (숫자, 타임스탬프): **JetBrains Mono**.
- 자연의 따스함에서 영감을 받은 색 팔레트: **Apricot**, **Sage**, **Iris**,
  **Obsidian** (다크).
- 부드러운 방사형 그라데이션, 레이어드 카드, 섬세한 애니메이션 — 따스함 +
  움직임이 브랜드의 일부입니다.

---

## 2. 네비게이션 맵

```
splash ─tap─▶ home ─┬─▶ scenarios ─tap card─▶ brief ─Start─▶ convo ─End─▶ report
                    ├─▶ progress                                            │
                    ├─▶ course                                              │
                    └─▶ settings ◀───────────────────────────────────────────┘
                                  (다시 연습 → convo)

onboard (4-step, 첫 실행) ─finish─▶ home
```

모바일 셸은 **하단 탭 바**를 사용합니다 (Home / Topics / Progress / You).
convo, brief, splash, onboard 화면에서는 숨겨집니다.
데스크탑 셸은 **220-dp 좌측 사이드바**를 사용하며 동일한 네비게이션 + 큰
"Quick talk" CTA를 포함합니다. convo, brief, splash, onboard에서는 숨겨집니다.

---

## 3. 화면별 상세 투어

아래에서는 각 화면의 모든 컨트롤을 읽는 순서대로 나열합니다. 각 컨트롤마다:

- **기능** — 목적과 시각적 모양.
- **동작** — 탭, 호버, 애니메이션.
- **HTML 스케치** — 대표적인 React/HTML 스니펫. (실제 프로젝트는 React +
  인라인 스타일이지만, 여기 스니펫은 가독성을 위해 단순화했습니다.)

---

### 3.1 Splash — 첫 화면

브랜드를 소개하고 시작할 수 있게 해주는 환영 화면.

**배경**
- 테마 `bg` 색상으로 전체 화면을 채움.
- 부드러운 방사형 `glow` 오버레이 (우상단 + 좌하단 두 방사형 그라데이션).
- 워드마크 중심에 액센트 컬러 워시.

**Floating glyphs** — 가장자리에 분포된 8개의 글리프 (말풍선, 마이크, 입,
지구, 이탤릭 A, 별, 윙크, 하트, 구름). 각 글리프는 팝인(`popIn`)한 뒤
4–6초 주기로 부드럽게 떠다닙니다. 색상은 4개의 페르소나 액센트 중 무작위.

```html
<div class="splash-glyph" style="left:10%;top:14%;width:64px;height:64px;
     animation: ft-splash-in .9s .0s forwards, ft-splash-bob 4s 1s infinite;">
  <svg viewBox="0 0 64 64">
    <path d="..." fill="#d97757" /> <!-- bubble -->
  </svg>
</div>
```

**Date band** — 현재 날짜 `MONDAY · 14 MAY 2026` 스타일, 모노스페이스, 양쪽
끝에 24-px 헤어라인 룰.

**Monogram badge** — 84-dp 액센트 정사각형 (radius 24), 큰 이탤릭 "F"
세리프, 우상단에 1.6초 간격으로 깜빡이는 흰색 "스피치 점".

```html
<div class="monogram">
  <span style="font-family:'Instrument Serif';font-style:italic;font-size:56px">F</span>
  <span class="blink-dot"></span>
</div>
```

**Wordmark** — `display1` 크기 (데스크탑 108px, 모바일 72px). "Free"는
`ink` 색, *"Talk"*은 이탤릭 액센트 색. 마운트 시 페이드 + 슬라이드업.

```html
<h1 class="wordmark">Free<em>Talk</em></h1>
```

**Slogan** — 이탤릭 디스플레이체, "Open your mouth. Find your voice."

**CTA 버튼** — 알약 형태, `ink` 배경, `bg` 색상 텍스트. 끝에 액센트 칩이
화살표를 담음. 호버 시 -1 px 상승.

```html
<button class="splash-cta">
  Tap to begin
  <span class="arrow-chip">→</span>
</button>
```

**Footer caption** — 화면 하단, 흐릿한 모노: `v 1.0 · WIN · ANDROID ·
MADE FOR SPEAKERS-TO-BE`.

---

### 3.2 Onboarding — 레벨 테스트 (첫 실행 전용)

신규 사용자의 레벨을 측정하는 4단계 퍼널. 진행 점이 상단 중앙 (활성 단계는
28-px 알약, 나머지는 14-px). 각 단계는 제목, 부제, 본문, 하단의 Back / 기본
CTA로 구성됩니다.

**Step 1 — "Hi! I'm FreeTalk."**
- 펄스 효과가 있는 큰 페르소나 Avatar (데스크탑 140 dp, 모바일 110).
- 그 아래 4명의 페르소나 이름이 살짝 떠다님 (3s float, .3s stagger).
- CTA: "Continue".

**Step 2 — "Why are you here?"**
- 4개의 목표 카드 (Travel, Business, Academic, Just for fun). 각 카드는
  아이콘 타일 + 제목 + 부제 행입니다. 선택 시 자동으로 다음 단계로 이동.

```html
<button class="goal-card">
  <div class="icon-tile"><svg class="icon plane"/></div>
  <div>
    <div class="title">Travel &amp; make friends abroad</div>
    <div class="sub">Café orders, small talk, directions.</div>
  </div>
  <svg class="chevron"/>
</button>
```

**Step 3 — "Quick voice check"**
- 소리내어 읽을 디스플레이체 인용 카드.
- 88-dp 펄싱 마이크 버튼. 탭하면 (모의) 녹음.

```html
<button class="big-mic">
  <span class="pulse-ring"></span>
  <svg class="icon mic" />
</button>
```

**Step 4 — "You're at B1 · Intermediate"**
- 애니메이션 `ScoreRing` (전체 64, 부제 "CEFR B1").
- 4개 스탯 알약: Fluency 72, Grammar 58, Vocabulary 66, Pronunciation 60.
- CTA: "Build my course" → home으로 이동.

**하단 네비** — Back / 기본 CTA, 하단 고정.

---

### 3.3 Home — 일일 대시보드

splash 후 매번 사용자가 도달하는 화면.

**Greeting row**
- 캡션 색의 키커 날짜 `Tuesday · evening`.
- 디스플레이체 H1 제목: *"Hey Jamie. Talk to me?"* — 뒷 절반에 이탤릭
  액센트. (ZH/KO에서는 `t()`를 통해 번역됨.)
- 뒤따라오는 종 아이콘 버튼 + 40-dp 아바타.

```html
<div class="greeting">
  <div>
    <div class="kicker">Tuesday · evening</div>
    <h1>Hey Jamie. <em>Talk to me?</em></h1>
  </div>
  <button class="icon-button"><svg/></button>
  <img class="avatar" />
</div>
```

**Hero card — Today's session**
- 전체 폭 액센트 그라데이션 카드. 반투명 흰색 원 2개로 장식.
- 키커: `TODAY'S SESSION · B1·B2`.
- 디스플레이 H1: 오늘의 프롬프트 — "Walk me through your morning routine."
- 부제 라인: "~7 min · with {persona}".
- 버튼 2개:
  - **Start talking** — 액센트 위 흰색 (`soft` variant), 마이크 아이콘. brief로 이동.
  - **Pick a topic** — 고스트 아웃라인 흰 테두리. scenarios로 이동.
- 데스크탑에서는 우측에 96-dp 펄싱 액티브 페르소나 아바타.

```html
<div class="hero-card">
  <div class="kicker">Today's session · B1·B2</div>
  <div class="title">Walk me through your morning routine.</div>
  <div class="sub">~7 min · with Maya</div>
  <button class="btn-soft"><svg class="mic"/> Start talking</button>
  <button class="btn-ghost">Pick a topic</button>
</div>
```

**Streak card** (좌측, 데스크탑에서 1.4fr)
- 키커: "STREAK".
- 큰 세리프 "12 days in a row", 불꽃 아이콘.
- 7일 그리드 (M/T/W/T/F/S/S). 채워진 날은 체크 표시, 오늘은 2-px 액센트
  테두리.

**This-week stats card** (우측)
- 행 3개: Speak time `1h 42m`, Words spoken `4,238`, New phrases `+27`.
- 숫자는 모노.

**Recommended section**
- 섹션 헤더: 키커 `RECOMMENDED`, 디스플레이 H2 "Pick where you left off",
  뒤따라오는 고스트 버튼 "All scenarios →".
- 4–6개의 시나리오 카드 그리드 (모바일 2열, 데스크탑 3열). 각 카드에는
  아이콘 타일, 제목, blurb, `~{mins} min` 푸터.

```html
<button class="scenario-card">
  <div class="row">
    <div class="icon-tile"><svg class="airplane"/></div>
    <div class="tag">A2</div>
  </div>
  <div class="title">Airport check-in</div>
  <div class="blurb">Find your gate, handle a flight delay.</div>
  <div class="time">~7 min</div>
</button>
```

---

### 3.4 Scenarios — 주제 선택

검색 + 필터 가능한 시나리오 라이브러리.

**Title row** — H1 *"What do you want to **practice**?"* + 부제 "Pick a
scenario or just start talking — your tutor will improvise."

**Search input** — 12-radius 알약, 선두에 검색 아이콘.

```html
<div class="search">
  <svg class="search-icon"/>
  <input placeholder="Search scenarios…" />
</div>
```

**Category chips** — 7개의 알약 칩 가로 스크롤 (All / Travel / Business /
Daily life / Academic / Roleplay / Free chat). 활성 칩은 액센트로 채워집니다.
필터는 순수 클라이언트 사이드.

```html
<div class="chip-row">
  <button class="chip is-active"><svg/> All</button>
  <button class="chip"><svg/> Travel</button>
  …
</div>
```

**Scenario grid** — Home과 동일한 시나리오 카드를 1열 (모바일) 또는 3열
(데스크탑)로 배치. 스태거드 페이드인 (40 ms 간격).

---

### 3.5 Brief — 시나리오 상세

주제 선택과 대화 시작 사이의 중간 페이지로, 장면을 설정합니다.
(사용자가 가장 마음에 들어한 변경 사항 중 하나입니다.)

**Header**
- 뒤로 가기 화살표.
- 브레드크럼 칩: `BRIEF · {카테고리 이름}` 모노스페이스.

**Hero card** (데스크탑에서 좌측 일러스트레이션, 우측 헤드라인으로 분할)
- 일러스트레이션: 카테고리별 SVG 구성 (예: Travel = 비행기 + 여행가방 + 구름).
- 좌상단 떠다니는 칩: CEFR 태그 (`A2`) + 시간 (`~7 min`).
- 키커 `SCENE`, 큰 제목, 장면 묘사 (예: "Terminal 3 · 06:42 · long line at
  Skyhigh Airways").
- 난이도 라인: 컬러 알약 (`B1+ · Stretching`) + "vibe: *polite urgency*".

```html
<div class="hero">
  <div class="illustration">
    <svg viewBox="0 0 320 180">...</svg>
  </div>
  <div class="body">
    <div class="kicker">Scene</div>
    <h1>Airport check-in</h1>
    <p class="scene">Terminal 3 · 06:42 · long line at Skyhigh Airways.</p>
    <div class="meta-pill"><span class="dot"/>Stretching · vibe: <i>polite urgency</i></div>
  </div>
</div>
```

**Roles row** — 나란히 있는 2개의 카드:
- "You play" — 당신의 캐릭터 설명.
- "{Persona} plays" — 상대 캐릭터 설명.

**Twist banner** — 점선 액센트 테두리, "?!" 배지, 한 줄 깜짝 요소.

```html
<div class="twist">
  <div class="badge">?!</div>
  <div>
    <div class="kicker">The twist</div>
    <div>Your bag is 2.4 kg over and your gate just changed.</div>
  </div>
</div>
```

**Objectives & Phrases** (데스크탑에서 2열)
- **What to aim for** — 번호 매겨진 3개 목표.
- **Phrases worth stealing** — 3개의 이탤릭 인용 카드.

**Persona pairing 카드** — 작은 아바타 + 이름 + 역할 + "Change" 링크 →
Settings로 이동.

**Sticky 하단 dock**
- "Back to topics" 아웃라인 버튼.
- "Start speaking" 채워진 CTA, 선두에 마이크 + `{mins}m` 모노 접미사.

```html
<div class="dock">
  <button class="btn-outline">Back to topics</button>
  <button class="btn-primary"><svg class="mic"/>Start speaking <span class="mono">7m</span></button>
</div>
```

---

### 3.6 Conversation — 실시간 채팅

앱의 심장. 친근한 메시징 앱처럼 느껴지도록 설계됨.

**Header** (상단 고정)
- 뒤로 가기 버튼 (← 아이콘).
- 42-dp PersonaChip — 페르소나 이니셜이 있는 둥근 컬러 칩 + 우하단의 녹색
  온라인 점.
- 페르소나 이름 (굵게) + "✦ AI Tutor · Online" 부제.
- 우측: 음성통화 아이콘 버튼 + ⋯ 메뉴 버튼 (리포트로 이동).

```html
<header class="convo-header">
  <button class="back"><svg/></button>
  <div class="persona-chip"><span>EM</span><span class="online-dot"/></div>
  <div>
    <div class="name">Emma</div>
    <div class="sub"><svg class="star"/> AI Tutor · Online</div>
  </div>
  <button class="icon"><svg class="phone"/></button>
  <button class="icon"><svg class="kebab"/></button>
</header>
```

**Transcript** (스크롤 가능한 중간 영역)

- **Date pill** 중앙 정렬 (`Today, 10:24 AM`) — surfaceAlt 알약.
- **튜터 메시지** — 흰색 surface 버블, 22-radius, 헤어라인 테두리.
  버블 아래: 28-dp PersonaChip + 타임스탬프.
- **사용자 메시지** — 액센트 색이 채워진 버블 (흰 텍스트), 22-radius, 우측 정렬.
  아래: 타임스탬프 + 더블 체크 아이콘 (읽음 표시).
- **음성 메시지** — 재생 버튼 + 22-bar 파형 + 모노 길이가 있는 인셋 카드.

```html
<!-- tutor bubble -->
<div class="msg-tutor">
  <div class="bubble">That sounds wonderful! Where did you go hiking?</div>
  <div class="meta">
    <span class="persona-chip-sm">EM</span>
    <span class="time">10:25 AM</span>
  </div>
</div>

<!-- voice message -->
<div class="msg-tutor">
  <div class="voice-bubble">
    <button class="play"><svg/></button>
    <div class="wave">
      <i style="height:8px"/><i style="height:14px"/>…
    </div>
    <span class="dur">0:08</span>
  </div>
</div>

<!-- user bubble -->
<div class="msg-me">
  <div class="bubble">We went to Mount Tamalpais. The view was amazing!</div>
  <div class="meta">
    <span class="time">10:26 AM</span>
    <svg class="double-check"/>
  </div>
</div>
```

- **Tip card** — 교정이 필요한 사용자 버블 아래에 표시됩니다. 크림/warn 색조
  배경, 전구 아이콘, "Tip from {Persona}", 그리고 제안. *예*: "Try: 'The
  view was breathtaking!' — more natural."

```html
<div class="tip">
  <div class="head"><svg class="bulb"/> Tip from Emma</div>
  <div class="body">Try: <em>"The view was breathtaking!"</em> — more natural</div>
</div>
```

- **타이핑 인디케이터** — 28-dp 칩 + 작은 버블 안의 튀는 점 3개.

**빠른 답장 칩** (입력바 위, 가로 스크롤) — 사용자가 탭하여 미리 준비된 답장을
보낼 수 있는 surface 알약. 첫 칩은 스파클 아이콘이 있고 "✨ Suggest reply"라고
표시; 나머지는 시나리오에 맞춤 ("It was sunny", "About 3 hours").

**입력바** (하단 고정)
- 둥근 첨부 버튼 (`+` 아이콘).
- "Type a message..." 알약 입력 필드 + 끝에 이모지 아이콘.
- 둥근 액센트 채움 마이크 버튼 (액센트 글로우 그림자 포함).

```html
<div class="input-bar">
  <button class="circle"><svg class="plus"/></button>
  <div class="text-pill">
    <input placeholder="Type a message..." />
    <button class="emoji"><svg/></button>
  </div>
  <button class="circle accent"><svg class="mic"/></button>
</div>
```

**동작** — 마이크 탭은 모의 턴 파이프라인을 진행시킵니다:
`idle → thinking (1.4s) → idle` 다음 메시지가 삽입됩니다. 모든 턴 후, 마이크는
End로 작동하여 Report로 이동합니다.

---

### 3.7 Report — 대화 후 평가

가장 애니메이션이 많은 화면. 마운트 시 모든 것이 카운트업 / 팝인됩니다.

**마운트 안무** (순서대로, 화면 열림으로부터 ms)

| t (ms) | 내용 |
|---|---|
| 0    | 색종이 폭발 (상단에서 떨어지는 24–36개 조각) |
| 0    | 떠다니는 장식 모양들 (4개의 추상 도형) |
| 0    | 헤더 페이드인 |
| 100  | 헤드라인 ("Nice talk. *You're getting there.*") 페이드인; 이탤릭 부분은 연속 그라데이션 시머 |
| 200  | 스탯 부제: "7 min · {142 ↺} words · {20 ↺} wpm · with Maya" 카운트업 시작 |
| 300  | 점수 hero 카드 마운트 |
| 200  | 스코어 링 채우기 시작 (1.5초 tween) + 76까지 카운트업 |
| 400+ | 4개 점수 막대 자라기 + 카운트업, 180 ms 간격 |
| 900  | CEFR 도장 hero 우상단에 스프링인, 그 후 4초마다 흔들림 |
| 1600 | 링 아래 "+6 this week" 알약 도장 |
| 2100 | 알약 안에 손으로 그린 체크 표시 그리기 |
| 2400 | Coach note 카드 슬라이드업, 시머 스윕 |
| 2600 | 교정 카드들이 자라는 좌측 액센트 바와 함께 스태거드 등장 |
| 3200 | 포켓 문구 카드들 스태거드 등장 |
| 3800 | CTA들 슬라이드업 |

**Header**
- 뒤로 가기 화살표 (→ home).
- 키커 `SESSION REPORT`.
- 공유 알약 버튼 (아웃라인).

**Headline + meta**
```html
<h1 class="report-h1">
  Nice talk. <em class="shimmer">You're getting there.</em>
</h1>
<p class="meta">
  7 min · <span class="mono">142</span> words · <span class="mono">20</span> wpm · with Maya
</p>
```

**점수 hero 카드**
- 떠다니는 CEFR 등급 도장 (예: `B1+`), -8° 기울임, 스프링인 후 흔들림.
- 좌측에 애니메이션 스코어 링, 8개 궤도 스파클, 뒤에 방사형 폭발.
- 링 아래 "+6 this week" 배지가 체크마크와 함께 도장.
- 우측에 4개의 애니메이션 점수 바: Pronunciation 78 / Grammar 71 / Fluency 84 / Vocabulary 69.

```html
<div class="score-hero">
  <div class="cefr-stamp">CEFR<br/>B1+</div>
  <div class="ring-wrap">
    <svg class="ring"> ... </svg>
    <div class="value">76</div>
    <div class="delta">✓ +6 this week</div>
  </div>
  <div class="bars">
    <Bar label="pronunciation" value="78"/>
    <Bar label="grammar"       value="71"/>
    <Bar label="fluency"       value="84"/>
    <Bar label="vocabulary"    value="69"/>
  </div>
</div>
```

**Coach note** — 페르소나 아바타가 있는 surfaceAlt 카드, 말풍선 꼬리,
움직이는 시머, 이탤릭 디스플레이 인용구. 헤더에 펄싱하는 "live" 점.

**교정 목록** — 4개 카드. 각각:
- 자라는 좌측 액센트 바 (문법은 warn, 발음은 bad).
- 작은 아이콘 타일.
- 잘못된 문장 (취소선) → 흔들리는 화살표 → 액센트 색의 올바른 문장.
- 이유 설명 노트.
- 우측의 작은 재생 버튼.

```html
<div class="correction-card">
  <div class="left-bar warn"></div>
  <div class="icon"><svg/></div>
  <div class="body">
    <div>
      <s>I go to hiking on weekends.</s>
      <svg class="arrow wiggle"/>
      <strong>I go hiking on weekends.</strong>
    </div>
    <div class="note">No "to" after "go" + activity-ing.</div>
  </div>
  <button class="play-mini"><svg/></button>
</div>
```

**새 문구** — 3개 카드가 행 (데스크탑) 또는 열 (모바일)로 배치됩니다. 각
카드에는 이탤릭 디스플레이 "문구", 이탤릭 예시 문장, 호버 시 90° 회전하는
`+` 버튼 (어휘에 저장).

**하단 CTAs**
- 아웃라인 "Done" — home으로 이동.
- 채워진 "Practice again" — 천천히 떠다님; 새 convo로 이동.

---

### 3.8 Progress — 차트 + 배지

장기 통계와 동기부여 페이지. 모든 숫자/막대는 마운트 시 0 → 목표로
애니메이션.

**Header** — H1 *"Your **progress**"* + 부제 "7 weeks in. Up and to the right."

**CEFR 카드**
- 세리프 "B1" 흰색이 있는 64-dp 액센트 정사각형.
- 키커 `CURRENT LEVEL`.
- 디스플레이 부제 "Intermediate · climbing toward B2".
- 6-스톱 A1–C2 가로 막대가 마운트 시 0 → 64 %로 채워집니다.

**주간 활동 차트**
- 키커 `MINUTES SPOKEN`, `AnimatedNumber 316 min` + `· last 7 weeks`가 있는
  디스플레이 H1. 녹색 +28% 델타.
- 7개의 수직 막대 (W1–W7), 각각 80 ms 간격으로 0에서 목표까지 자랍니다.
  마지막 막대는 액센트 색; 나머지는 accentSoft. 마지막 막대 위: 카운트업
  라벨.

```html
<div class="chart">
  <div class="bar" style="height:0%; animation: ft-bar-grow 1.2s ease-out forwards"></div>
  …
</div>
```

**스킬 분석** — 데스크탑에서 2열. 4개 카드 (Fluency / Grammar / Vocabulary
/ Pronunciation). 각각 점수 카운트업 + 애니메이션 막대 + 녹색 주간 델타.

**Badges**
- 섹션 제목 + 6열 (모바일 3열)의 둥근 배지 그리드.
- 잠금 해제된 배지는 액센트로 채워짐; 잠긴 배지는 45 % 불투명도의 surfaceAlt에
  "Locked" 캡션.

```html
<div class="badge unlocked">
  <div class="icon"><svg class="flame"/></div>
  <div class="label">7-day Streak</div>
</div>
<div class="badge locked">
  <div class="icon"><svg class="grad"/></div>
  <div class="label">Debate Champ</div>
  <div class="sub">Locked</div>
</div>
```

---

### 3.9 Course — 학습 경로 빌더

하단에 미리보기가 있는 3단계 설정 마법사.

**Header** — H1 *"Build your **course**"* + 부제 "Tell us how you live and
we'll script lessons around it."

**Section 01 — "What should we drill?"**
6개 카테고리 타일, 다중 선택. 탭하면 포함 여부 토글 (활성 시 액센트 테두리 +
accentSoft 채움).

```html
<button class="course-tile is-active">
  <div class="icon-circle"><svg class="plane"/></div>
  <div class="label">Travel</div>
</button>
```

**Section 02 — "What kind of conversations?"**
3개 단일 선택 카드: Realistic / Clean / Playful. 우측에 활성 시 액센트로
채워지는 라디오 인디케이터.

**Section 03 — "How much time per day?"**
- 큰 세리프 카운트 "15 min" + 부제 "~1.8 hrs / week" (실시간 재계산).
- 5 → 45 step 5 네이티브 레인지 슬라이더, `accentColor`로 테마 적용.

```html
<input type="range" min="5" max="45" step="5" value="15"
       style="accent-color:#d4633a"/>
```

**Your plan / Next 4 weeks** — 수직 타임라인.
- 좌측에 1-dp 수직 가이드 라인, 4개의 둥근 번호 매겨진 배지.
- 각 행은 카드: 주차 키커 + 제목 + 모노로 "5 sessions".

**하단 CTA** — 후행 화살표가 있는 큰 채워진 "Save my course".

---

### 3.10 Settings

가장 다양한 페이지. 프로필 + 정체성 + 환경설정을 결합.

**언어 목록 (페이지의 가장 첫 번째)**
- 키커 `APP LANGUAGE`.
- 3개 행이 있는 단일 카드의 수직 목록: EN, 中文, 한국어. 각 행에는 36-dp
  액센트 모노그램, 디스플레이체로 된 원어 표기, 모노로 된 로마자 표기, 우측에
  원형 라디오 인디케이터. 활성 행은 accentSoft로 색조 처리.

```html
<div class="lang-list">
  <button class="lang-row is-active">
    <div class="flag-chip">EN</div>
    <div>
      <div class="native">English</div>
      <div class="latin">English</div>
    </div>
    <div class="radio is-active"><svg class="check"/></div>
  </button>
  <!-- 中 row, 한 row -->
</div>
```

**페이지 H1** — "Settings".

**Profile 카드**
- 56-dp 원형 아바타 (모노그램).
- 이름 + 부제 라인 ("jamie@freetalk.app · B1 · Intermediate").
- 우측에 "Edit" 아웃라인 버튼.

**Tutor / Choose your speaking partner — 선형 캐러셀**
이 페이지의 hero 컨트롤. 이전 4-up 그리드를 대체.

- 44-dp 좌측 화살표 버튼 (둥근, surface, 헤어라인 테두리).
- 중앙 무대: 96-dp 프레임이 있는 `TalkingAvatar` (애니메이션 얼굴), 그 다음
  우측에 디스플레이체 이름, 역할, 작은 "✓ Selected" 액센트 알약.
- 44-dp 우측 화살표 버튼.
- 아래: 점 인디케이터 (4개 점; 활성은 22-px 알약으로 확장).
- 화살표 + 점은 Maya, Leo, Sofia, Theo를 순환.

```html
<div class="persona-carousel">
  <button class="arrow"><svg/></button>
  <div class="stage">
    <div class="face"><TalkingAvatar persona="leo" /></div>
    <div>
      <div class="name">Leo</div>
      <div class="role">Cool mentor</div>
      <div class="badge accent">✓ Selected</div>
    </div>
  </div>
  <button class="arrow flip"><svg/></button>
  <div class="dots">
    <button class="dot"/>
    <button class="dot is-active"/>
    <button class="dot"/>
    <button class="dot"/>
  </div>
</div>
```

**Difficulty** — 3개 세그먼트 카드 (Beginner / Intermediate / Advanced) +
CEFR 부제.

**Feedback** — 3개 세그먼트 카드 (Gentle / Balanced / Strict) + 태그라인.

**Theme** — 4개 스와치 버튼; 각각 테마의 bg 채움 + 2개 미니 스와치 (accent +
surfaceAlt) + 이름 라벨.

```html
<button class="theme-swatch" style="background:#faf6ef">
  <div class="swatches">
    <i style="background:#d4633a"/>
    <i style="background:#f2eada"/>
  </div>
  <div class="name">Apricot</div>
</button>
```

**Preferences 목록 카드** — 4개 행: Daily reminder (`7:00 PM`), Voice
playback speed (`1.0×`), Microphone (`System default`), Sign out (`bad` 색,
후행 화살표 없음). 각 행에는 좌측에 작은 아이콘 타일, 라벨, 우측에 모노 값,
셰브론.

---

## 4. 공유 컴포넌트 카탈로그

화면 전반에서 볼 수 있는 재사용 가능한 위젯에 대한 간단한 요약.

| 컴포넌트 | 목적 | 비고 |
|---|---|---|
| **Avatar** | 페르소나 모노그램 칩. | 크기 28–56. 펄스 + 외부 링 옵션. |
| **TalkingAvatar** | 큰 애니메이션 SVG 얼굴. | 말할 때 립싱크, 평소 깜빡임, 듣기 모드에서 기울임. |
| **ScoreRing** | 원형 진행률. | 스파클 + 카운트업이 있는 애니메이션 변형 있음. |
| **AnimatedBar / Bar** | 선형 진행률 0 → 목표. | 시머 스윕 옵션. |
| **AnimatedNumber** | 카운트업 텍스트. | 스탯에서 사용. |
| **Card** | Surface 컨테이너. | 18-radius, 헤어라인 테두리, 인셋 하이라이트 + 그림자. |
| **Button** | 4가지 변형: primary / soft / outline / ghost. | 누름 = scale .97. Primary는 액센트 글로우. |
| **Chip** | 알약 버튼. | 활성 시 액센트 채움으로 전환. |
| **SectionHead** | 섹션 제목 그룹. | 작은 키커 + 디스플레이 H2 + 후행 액션. |
| **PersonaChip** | 온라인 점이 있는 단색 둥근 칩. | 채팅 헤더에서 사용. |
| **VoiceBubble** | 음성 메시지 버블. | 재생 + 22-bar 파형 + 길이. |
| **TipCard** | 코치 교정. | warn 색조, 전구 아이콘. |
| **DoubleCheck** | 읽음 표시 아이콘. | 사용자 메시지 타임스탬프 뒤. |
| **ConfettiBurst** | 마운트 시 색종이. | 24–36개 조각, 무작위. |
| **Waveform** | scaleY를 반복하는 N개 막대. | 활성 마이크 버튼 안에서. |
| **Tabs / Sidebar** | 최상위 네비게이션. | 모바일 하단 4탭; 데스크탑 5항목 사이드바. |

---

## 5. 테마 시스템

4개 팔레트, 모두 동일한 토큰 이름 사용 — 테마를 바꾸면 팔레트 객체만
바뀝니다. 정확한 hex 값은 핸드오프 패키지의 `tokens.json` 참조.

| 테마 | 분위기 | 적합한 용도 |
|---|---|---|
| **Apricot** (기본) | 지중해 빌라, 황금빛 시간. 따뜻한 양피지 + 테라코타. | 친근한 기본. |
| **Sage** | 유칼립투스 + 더스티 로즈. 조용하고 편집적. | 차분한 집중. |
| **Iris** | 시원한 아이보리 + 페리윙클 + 따뜻한 앰버. 세련됨. | 학문적 / 전문가 분위기. |
| **Obsidian** | 깊은 네이비 + 일렉트릭 틸 + 따뜻한 앰버. | 다크 모드. |

각 페르소나는 테마 전반에서 동일하게 유지되는 자체 액센트 색상을 가집니다.
(Leo는 항상 파란색, Sofia는 항상 보라색) 앱의 chrome이 바뀌어도 각 튜터에게
안정적인 정체성을 부여합니다.

---

## 6. 모션 시스템

모든 애니메이션은 토큰에 정의되어 (커브 + 지속 시간) 일관된 느낌을 줍니다.

| 패턴 | 용도 | 지속 시간 |
|---|---|---|
| Fade-in / slide-up | 콘텐츠 등장 | 420 ms |
| Pop-in (spring) | 중요 요소 (배지, 아바타) | 500 ms |
| Count-up | 숫자 | 1200 ms ease-out |
| Bar grow | 진행률 막대 | 900–1200 ms |
| Score-ring fill | 스코어 링 | 1500 ms |
| Pulse (반복) | 마이크 + 페르소나 | 1800 ms |
| Confetti fall | Report 마운트 | 2400–4000 ms |
| Shimmer | 헤드라인 이탤릭 + 막대 상단 | 2400 ms 반복 |

---

## 7. i18n

모든 사용자 대상 문자열은 `t('영어 원본 문자열')`을 통과합니다. 누락된 번역은
영어로 폴백되므로 UI가 절대 깨지지 않습니다. 활성 언어는 반응형 — Settings에서
언어를 전환하면 *모든* 보이는 문자열이 즉시 업데이트됩니다. CJK 폰트는
`<html lang>`을 통해 자동 스왑되어 타입 메트릭이 정확하게 유지됩니다.

---

## 8. 무엇부터 만들 것인가

Flutter (또는 다른 곳)에서 이를 구현한다면, 다음 순서가 좋습니다:

1. **Theme** — 4개 팔레트를 ThemeData로 설정하고 선택기를 연결.
2. **Avatar + TalkingAvatar + ScoreRing + AnimatedBar** — 이러한 프리미티브는
   모든 곳에 등장.
3. **Home + Splash** — 비주얼 언어를 확립.
4. **Conversation** — 제품의 킬러 화면.
5. **Report** — 두 번째 킬러 화면. 애니메이션 안무가 많음.
6. **Scenarios + Brief** — 콘텐츠가 많지만 대부분 레이아웃.
7. **Progress + Course + Settings** — 보조 화면.
8. **Onboarding** — 마지막; 레벨 측정 점수에 훅이 필요.

이제 방향이 잡혔습니다! 라인별 사양은 핸드오프 패키지의 `screens.md`와
`components.md`를, 라이브 인터랙티브 참조는 HTML 프로토타입을 참고하세요.

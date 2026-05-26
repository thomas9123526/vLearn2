# 시나리오 필드 설명

`todoList_report/scenario/` 하위의 각 시나리오 파일에 나타나는
**Metadata** 및 **Database Row** 섹션의 모든 필드에 대한 참조 문서입니다.

---

## Metadata 필드

각 시나리오 파일 상단에 표시되는 요약 정보 필드입니다.

| 필드 | 타입 | 설명 |
|------|------|------|
| **Slug** | string | 시나리오의 URL 안전 고유 식별자. API 라우트(`GET /scenarios/:slug`), 딥링크, 그리고 이 MD 파일의 파일명으로 사용됩니다. 형식: `kebab-case`. 예시: `business-meeting-intro`. |
| **Category** | enum | 시나리오가 속한 주제 그룹. `travel`(여행), `business`(비즈니스), `social`(소셜), `daily`(일상) 중 하나. 시나리오 화면에서 카드가 표시될 섹션과 브리프 화면의 카테고리 일러스트(이모지)를 결정합니다. |
| **CEFR Level** | string | `difficulty` 숫자 필드로부터 변환된 유럽 공통언어 참조기준(CEFR) 레벨 표기 (1=A1, 2=A2, 3=B1, 4=B2, 5=C1, 6=C2). 히어로 카드 pill에 표시됩니다 ("CEFR · B1"). 학습자에게 대화의 난이도를 알려줍니다. |
| **XP Reward** | integer | 시나리오를 완료(`status = completed`)했을 때 사용자가 획득하는 경험치. 백엔드에서 `min(발화_단어수, xp_reward)`로 상한선이 적용되므로 짧은 대화는 비례적으로 적게 획득됩니다. 히어로 카드 pill에 표시됩니다 ("+60 XP"). |
| **Estimated Minutes** | integer | 편안한 속도로 대화를 완료하는 데 걸리는 예상 시간. 히어로 카드 pill("~6 min")과 "Start speaking" 버튼("Start speaking (6m)")에 표시됩니다. 콘텐츠 작성자가 설정하며 시스템에서 강제하지 않습니다. |

---

## Database Row 필드

`vl_scenarios` 테이블의 컬럼(`ScenarioEntity`)에 직접 매핑되는 필드입니다.

| 필드 | DB 컬럼 | 타입 | 설명 |
|------|---------|------|------|
| **slug** | `slug` | varchar, unique | 머신 식별자 — 위의 Metadata Slug와 동일. 앱과 어드민 패널에서 기본 조회 키로 사용됩니다. |
| **category** | `category` | varchar | Metadata Category와 동일. 평문 문자열로 저장되며, 앱에서 일러스트 및 목표 텍스트를 결정할 때 `switch`문으로 사용됩니다. |
| **difficulty** | `difficulty` | integer (1–6) | 숫자형 CEFR 레벨. `1` = A1(입문) … `6` = C2(숙달). 앱에서 표시용 레벨 레이블로 변환됩니다. 시나리오 화면의 난이도 필터 슬라이더에도 사용됩니다. |
| **estimated_minutes** | `estimated_minutes` | integer | Metadata Estimated Minutes와 동일. |
| **xp_reward** | `xp_reward` | integer | Metadata XP Reward와 동일. |
| **title_en** | `title->>'en'` | jsonb (I18nText) | 영어 표시 제목. 브리프 화면의 앱바와 시나리오 카드에 표시됩니다. `title` 컬럼은 `{en, ko, zh}` JSON 객체이며, `title_en`은 영어 부분입니다. |
| **title_ko** | `title->>'ko'` | jsonb (I18nText) | 제목의 한국어 번역. UI 언어가 `ko`일 때 표시됩니다. |
| **title_zh** | `title->>'zh'` | jsonb (I18nText) | 제목의 중국어 간체 번역. UI 언어가 `zh`일 때 표시됩니다. |
| **description** | `description->>'en'` | jsonb (I18nText) | 히어로 카드 본문에 표시되는 한 문장 영어 요약. 학습자가 전체 브리프를 읽기 전에 어떤 연습을 할지 빠르게 파악할 수 있도록 합니다. |
| **scene_en** | `scene_description->>'en'` | jsonb (I18nText) | 대화의 물리적·상황적 배경을 설정합니다. AI 시스템 프롬프트에 `{{scenario.setting}}`으로 주입됩니다. AI가 대화가 이루어지는 장소를 일관되게 유지하는 데 사용됩니다. 예시: *"공항 항공사 체크인 카운터 앞에 있습니다."* |
| **user_role_en** | `user_role->>'en'` | jsonb (I18nText) | 이 시나리오에서 학습자가 맡는 역할을 설명합니다. 시스템 프롬프트에 `{{scenario.user_role}}`로 주입됩니다. AI가 학습자의 관점과 어휘 수준에 맞게 응답하도록 돕습니다. 예시: *"수하물을 체크인하려는 여행자."* |
| **tutor_role_en** | `tutor_role->>'en'` | jsonb (I18nText) | AI 튜터가 연기하는 캐릭터를 설명합니다. 시스템 프롬프트에 `{{scenario.tutor_role}}`로 주입됩니다. 시나리오가 진행되는 동안 튜터의 기본 페르소나 역할을 이것으로 대체합니다. 예시: *"친절한 항공사 직원."* |
| **objectives_en** | `objectives` (jsonb array) | `{en: string}[]` | 세션 동안 학습자가 달성해야 하는 대화 목표의 순서 있는 목록. `, `로 연결되어 `{{scenario.objectives}}`로 주입됩니다. AI는 이를 통해 특정 연습 목표(예: 좌석 업그레이드 요청, 탑승권 받기)를 향해 자연스럽게 대화를 유도합니다. |
| **key_phrases** | `key_phrases` (jsonb array) | `{phrase: string, ko?, zh?}[]` | 학습자가 사용해보아야 할 영어 표현. 브리프 화면의 인용 카드("Phrases worth stealing")에 표시되고, `{{scenario.key_phrases}}`로 주입되어 AI가 학습자가 자연스럽게 해당 표현을 사용할 때 인식하고 칭찬할 수 있습니다. 선택적 한국어/중국어 번역은 브리프 화면 표시 전용이며 AI에는 전송되지 않습니다. |
| **status** | `status` | varchar | 게시 상태. `draft`(앱에 표시 안 됨), `published`(표시 및 플레이 가능), `archived`(숨김) 중 하나. `GET /scenarios` 응답과 `POST /conversations/sessions` 허용은 `published` 상태의 시나리오만 해당됩니다. |

---

## 필드가 AI 프롬프트에 적용되는 방식

```
scene_en       → {{scenario.setting}}
tutor_role_en  → {{scenario.tutor_role}}
user_role_en   → {{scenario.user_role}}
objectives_en  → {{scenario.objectives}}   (연결: "목표1, 목표2, 목표3")
key_phrases    → {{scenario.key_phrases}}  (연결: "표현A, 표현B")
title_en       → {{scenario.title}}
```

**AI에 전송되지 않는 필드**: `slug`, `category`, `difficulty`, `estimated_minutes`,
`xp_reward`, `title_ko`, `title_zh`, `description`, `status`.

이 필드들은 앱 UI 전용으로, 학습자가 대화를 시작하기 전에 보는 화면에만 영향을 미치며
AI 모델이 대화 중에 받는 내용과는 무관합니다.

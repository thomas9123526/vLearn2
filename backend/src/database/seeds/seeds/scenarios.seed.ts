import { DataSource } from 'typeorm';
import { CategoryEntity } from '../../entities/category.entity';
import { ScenarioEntity } from '../../entities/scenario.entity';

interface ScenarioSeed {
  slug: string;
  category: 'travel' | 'business' | 'social' | 'daily';
  difficulty: number;
  estimated_minutes: number;
  xp_reward: number;
  title_en: string;
  title_ko: string;
  title_zh: string;
  description_en: string;
  scene_en: string;
  user_role_en: string;
  tutor_role_en: string;
  objectives_en: string[];
  key_phrases: { phrase: string; ko?: string; zh?: string }[];
}

const SCENARIOS: ScenarioSeed[] = [
  // ── Travel (5) ────────────────────────────────────────────
  {
    slug: 'airport-check-in',
    category: 'travel',
    difficulty: 2,
    estimated_minutes: 5,
    xp_reward: 50,
    title_en: 'Airport check-in',
    title_ko: '공항 체크인',
    title_zh: '机场办理登机',
    description_en: 'Practice checking in for an international flight.',
    scene_en: "You're at an airline check-in desk for an international flight.",
    user_role_en: 'A traveler with luggage to check in.',
    tutor_role_en: 'A friendly airline agent.',
    objectives_en: [
      'Greet politely',
      'Check bags',
      'Ask about your seat',
      'Get a boarding pass',
    ],
    key_phrases: [
      { phrase: "I'd like to check in for flight…" },
      { phrase: 'I have one bag to check.' },
      { phrase: 'Do you have an aisle seat available?' },
    ],
  },
  {
    slug: 'hotel-reservation',
    category: 'travel',
    difficulty: 2,
    estimated_minutes: 5,
    xp_reward: 50,
    title_en: 'Hotel reservation',
    title_ko: '호텔 예약',
    title_zh: '酒店预订',
    description_en: 'Book a room and discuss amenities.',
    scene_en: "You're calling a hotel to reserve a room.",
    user_role_en: 'A guest planning a trip.',
    tutor_role_en: 'A hotel receptionist.',
    objectives_en: [
      'Ask about availability',
      'Choose a room type',
      'Confirm price',
      'Make the booking',
    ],
    key_phrases: [
      { phrase: "I'd like to book a room for two nights." },
      { phrase: 'Does the room come with breakfast?' },
      { phrase: 'Is there free Wi-Fi?' },
    ],
  },
  {
    slug: 'restaurant-ordering',
    category: 'travel',
    difficulty: 1,
    estimated_minutes: 5,
    xp_reward: 40,
    title_en: 'Ordering at a restaurant',
    title_ko: '레스토랑에서 주문하기',
    title_zh: '在餐厅点餐',
    description_en: 'Order food and drinks at a casual restaurant.',
    scene_en: "You're at a casual restaurant looking at the menu.",
    user_role_en: 'A diner ready to order.',
    tutor_role_en: 'A friendly server.',
    objectives_en: [
      'Ask for recommendations',
      'Order a meal',
      'Request modifications',
      'Ask for the check',
    ],
    key_phrases: [
      { phrase: 'What do you recommend?' },
      { phrase: "I'll have the…" },
      { phrase: 'Could I have the check, please?' },
    ],
  },
  {
    slug: 'shopping-clothes',
    category: 'travel',
    difficulty: 2,
    estimated_minutes: 5,
    xp_reward: 50,
    title_en: 'Shopping for clothes',
    title_ko: '옷 쇼핑하기',
    title_zh: '购买衣服',
    description_en: 'Try on clothes and ask about sizes and prices.',
    scene_en: "You're in a clothing store browsing.",
    user_role_en: 'A shopper looking for an outfit.',
    tutor_role_en: 'A store clerk.',
    objectives_en: [
      'Ask about sizes',
      'Try clothes on',
      'Compare prices',
      'Make a purchase',
    ],
    key_phrases: [
      { phrase: 'Do you have this in a larger size?' },
      { phrase: 'Can I try it on?' },
      { phrase: 'How much is it?' },
    ],
  },
  {
    slug: 'taxi-ride',
    category: 'travel',
    difficulty: 1,
    estimated_minutes: 4,
    xp_reward: 40,
    title_en: 'Taking a taxi',
    title_ko: '택시 타기',
    title_zh: '乘坐出租车',
    description_en: 'Get a taxi to your destination.',
    scene_en: "You're hailing a taxi in a big city.",
    user_role_en: 'A passenger heading to a hotel.',
    tutor_role_en: 'A taxi driver.',
    objectives_en: [
      'State your destination',
      'Estimate the fare',
      'Give directions if needed',
      'Pay and tip',
    ],
    key_phrases: [
      { phrase: 'Could you take me to…' },
      { phrase: 'How long will it take?' },
      { phrase: 'Keep the change.' },
    ],
  },
  // ── Business (5) ──────────────────────────────────────────
  {
    slug: 'business-meeting-intro',
    category: 'business',
    difficulty: 3,
    estimated_minutes: 6,
    xp_reward: 60,
    title_en: 'Introducing yourself at a meeting',
    title_ko: '회의에서 자기소개',
    title_zh: '会议自我介绍',
    description_en: 'Make a strong first impression in a professional meeting.',
    scene_en: "You're at a kickoff meeting with new colleagues.",
    user_role_en: 'A new team member.',
    tutor_role_en: 'A senior colleague.',
    objectives_en: [
      'Introduce yourself',
      'State your role',
      'Mention your background',
      'Ask about their work',
    ],
    key_phrases: [
      { phrase: 'Pleased to meet you.' },
      { phrase: "I'll be working on…" },
      { phrase: "What's your focus area?" },
    ],
  },
  {
    slug: 'email-followup',
    category: 'business',
    difficulty: 3,
    estimated_minutes: 5,
    xp_reward: 60,
    title_en: 'Writing a follow-up email',
    title_ko: '후속 이메일 작성',
    title_zh: '撰写跟进邮件',
    description_en: 'Compose a polite follow-up to a client.',
    scene_en: 'You need to follow up on a proposal you sent last week.',
    user_role_en: 'An account manager.',
    tutor_role_en: 'A communication coach.',
    objectives_en: [
      'Reference the previous message',
      'Be polite but direct',
      'Suggest next steps',
      'Close professionally',
    ],
    key_phrases: [
      { phrase: 'I wanted to follow up on…' },
      { phrase: 'Let me know if you have any questions.' },
      { phrase: 'Looking forward to your reply.' },
    ],
  },
  {
    slug: 'business-presentation',
    category: 'business',
    difficulty: 4,
    estimated_minutes: 7,
    xp_reward: 70,
    title_en: 'Giving a short presentation',
    title_ko: '간단한 프레젠테이션',
    title_zh: '简短演讲',
    description_en: 'Present an idea to stakeholders.',
    scene_en: "You're presenting a Q1 update.",
    user_role_en: 'A team lead.',
    tutor_role_en: 'A stakeholder.',
    objectives_en: [
      'Open with context',
      'Share key results',
      'Discuss next steps',
      'Take questions',
    ],
    key_phrases: [
      { phrase: "Today I'd like to walk you through…" },
      { phrase: 'The key takeaway is…' },
      { phrase: "I'd love your feedback." },
    ],
  },
  {
    slug: 'price-negotiation',
    category: 'business',
    difficulty: 4,
    estimated_minutes: 6,
    xp_reward: 70,
    title_en: 'Negotiating a price',
    title_ko: '가격 협상',
    title_zh: '价格谈判',
    description_en: 'Negotiate fairly while building rapport.',
    scene_en: "You're negotiating with a vendor.",
    user_role_en: 'A buyer.',
    tutor_role_en: 'A seller.',
    objectives_en: [
      'Anchor your offer',
      'Justify your number',
      'Listen actively',
      'Find a middle ground',
    ],
    key_phrases: [
      { phrase: 'I was hoping we could come closer to…' },
      { phrase: 'What if we…' },
      { phrase: 'That works for me.' },
    ],
  },
  {
    slug: 'networking-event',
    category: 'business',
    difficulty: 3,
    estimated_minutes: 5,
    xp_reward: 60,
    title_en: 'Networking at an event',
    title_ko: '네트워킹 이벤트',
    title_zh: '社交活动',
    description_en: 'Start a conversation with someone new.',
    scene_en: "You're at an industry mixer.",
    user_role_en: 'A professional looking to expand your network.',
    tutor_role_en: 'A stranger at the event.',
    objectives_en: [
      'Break the ice',
      'Find common ground',
      'Exchange contacts',
      'Close politely',
    ],
    key_phrases: [
      { phrase: 'How did you get into this field?' },
      { phrase: "I'd love to stay in touch." },
      { phrase: 'Mind if I get your email?' },
    ],
  },
  // ── Social (5) ────────────────────────────────────────────
  {
    slug: 'greeting-strangers',
    category: 'social',
    difficulty: 1,
    estimated_minutes: 4,
    xp_reward: 40,
    title_en: 'Greeting someone new',
    title_ko: '처음 만난 사람과 인사',
    title_zh: '与陌生人打招呼',
    description_en: 'Friendly small talk.',
    scene_en:
      "You're at a coffee shop and someone is waiting in line with you.",
    user_role_en: 'A friendly customer.',
    tutor_role_en: 'Another customer.',
    objectives_en: [
      'Start a polite chat',
      'Comment on something nearby',
      'Listen actively',
      'End graciously',
    ],
    key_phrases: [
      { phrase: "Quite a queue today, isn't it?" },
      { phrase: 'Have you tried the…' },
      { phrase: 'Nice meeting you!' },
    ],
  },
  {
    slug: 'house-party',
    category: 'social',
    difficulty: 2,
    estimated_minutes: 5,
    xp_reward: 50,
    title_en: 'At a house party',
    title_ko: '홈 파티에서',
    title_zh: '家庭聚会',
    description_en: 'Mingle and meet new people.',
    scene_en: "You're at a friend's casual party.",
    user_role_en: 'A guest.',
    tutor_role_en: "Another guest you haven't met.",
    objectives_en: [
      'Introduce yourself',
      'Ask about how they know the host',
      'Share a fun fact',
      'Move on politely',
    ],
    key_phrases: [
      { phrase: 'How do you know…' },
      { phrase: 'Have you tried the…' },
      { phrase: "I'm going to grab another drink." },
    ],
  },
  {
    slug: 'first-date',
    category: 'social',
    difficulty: 3,
    estimated_minutes: 6,
    xp_reward: 60,
    title_en: 'On a first date',
    title_ko: '첫 데이트',
    title_zh: '初次约会',
    description_en: 'Get to know someone over coffee.',
    scene_en: "You're on a coffee date with someone you matched with online.",
    user_role_en: 'You, on a date.',
    tutor_role_en: 'Your date.',
    objectives_en: [
      'Break the ice',
      'Ask about interests',
      'Share about yourself',
      'Suggest a next step',
    ],
    key_phrases: [
      { phrase: 'So, what do you do for fun?' },
      { phrase: 'I really enjoyed talking with you.' },
      { phrase: 'Would you want to do this again?' },
    ],
  },
  {
    slug: 'sports-talk',
    category: 'social',
    difficulty: 2,
    estimated_minutes: 5,
    xp_reward: 50,
    title_en: 'Talking about sports',
    title_ko: '스포츠 이야기',
    title_zh: '聊体育',
    description_en: 'Casual chat about a favorite sport.',
    scene_en: "You're watching a match at a sports bar.",
    user_role_en: 'A fan.',
    tutor_role_en: 'Another fan.',
    objectives_en: [
      'Ask about their team',
      'Share an opinion',
      'Predict the result',
      'Suggest watching another match',
    ],
    key_phrases: [
      { phrase: 'Who are you rooting for?' },
      { phrase: "I think they'll win because…" },
      { phrase: 'Want to grab another?' },
    ],
  },
  {
    slug: 'hobby-discussion',
    category: 'social',
    difficulty: 2,
    estimated_minutes: 5,
    xp_reward: 50,
    title_en: 'Sharing your hobby',
    title_ko: '취미 공유',
    title_zh: '分享爱好',
    description_en: 'Explain a hobby you love.',
    scene_en: 'A new acquaintance asks about your weekends.',
    user_role_en: 'You.',
    tutor_role_en: 'Someone curious about your interests.',
    objectives_en: [
      'Name your hobby',
      'Explain why you love it',
      'Ask about theirs',
      'Find common ground',
    ],
    key_phrases: [
      { phrase: "I've been really into…" },
      { phrase: 'It started when…' },
      { phrase: 'What do you do for fun?' },
    ],
  },
  // ── Daily Life (5) ────────────────────────────────────────
  {
    slug: 'grocery-shopping',
    category: 'daily',
    difficulty: 1,
    estimated_minutes: 4,
    xp_reward: 40,
    title_en: 'Grocery shopping',
    title_ko: '식료품 쇼핑',
    title_zh: '购买杂货',
    description_en: 'Buy groceries and ask about items.',
    scene_en: "You're at the supermarket.",
    user_role_en: 'A shopper.',
    tutor_role_en: 'A store employee.',
    objectives_en: [
      'Ask where items are',
      'Compare options',
      'Check prices',
      'Pay at checkout',
    ],
    key_phrases: [
      { phrase: 'Excuse me, where can I find…' },
      { phrase: 'Is this on sale?' },
      { phrase: 'Cash or card?' },
    ],
  },
  {
    slug: 'doctor-visit',
    category: 'daily',
    difficulty: 3,
    estimated_minutes: 6,
    xp_reward: 60,
    title_en: 'Visiting the doctor',
    title_ko: '병원 진료',
    title_zh: '看医生',
    description_en: 'Describe symptoms and discuss treatment.',
    scene_en: "You're at a clinic for a check-up.",
    user_role_en: 'A patient.',
    tutor_role_en: 'A doctor.',
    objectives_en: [
      'Describe symptoms',
      'Answer health questions',
      'Ask about treatment',
      'Schedule a follow-up',
    ],
    key_phrases: [
      { phrase: "I've been feeling…" },
      { phrase: 'How long has this been going on?' },
      { phrase: 'Do I need a follow-up?' },
    ],
  },
  {
    slug: 'bank-account',
    category: 'daily',
    difficulty: 3,
    estimated_minutes: 6,
    xp_reward: 60,
    title_en: 'Opening a bank account',
    title_ko: '은행 계좌 개설',
    title_zh: '开设银行账户',
    description_en: 'Ask about account types and complete paperwork.',
    scene_en: "You're at a bank branch.",
    user_role_en: 'A new customer.',
    tutor_role_en: 'A bank teller.',
    objectives_en: [
      'Explain what you want to open',
      'Ask about fees',
      'Provide ID',
      'Confirm details',
    ],
    key_phrases: [
      { phrase: "I'd like to open a checking account." },
      { phrase: 'What are the monthly fees?' },
      { phrase: 'Is there a minimum balance?' },
    ],
  },
  {
    slug: 'asking-directions',
    category: 'daily',
    difficulty: 1,
    estimated_minutes: 4,
    xp_reward: 40,
    title_en: 'Asking for directions',
    title_ko: '길 묻기',
    title_zh: '问路',
    description_en: 'Find your way in an unfamiliar place.',
    scene_en: "You're lost in a downtown area.",
    user_role_en: 'A tourist.',
    tutor_role_en: 'A friendly local.',
    objectives_en: [
      'Politely interrupt',
      'Ask for directions',
      'Confirm landmarks',
      'Thank the person',
    ],
    key_phrases: [
      { phrase: 'Excuse me, could you help me?' },
      { phrase: 'Is it far from here?' },
      { phrase: 'Thanks so much!' },
    ],
  },
  {
    slug: 'phone-call',
    category: 'daily',
    difficulty: 2,
    estimated_minutes: 5,
    xp_reward: 50,
    title_en: 'A phone call to customer service',
    title_ko: '고객 서비스 전화',
    title_zh: '客服电话',
    description_en: 'Solve a problem over the phone.',
    scene_en: "You're calling to ask about a delayed delivery.",
    user_role_en: 'A customer.',
    tutor_role_en: 'A customer-service agent.',
    objectives_en: [
      'Explain the issue',
      'Provide order details',
      'Ask for a resolution',
      'Confirm next steps',
    ],
    key_phrases: [
      { phrase: "I'm calling about…" },
      { phrase: 'My order number is…' },
      { phrase: 'When can I expect…' },
    ],
  },
];

export async function seedScenarios(ds: DataSource): Promise<void> {
  const repo = ds.getRepository(ScenarioEntity);

  // vl_scenarios.category_id is NOT NULL with a FK to vl_categories.
  // The categories rows were seeded by migration 1780400000000; we
  // just need to look them up by slug and stamp the id on each
  // scenario. Build the slug -> id map once up front rather than
  // re-querying inside the loop.
  const categoryRows = await ds
    .getRepository(CategoryEntity)
    .find({ select: ['id', 'slug'] });
  const categoryIdBySlug = new Map(categoryRows.map((c) => [c.slug, c.id]));

  let order = 0;
  for (const s of SCENARIOS) {
    const categoryId = categoryIdBySlug.get(s.category);
    if (!categoryId) {
      throw new Error(
        `seedScenarios: vl_categories has no row for slug "${s.category}" ` +
          `(scenario "${s.slug}"). Run migrations first, then re-seed.`,
      );
    }
    const data = {
      slug: s.slug,
      category: s.category,
      category_id: categoryId,
      difficulty: s.difficulty,
      title: { en: s.title_en, ko: s.title_ko, zh: s.title_zh },
      description: { en: s.description_en },
      scene_description: { en: s.scene_en },
      user_role: { en: s.user_role_en },
      tutor_role: { en: s.tutor_role_en },
      objectives: s.objectives_en.map((o) => ({ en: o })),
      key_phrases: s.key_phrases,
      estimated_minutes: s.estimated_minutes,
      xp_reward: s.xp_reward,
      order_index: order++,
      status: 'published' as const,
      published_at: new Date(),
    };
    const existing = await repo.findOne({ where: { slug: s.slug } });
    if (existing) {
      Object.assign(existing, data);
      await repo.save(existing);
    } else {
      await repo.save(repo.create(data));
    }
  }
}

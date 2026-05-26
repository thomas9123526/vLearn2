# vLearn2 Scenario Index

All 20 conversation scenarios used in the AI prompt system.

---

## Master Table

| Slug | Category | CEFR | XP | Minutes | Title (EN) | Title (KO) | Title (ZH) |
|------|----------|------|----|---------|-----------|-----------|-----------|
| airport-check-in | travel | A2 | 50 | 5 | Airport check-in | 공항 체크인 | 机场值机 |
| hotel-reservation | travel | A2 | 50 | 5 | Hotel reservation | 호텔 예약 | 酒店预订 |
| restaurant-ordering | travel | A1 | 40 | 5 | Ordering at a restaurant | 레스토랑 주문 | 餐厅点餐 |
| shopping-clothes | travel | A2 | 50 | 5 | Shopping for clothes | 옷 쇼핑 | 购买衣物 |
| taxi-ride | travel | A1 | 40 | 4 | Taking a taxi | 택시 타기 | 乘坐出租车 |
| business-meeting-intro | business | B1 | 60 | 6 | Introducing yourself at a meeting | 회의에서 자기소개 | 会议自我介绍 |
| email-followup | business | B1 | 60 | 5 | Writing a follow-up email | 후속 이메일 작성 | 撰写跟进邮件 |
| business-presentation | business | B2 | 70 | 7 | Giving a short presentation | 짧은 발표하기 | 做简短报告 |
| price-negotiation | business | B2 | 70 | 6 | Negotiating a price | 가격 협상 | 价格谈判 |
| networking-event | business | B1 | 60 | 5 | Networking at an event | 행사에서 네트워킹 | 活动中社交 |
| greeting-strangers | social | A1 | 40 | 4 | Greeting someone new | 새로운 사람 인사하기 | 与陌生人打招呼 |
| house-party | social | A2 | 50 | 5 | At a house party | 하우스 파티에서 | 在家庭聚会上 |
| first-date | social | B1 | 60 | 6 | On a first date | 첫 번째 데이트 | 第一次约会 |
| sports-talk | social | A2 | 50 | 5 | Talking about sports | 스포츠 이야기 | 聊体育话题 |
| hobby-discussion | social | A2 | 50 | 5 | Sharing your hobby | 취미 이야기 | 分享爱好 |
| grocery-shopping | daily | A1 | 40 | 4 | Grocery shopping | 식료품 쇼핑 | 杂货购物 |
| doctor-visit | daily | B1 | 60 | 6 | Visiting the doctor | 병원 방문 | 看医生 |
| bank-account | daily | B1 | 60 | 6 | Opening a bank account | 은행 계좌 개설 | 开设银行账户 |
| asking-directions | daily | A1 | 40 | 4 | Asking for directions | 길 묻기 | 问路 |
| phone-call | daily | A2 | 50 | 5 | A phone call to customer service | 고객 서비스 전화 | 致电客服 |

---

## Full Database Row Dump

### 1. airport-check-in

| Field | Value |
|-------|-------|
| slug | airport-check-in |
| category | travel |
| difficulty / CEFR | A2 |
| estimated_minutes | 5 |
| xp_reward | 50 |
| title_en | Airport check-in |
| title_ko | 공항 체크인 |
| title_zh | 机场值机 |
| description | Practice checking in at an international airport. |
| scene_en | You're at an airline check-in desk for an international flight. |
| user_role_en | A traveler with luggage to check in. |
| tutor_role_en | A friendly airline agent. |
| objectives_en | Greet politely, Check bags, Ask about your seat, Get a boarding pass |
| key_phrases | "I'd like to check in for flight…", "I have one bag to check.", "Do you have an aisle seat available?" |
| status | active |

---

### 2. hotel-reservation

| Field | Value |
|-------|-------|
| slug | hotel-reservation |
| category | travel |
| difficulty / CEFR | A2 |
| estimated_minutes | 5 |
| xp_reward | 50 |
| title_en | Hotel reservation |
| title_ko | 호텔 예약 |
| title_zh | 酒店预订 |
| description | Practice making a hotel reservation over the phone. |
| scene_en | You're calling a hotel to reserve a room. |
| user_role_en | A guest planning a trip. |
| tutor_role_en | A hotel receptionist. |
| objectives_en | Ask about availability, Choose a room type, Confirm price, Make the booking |
| key_phrases | "I'd like to book a room for two nights.", "Does the room come with breakfast?", "Is there free Wi-Fi?" |
| status | active |

---

### 3. restaurant-ordering

| Field | Value |
|-------|-------|
| slug | restaurant-ordering |
| category | travel |
| difficulty / CEFR | A1 |
| estimated_minutes | 5 |
| xp_reward | 40 |
| title_en | Ordering at a restaurant |
| title_ko | 레스토랑 주문 |
| title_zh | 餐厅点餐 |
| description | Practice ordering food and interacting with restaurant staff. |
| scene_en | You're at a casual restaurant looking at the menu. |
| user_role_en | A diner ready to order. |
| tutor_role_en | A friendly server. |
| objectives_en | Ask for recommendations, Order a meal, Request modifications, Ask for the check |
| key_phrases | "What do you recommend?", "I'll have the…", "Could I have the check, please?" |
| status | active |

---

### 4. shopping-clothes

| Field | Value |
|-------|-------|
| slug | shopping-clothes |
| category | travel |
| difficulty / CEFR | A2 |
| estimated_minutes | 5 |
| xp_reward | 50 |
| title_en | Shopping for clothes |
| title_ko | 옷 쇼핑 |
| title_zh | 购买衣物 |
| description | Practice shopping for clothing with store staff. |
| scene_en | You're in a clothing store browsing. |
| user_role_en | A shopper looking for an outfit. |
| tutor_role_en | A store clerk. |
| objectives_en | Ask about sizes, Try clothes on, Compare prices, Make a purchase |
| key_phrases | "Do you have this in a larger size?", "Can I try it on?", "How much is it?" |
| status | active |

---

### 5. taxi-ride

| Field | Value |
|-------|-------|
| slug | taxi-ride |
| category | travel |
| difficulty / CEFR | A1 |
| estimated_minutes | 4 |
| xp_reward | 40 |
| title_en | Taking a taxi |
| title_ko | 택시 타기 |
| title_zh | 乘坐出租车 |
| description | Practice giving directions and paying for a taxi ride. |
| scene_en | You're hailing a taxi in a big city. |
| user_role_en | A passenger heading to a hotel. |
| tutor_role_en | A taxi driver. |
| objectives_en | State your destination, Estimate the fare, Give directions if needed, Pay and tip |
| key_phrases | "Could you take me to…", "How long will it take?", "Keep the change." |
| status | active |

---

### 6. business-meeting-intro

| Field | Value |
|-------|-------|
| slug | business-meeting-intro |
| category | business |
| difficulty / CEFR | B1 |
| estimated_minutes | 6 |
| xp_reward | 60 |
| title_en | Introducing yourself at a meeting |
| title_ko | 회의에서 자기소개 |
| title_zh | 会议自我介绍 |
| description | Practice professional self-introductions in a work meeting. |
| scene_en | You're at a kickoff meeting with new colleagues. |
| user_role_en | A new team member. |
| tutor_role_en | A senior colleague. |
| objectives_en | Introduce yourself, State your role, Mention your background, Ask about their work |
| key_phrases | "Pleased to meet you.", "I'll be working on…", "What's your focus area?" |
| status | active |

---

### 7. email-followup

| Field | Value |
|-------|-------|
| slug | email-followup |
| category | business |
| difficulty / CEFR | B1 |
| estimated_minutes | 5 |
| xp_reward | 60 |
| title_en | Writing a follow-up email |
| title_ko | 후속 이메일 작성 |
| title_zh | 撰写跟进邮件 |
| description | Practice professional email follow-up communication with a coach. |
| scene_en | You need to follow up on a proposal you sent last week. |
| user_role_en | An account manager. |
| tutor_role_en | A communication coach. |
| objectives_en | Reference the previous message, Be polite but direct, Suggest next steps, Close professionally |
| key_phrases | "I wanted to follow up on…", "Let me know if you have any questions.", "Looking forward to your reply." |
| status | active |

---

### 8. business-presentation

| Field | Value |
|-------|-------|
| slug | business-presentation |
| category | business |
| difficulty / CEFR | B2 |
| estimated_minutes | 7 |
| xp_reward | 70 |
| title_en | Giving a short presentation |
| title_ko | 짧은 발표하기 |
| title_zh | 做简短报告 |
| description | Practice delivering a concise business update presentation. |
| scene_en | You're presenting a Q1 update. |
| user_role_en | A team lead. |
| tutor_role_en | A stakeholder. |
| objectives_en | Open with context, Share key results, Discuss next steps, Take questions |
| key_phrases | "Today I'd like to walk you through…", "The key takeaway is…", "I'd love your feedback." |
| status | active |

---

### 9. price-negotiation

| Field | Value |
|-------|-------|
| slug | price-negotiation |
| category | business |
| difficulty / CEFR | B2 |
| estimated_minutes | 6 |
| xp_reward | 70 |
| title_en | Negotiating a price |
| title_ko | 가격 협상 |
| title_zh | 价格谈判 |
| description | Practice negotiating prices and terms with a vendor. |
| scene_en | You're negotiating with a vendor. |
| user_role_en | A buyer. |
| tutor_role_en | A seller. |
| objectives_en | Anchor your offer, Justify your number, Listen actively, Find a middle ground |
| key_phrases | "I was hoping we could come closer to…", "What if we…", "That works for me." |
| status | active |

---

### 10. networking-event

| Field | Value |
|-------|-------|
| slug | networking-event |
| category | business |
| difficulty / CEFR | B1 |
| estimated_minutes | 5 |
| xp_reward | 60 |
| title_en | Networking at an event |
| title_ko | 행사에서 네트워킹 |
| title_zh | 活动中社交 |
| description | Practice professional small talk and exchanging contacts at a networking mixer. |
| scene_en | You're at an industry mixer. |
| user_role_en | A professional looking to expand your network. |
| tutor_role_en | A stranger at the event. |
| objectives_en | Break the ice, Find common ground, Exchange contacts, Close politely |
| key_phrases | "How did you get into this field?", "I'd love to stay in touch.", "Mind if I get your email?" |
| status | active |

---

### 11. greeting-strangers

| Field | Value |
|-------|-------|
| slug | greeting-strangers |
| category | social |
| difficulty / CEFR | A1 |
| estimated_minutes | 4 |
| xp_reward | 40 |
| title_en | Greeting someone new |
| title_ko | 새로운 사람 인사하기 |
| title_zh | 与陌生人打招呼 |
| description | Practice casual small talk with a stranger in a public setting. |
| scene_en | You're at a coffee shop and someone is waiting in line with you. |
| user_role_en | A friendly customer. |
| tutor_role_en | Another customer. |
| objectives_en | Start a polite chat, Comment on something nearby, Listen actively, End graciously |
| key_phrases | "Quite a queue today, isn't it?", "Have you tried the…", "Nice meeting you!" |
| status | active |

---

### 12. house-party

| Field | Value |
|-------|-------|
| slug | house-party |
| category | social |
| difficulty / CEFR | A2 |
| estimated_minutes | 5 |
| xp_reward | 50 |
| title_en | At a house party |
| title_ko | 하우스 파티에서 |
| title_zh | 在家庭聚会上 |
| description | Practice casual social introductions and conversations at a party. |
| scene_en | You're at a friend's casual party. |
| user_role_en | A guest. |
| tutor_role_en | Another guest you haven't met. |
| objectives_en | Introduce yourself, Ask about how they know the host, Share a fun fact, Move on politely |
| key_phrases | "How do you know…", "Have you tried the…", "I'm going to grab another drink." |
| status | active |

---

### 13. first-date

| Field | Value |
|-------|-------|
| slug | first-date |
| category | social |
| difficulty / CEFR | B1 |
| estimated_minutes | 6 |
| xp_reward | 60 |
| title_en | On a first date |
| title_ko | 첫 번째 데이트 |
| title_zh | 第一次约会 |
| description | Practice light, friendly conversation on a first date. |
| scene_en | You're on a coffee date with someone you matched with online. |
| user_role_en | You, on a date. |
| tutor_role_en | Your date. |
| objectives_en | Break the ice, Ask about interests, Share about yourself, Suggest a next step |
| key_phrases | "So, what do you do for fun?", "I really enjoyed talking with you.", "Would you want to do this again?" |
| status | active |

---

### 14. sports-talk

| Field | Value |
|-------|-------|
| slug | sports-talk |
| category | social |
| difficulty / CEFR | A2 |
| estimated_minutes | 5 |
| xp_reward | 50 |
| title_en | Talking about sports |
| title_ko | 스포츠 이야기 |
| title_zh | 聊体育话题 |
| description | Practice casual sports conversation at a sports bar. |
| scene_en | You're watching a match at a sports bar. |
| user_role_en | A fan. |
| tutor_role_en | Another fan. |
| objectives_en | Ask about their team, Share an opinion, Predict the result, Suggest watching another match |
| key_phrases | "Who are you rooting for?", "I think they'll win because…", "Want to grab another?" |
| status | active |

---

### 15. hobby-discussion

| Field | Value |
|-------|-------|
| slug | hobby-discussion |
| category | social |
| difficulty / CEFR | A2 |
| estimated_minutes | 5 |
| xp_reward | 50 |
| title_en | Sharing your hobby |
| title_ko | 취미 이야기 |
| title_zh | 分享爱好 |
| description | Practice talking about personal hobbies and interests with a new acquaintance. |
| scene_en | A new acquaintance asks about your weekends. |
| user_role_en | You. |
| tutor_role_en | Someone curious about your interests. |
| objectives_en | Name your hobby, Explain why you love it, Ask about theirs, Find common ground |
| key_phrases | "I've been really into…", "It started when…", "What do you do for fun?" |
| status | active |

---

### 16. grocery-shopping

| Field | Value |
|-------|-------|
| slug | grocery-shopping |
| category | daily |
| difficulty / CEFR | A1 |
| estimated_minutes | 4 |
| xp_reward | 40 |
| title_en | Grocery shopping |
| title_ko | 식료품 쇼핑 |
| title_zh | 杂货购物 |
| description | Practice asking for help in a supermarket and paying at checkout. |
| scene_en | You're at the supermarket. |
| user_role_en | A shopper. |
| tutor_role_en | A store employee. |
| objectives_en | Ask where items are, Compare options, Check prices, Pay at checkout |
| key_phrases | "Excuse me, where can I find…", "Is this on sale?", "Cash or card?" |
| status | active |

---

### 17. doctor-visit

| Field | Value |
|-------|-------|
| slug | doctor-visit |
| category | daily |
| difficulty / CEFR | B1 |
| estimated_minutes | 6 |
| xp_reward | 60 |
| title_en | Visiting the doctor |
| title_ko | 병원 방문 |
| title_zh | 看医生 |
| description | Practice describing symptoms and discussing treatment with a doctor. |
| scene_en | You're at a clinic for a check-up. |
| user_role_en | A patient. |
| tutor_role_en | A doctor. |
| objectives_en | Describe symptoms, Answer health questions, Ask about treatment, Schedule a follow-up |
| key_phrases | "I've been feeling…", "How long has this been going on?", "Do I need a follow-up?" |
| status | active |

---

### 18. bank-account

| Field | Value |
|-------|-------|
| slug | bank-account |
| category | daily |
| difficulty / CEFR | B1 |
| estimated_minutes | 6 |
| xp_reward | 60 |
| title_en | Opening a bank account |
| title_ko | 은행 계좌 개설 |
| title_zh | 开设银行账户 |
| description | Practice opening a bank account and asking about fees at a bank branch. |
| scene_en | You're at a bank branch. |
| user_role_en | A new customer. |
| tutor_role_en | A bank teller. |
| objectives_en | Explain what you want to open, Ask about fees, Provide ID, Confirm details |
| key_phrases | "I'd like to open a checking account.", "What are the monthly fees?", "Is there a minimum balance?" |
| status | active |

---

### 19. asking-directions

| Field | Value |
|-------|-------|
| slug | asking-directions |
| category | daily |
| difficulty / CEFR | A1 |
| estimated_minutes | 4 |
| xp_reward | 40 |
| title_en | Asking for directions |
| title_ko | 길 묻기 |
| title_zh | 问路 |
| description | Practice politely asking a local for directions in an unfamiliar city. |
| scene_en | You're lost in a downtown area. |
| user_role_en | A tourist. |
| tutor_role_en | A friendly local. |
| objectives_en | Politely interrupt, Ask for directions, Confirm landmarks, Thank the person |
| key_phrases | "Excuse me, could you help me?", "Is it far from here?", "Thanks so much!" |
| status | active |

---

### 20. phone-call

| Field | Value |
|-------|-------|
| slug | phone-call |
| category | daily |
| difficulty / CEFR | A2 |
| estimated_minutes | 5 |
| xp_reward | 50 |
| title_en | A phone call to customer service |
| title_ko | 고객 서비스 전화 |
| title_zh | 致电客服 |
| description | Practice calling customer service to resolve an issue with a delayed delivery. |
| scene_en | You're calling to ask about a delayed delivery. |
| user_role_en | A customer. |
| tutor_role_en | A customer-service agent. |
| objectives_en | Explain the issue, Provide order details, Ask for a resolution, Confirm next steps |
| key_phrases | "I'm calling about…", "My order number is…", "When can I expect…" |
| status | active |

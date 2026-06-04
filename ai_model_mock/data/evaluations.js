/**
 * Pre-canned evaluation responses for the AI mock server.
 * Sourced from A1_passed.json quality-pipeline-passed evaluation samples.
 *
 * Each entry: { id, cefrLevel, turn0Snippet, response }
 * - turn0Snippet: first USER turn text, used as match key
 * - response: clean JSON string (EvaluationOutput schema, no think block)
 */

'use strict';

const EVALUATIONS = [
  // ── A1 — shopping_and_services ────────────────────────────────────────────
  {
    id: 'eval_sft_a9f212b991c9_v1',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello. I am Li. Where is this market in Harbin?',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 3, accuracy: 3, vocabulary: 4, interaction: 4, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello. I am Li. Where is this market in Harbin?',
          issue: 'The question is a bit unclear — the market location is already known from the scenario.',
          correction: 'Hello. I am Li. Is this the market near Erhai Street?',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 2,
          user_text: 'Is it cheap? How much is it?',
          issue: 'Could be more specific about the item being asked about.',
          correction: 'Is it cheap? How much is the red scarf?',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 4,
          user_text: 'I have cash. I give you fifty yuan now.',
          issue: 'Tense is awkward — present simple used where present continuous or future is more natural.',
          correction: 'I have cash. I will give you fifty yuan now.',
          level: 'A1',
          severity: 'moderate',
        },
        {
          turn_index: 6,
          user_text: 'You are right. Bye, shop owner.',
          issue: 'Informal closing. Could use a more complete goodbye phrase.',
          correction: 'You are right. Goodbye, shop owner. Have a good day.',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Uses simple and clear sentences throughout.',
        'Stays focused on buying gifts and payment.',
        'Appropriate basic vocabulary for the A1 level.',
        'Interacts politely with the tutor.',
      ],
      suggested_practice:
        'Practice asking about prices and payment methods at a Chinese market. For example, ask about the price of a traditional Harbin ice sculpture souvenir or how to pay with WeChat.',
    }),
  },

  // ── A1 — family_and_relationships (visiting grandparents) ─────────────────
  {
    id: 'eval_sft_c4eb7dc5a1e7_v1',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello Grandma. Welcome home.',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 3, accuracy: 4, vocabulary: 3, interaction: 4, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello Grandma. Welcome home.',
          issue: 'Sentence is simple but slightly unnatural — the grandma is already home.',
          correction: 'Hello Grandma. I am happy to see you.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 4,
          user_text: 'Yes, please. Do you have dumplings?',
          issue: 'Good question, but could be more specific.',
          correction: 'Yes, please. Do you have pork dumplings today?',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 7,
          user_text: 'Oh, Beijing is far. I want to see Beijing.',
          issue: 'Could be more detailed to extend the conversation.',
          correction: 'Oh, Beijing is far. I want to visit Beijing one day.',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Clear and simple sentences easy to understand.',
        'Good use of basic vocabulary related to food and family.',
        'Natural interaction with the grandmother role.',
        'Consistent engagement with the assigned topic.',
      ],
      suggested_practice:
        'Practice asking more specific questions about Chinese foods like dumplings and jasmine tea. Also try talking about plans to visit Chinese cities like Shanghai or Guangzhou.',
    }),
  },

  // ── A1 — nature_and_weather (flowers in Chongqing) ────────────────────────
  {
    id: 'eval_sft_bd987712c5d2',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello, Mr. Li. Where are the flowers today?',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 4, accuracy: 3, vocabulary: 3, interaction: 4, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello, Mr. Li. Where are the flowers today?',
          issue: 'Article usage is correct; the question is clear.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 2,
          user_text: 'I like the orange flowers. They look like oranges.',
          issue: 'Repetitive use of the word "orange" could be varied.',
          correction: 'I like the orange flowers. They are the same colour as fruit.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 5,
          user_text: 'I saw the big tree. It was very green.',
          issue: 'Incorrect tense for a present observation — past tense used for something visible now.',
          correction: 'I can see the big tree. It is very green.',
          level: 'A1',
          severity: 'moderate',
        },
      ],
      strengths: [
        'Clear and polite communication throughout.',
        'Good topic adherence — stays on flowers, garden, and weather.',
        'Appropriate use of basic adjectives for the level.',
      ],
      suggested_practice:
        "Practice describing different flowers in Wanda Square using simple sentences like 'This flower is red' or 'The sun is warm today'.",
    }),
  },

  // ── A1 — work_and_education (university, East Lake) ───────────────────────
  {
    id: 'eval_sft_80806e8d613e',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello, Lin. Where are we sitting today?',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 4, accuracy: 5, vocabulary: 3, interaction: 4, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello, Lin. Where are we sitting today?',
          issue: 'Simple greeting and question — good for A1.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 2,
          user_text: 'I want to finish my homework. Do I have to read?',
          issue: 'Simple question about homework — appropriate for A1.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 5,
          user_text: 'I can go to the library later. Is it far?',
          issue: 'Simple question about location — good.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Stays on topic throughout the conversation.',
        'Uses authentic Chinese names and settings.',
        'Asks relevant questions about homework and the library.',
      ],
      suggested_practice:
        "Practice asking more questions about the university class in Hangzhou, such as 'What time does the class start?' or 'Where is the classroom in the university?'",
    }),
  },

  // ── A1 — family_and_relationships (redirect — western culture) ─────────────
  {
    id: 'eval_redirect_western_culture_cb0f4b8b3f86_v1',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello, Grandma. I am calling you to say hello.',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 4, accuracy: 4, vocabulary: 3, interaction: 4, topic_adherence: 3 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello, Grandma. I am calling you to say hello.',
          issue: 'Slightly formal phrasing for a casual phone call.',
          correction: 'Hello, Grandma. I am calling to say hello.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 2,
          user_text: 'Yes, we ate at a small restaurant in Wujiang. I ate some soup.',
          issue: "Repetition of 'ate' — could be varied with 'had'.",
          correction: 'Yes, we ate at a small restaurant in Wujiang. I had some soup.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 5,
          user_text: 'I was wondering if you like American movies from Hollywood.',
          issue: 'Topic drifts to American/Hollywood content instead of Chinese context.',
          correction: 'I was wondering if you like Chinese films.',
          level: 'A1',
          severity: 'moderate',
        },
        {
          turn_index: 9,
          user_text: 'Thank you, Grandma. I love playing sports with my friends.',
          issue: 'Good closing but could include a question to keep the conversation going.',
          correction: 'Thank you, Grandma. I love playing sports with my friends. Do you exercise too?',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Simple and clear sentences suitable for A1 level.',
        "Good use of basic connectors like 'and', 'but', 'yes'.",
        'Appropriate vocabulary for the topic of family and daily life.',
      ],
      suggested_practice:
        "Practice asking simple questions about your daily life in Suzhou, such as 'Do you like tea?' or 'What food do you eat for dinner?' to keep the conversation going naturally.",
    }),
  },

  // ── A1 — family_and_relationships (visiting grandparents variant) ──────────
  {
    id: 'eval_sft_dbda7ccb8822',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello Grandmother. I am Zhang. I am here in Suzhou.',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 5, accuracy: 5, vocabulary: 5, interaction: 5, topic_adherence: 5 },
      specific_feedback: [],
      strengths: [
        'Simple sentences with clear meaning throughout.',
        'Good use of present and past tenses.',
        'Natural engagement with visiting, food, and gift subtopics.',
      ],
      suggested_practice:
        'Practice ordering Chinese food items like dumplings or noodles in Suzhou, and describe why you like them.',
    }),
  },

  // ── A1 — work_and_education (university, West Lake variant) ───────────────
  {
    id: 'eval_sft_80806e8d613e_v1',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello. I am Yuan Yuan. I am at West Lake today.',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 5, accuracy: 5, vocabulary: 5, interaction: 5, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 1,
          user_text: 'Yes. I want to finish my English book homework.',
          issue: 'Noun stacking is slightly awkward.',
          correction: 'Yes. I want to finish my homework for my English book.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 2,
          user_text: 'The library is very near the lake?',
          issue: 'Statement used as a question — intonation only, no inversion.',
          correction: 'Is the library very near the lake?',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 6,
          user_text: 'Yes. I want hot milk tea with sugar.',
          issue: 'No issue — clear and natural request.',
          correction: '',
          level: 'A1',
          severity: 'none',
        },
      ],
      strengths: [
        'Uses simple sentence structures effectively.',
        'Maintains the topic of studying in Hangzhou throughout.',
      ],
      suggested_practice:
        'Practice describing your daily routine at a university in Hangzhou, such as going to the library or buying milk tea near West Lake.',
    }),
  },

  // ── A1 — nature_and_weather (flowers, Chongqing, variant) ─────────────────
  {
    id: 'eval_sft_bd987712c5d2_v1',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello. Where is the flower garden in Chongqing?',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 4, accuracy: 5, vocabulary: 3, interaction: 5, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello. Where is the flower garden in Chongqing?',
          issue: 'Basic question structure is correct.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 1,
          user_text: 'Is it sunny today?',
          issue: 'Simple present tense used correctly.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 3,
          user_text: 'How many kinds of flowers are there?',
          issue: 'Question structure is clear and well-formed.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Clear and simple sentence structures suitable for A1.',
        'Good topic adherence regarding flowers and the garden.',
        'Polite and cooperative interaction with the tutor.',
      ],
      suggested_practice:
        "Practice describing different flowers found in parks in Chongqing or Sichuan using simple sentences like 'The red flowers are beautiful' or 'The sun is hot in summer'.",
    }),
  },

  // ── A1 — family_and_relationships (violence/harm redirect) ────────────────
  {
    id: 'eval_redirect_violence_harm_a6fc38173285',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello cousin. It is Saturday. My mother is cooking today.',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 5, accuracy: 5, vocabulary: 5, interaction: 5, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello cousin. It is Saturday. My mother is cooking today.',
          issue: 'Good greeting and scene-setting.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 2,
          user_text: "Do you like Zongzi? Some people say they are dangerous.",
          issue: "'Dangerous' is slightly advanced vocabulary for A1.",
          correction: "Do you like Zongzi? Some people say they are hard to eat.",
          level: 'A2',
          severity: 'minor',
        },
        {
          turn_index: 4,
          user_text: 'I have not been there in a long time. It is nice to see the trees.',
          issue: "Present perfect 'have not been' is slightly above A1.",
          correction: 'I did not go there for a long time. It is nice to see the trees.',
          level: 'A2',
          severity: 'minor',
        },
      ],
      strengths: [
        'Clear and simple sentences.',
        'Stays on topic about family and food.',
        'Uses correct food names like Zongzi and dumplings.',
      ],
      suggested_practice:
        'Talk about a family meal in Suzhou or a festival like the Dragon Boat Festival using simple sentences.',
    }),
  },

  // ── A1 — travel_and_transit (bus, Taiyuan) ────────────────────────────────
  {
    id: 'eval_sft_70979d9ec069_v1',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello. Where is the bus stop in Taiyuan?',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 4, accuracy: 4, vocabulary: 3, interaction: 4, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello. Where is the bus stop in Taiyuan?',
          issue: 'Simple sentence structure — appropriate for A1.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 4,
          user_text: 'I have one hundred yuan. Is that enough?',
          issue: "Writing out 'one hundred' is fine, but numerals are more natural in speech.",
          correction: 'I have 100 yuan. Is that enough?',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 6,
          user_text: 'Good idea. The weather is sunny today.',
          issue: 'Could add location for more context.',
          correction: 'Good idea. The weather is sunny today in Taiyuan.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 7,
          user_text: 'I will drink water. Thank you for the ticket.',
          issue: 'Clear and polite closing — no issue.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Clear and polite questions about travel and transit.',
        'Appropriate use of basic vocabulary for A1.',
        'Good topic adherence throughout.',
      ],
      suggested_practice:
        "Practice asking more specific questions about the bus route in Taiyuan, such as 'How long does it take to reach the city centre?' or 'What is the name of the square where the bus stops?'",
    }),
  },

  // ── A1 — hobbies_and_leisure (chess, Kunming) ─────────────────────────────
  {
    id: 'eval_sft_b0e100adce6e_v1',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello. My name is Wang. Where are we now?',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 5, accuracy: 5, vocabulary: 5, interaction: 5, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello. My name is Wang. Where are we now?',
          issue: 'Good introduction and question.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 2,
          user_text: 'Me too. I played with my friend yesterday.',
          issue: "'Me too' is slightly informal; 'I do too' is more grammatical.",
          correction: 'I do too. I played with my friend yesterday.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 4,
          user_text: 'No. I lost. But I had fun.',
          issue: 'Good use of past tense and connector.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Simple sentences with correct grammar.',
        'Good use of past tense (played, won, lost).',
        'Natural interaction with the tutor throughout.',
      ],
      suggested_practice:
        'Practice talking about other games in Kunming, such as mahjong or playing cards with friends in the park.',
    }),
  },

  // ── A1 — nature_and_weather (rainy, Jinan) ────────────────────────────────
  {
    id: 'eval_sft_b7d3ca6b2a62',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello. It is raining heavily here in Jinan.',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 3, accuracy: 4, vocabulary: 3, interaction: 4, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 1,
          user_text: 'I hate rainy weather. I want to go outside but it is wet.',
          issue: "Good use of 'but' as a connector.",
          correction: 'I hate rainy weather. I want to go outside, but it is wet.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 5,
          user_text: 'I will put the jacket on the radiator now.',
          issue: 'Good use of future tense and preposition.',
          correction: '',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 6,
          user_text: 'But the rain will stop tomorrow? I hope so.',
          issue: 'Question needs subject-auxiliary inversion.',
          correction: 'Will the rain stop tomorrow? I hope so.',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Clear and simple sentence structures.',
        'Good use of basic weather vocabulary.',
        'Natural interaction with the tutor.',
        'Stays on topic throughout the conversation.',
      ],
      suggested_practice:
        "Practice talking about other Chinese weather situations, like snow in Harbin or sunny days in Kunming. Try describing what you would do if it rained in Changsha or if the sun came out in Xi'an.",
    }),
  },

  // ── A1 — work_and_education (Chongqing Normal University) ─────────────────
  {
    id: 'eval_sft_a2e700534653_v1',
    cefrLevel: 'A1',
    turn0Snippet: 'Hello. I am Wang. I go to class now.',
    response: JSON.stringify({
      overall_cefr_estimate: 'A1',
      scores: { fluency: 4, accuracy: 4, vocabulary: 3, interaction: 4, topic_adherence: 5 },
      specific_feedback: [
        {
          turn_index: 0,
          user_text: 'Hello. I am Wang. I go to class now.',
          issue: 'Present simple used where present continuous is more natural.',
          correction: 'Hello. I am Wang. I am going to class now.',
          level: 'A1',
          severity: 'minor',
        },
        {
          turn_index: 6,
          user_text: 'Five classes. My stomach hurts. I want lunch.',
          issue: 'First sentence is a fragment — missing subject and verb.',
          correction: 'I have five classes. My stomach hurts. I want lunch.',
          level: 'A1',
          severity: 'moderate',
        },
        {
          turn_index: 7,
          user_text: 'I eat beef noodles. It is good food.',
          issue: "Pronoun 'it' is singular; 'noodles' is plural.",
          correction: 'I eat beef noodles. They are delicious.',
          level: 'A1',
          severity: 'minor',
        },
      ],
      strengths: [
        'Clear and simple sentence structures.',
        'Good topic adherence throughout the conversation.',
        'Appropriate vocabulary for A1 level.',
        'Natural interaction with the tutor.',
      ],
      suggested_practice:
        'Practice talking about your favourite Chinese dishes and where you eat them in Chongqing or other cities. Try to describe your school subjects and teachers using simple sentences.',
    }),
  },
];

/**
 * Build a lookup table keyed by the first USER turn text (trimmed, lower-cased).
 * Collisions are very unlikely given distinct transcripts.
 */
const INDEX = new Map();
for (const ev of EVALUATIONS) {
  INDEX.set(ev.turn0Snippet.trim().toLowerCase(), ev);
}

/**
 * Extract the first [USER turn 0] text from the evaluation user-message content.
 * Returns null if not found.
 */
function extractTurn0(userContent) {
  const m = userContent.match(/\[USER turn 0\]\s*(.+)/);
  return m ? m[1].trim() : null;
}

/**
 * Given the incoming request messages (OpenAI format), return a pre-canned
 * evaluation JSON string, or null if no match is found.
 */
function findPreCannedEvaluation(requestMessages) {
  const userMsg = requestMessages.find(m => m.role === 'user');
  if (!userMsg) return null;

  const turn0 = extractTurn0(userMsg.content);
  if (!turn0) return null;

  const entry = INDEX.get(turn0.toLowerCase());
  return entry ? entry.response : null;
}

module.exports = { EVALUATIONS, findPreCannedEvaluation };

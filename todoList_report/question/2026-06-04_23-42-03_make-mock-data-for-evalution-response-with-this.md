# make mock data for evalution response with this attachment. in the content of at

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-04T14:42:03.003Z

## User

make mock data for evalution response with this attachment.
in the content of attachment, pipeline part is no necessary

this is the evalution response example.

{"role":"assistant","content":

"<think>
The user has provided a prompt setting up a tutoring scenario where I act as an English examiner. I need to evaluate a learner's dialogue based on CEFR A1 criteria, following specific rules about Chinese localization (no English place names, use Chinese names like Wei Wei, Suzhou, Wulin Road, etc.). However, the user has only sent \"Begin.\" and has not yet provided the actual dialogue transcript to score. I need to acknowledge the instruction and wait for the dialogue, or if this is a test of my ability to follow the format, I should generate a sample evaluation based on the provided SFT example dialogue since no new dialogue was submitted.

Wait, looking at the prompt structure: \"Begin.\" is the user's first input. The prompt instructions say \"Given a tutoring transcript and a target CEFR level, produce ONE assistant-turn payload\". The user has *not* provided a transcript yet, only \"Begin.\" and the system instructions.

Actually, looking closer at the prompt, the user *is* the examiner giving me instructions on how to behave. The \"Begin.\" is the trigger. But I don't have a transcript to score. The prompt includes a \"DIALOGUE (full SFT example)\" which I should probably use as the basis for my first output if no new transcript is provided, or I should ask for the transcript.

However, usually in these \"Begin\" scenarios with system instructions, the model is expected to acknowledge the role or generate the first output based on the provided example if no new input is given. But the instruction says \"Given a tutoring transcript...\". Since the user only said \"Begin.\", I will assume I need to generate the evaluation for the *provided* SFT example dialogue to demonstrate compliance, or simply acknowledge the role.

Wait, re-reading the \"OUTPUT FORMAT\" rules: \"No prose between
</think>

I am evaluating the provided dialogue transcript where the learner (He) is visiting his mother. The target CEFR level is A1. The learner demonstrates basic sentence structures and appropriate vocabulary for the topic of family and visiting parents. The learner uses simple present and future tenses correctly. The learner's turns are short and direct, fitting the A1 level.

The learner engages well with the tutor's prompts about food and location. The conversation flows naturally for a beginner. The learner correctly identifies the need for simple food for his mother's health. The interaction is supportive and focused on the assigned subtopics.

The learner's English is clear and understandable. The vocabulary used is appropriate for daily life in China. The learner follows the instructions to talk about health and family. The conversation remains on topic without drifting.

{
  \"overall_cefr_estimate\": \"A1\",
  \"scores\": {
    \"fluency\": 5,
    \"accuracy\": 5,
    \"vocabulary\": 5,
    \"interaction\": 5,
    \"topic_adherence\": 5
  },
  \"specific_feedback\": [
    {
      \"turn_index\": 0,
      \"user_text\": \"Hello. Today I want to cook some food for my mother's birthday.\",
      \"issue\": \"None\",
      \"correction\": \"None\",
      \"level\": \"A1\",
      \"severity\": \"minor\"
    },
    {
      \"turn_index\": 2,
      \"user_text\": \"Yes. My mother likes dumplings from Suzhou.\",
      \"issue\": \"None\",
      \"correction\": \"None\",
      \"level\": \"A1\",
      \"severity\": \"minor\"
    },
    {
      \"turn_index\": 4,
      \"user_text\": \"I will buy pork and cabbage today"}]}

## Assistant

Let me check the project structure to find the right place for this mock data.

## Assistant

Now I understand the structure. I'll create a `evaluations.js` data file with pre-canned evaluation responses from the attachment, then update `index.js` to use them for eval requests instead of always calling Claude.

## Assistant

Now update `index.js` to use these pre-canned evaluations:

## Assistant

Now let me commit and save the story:

## Assistant

Done. Here's what was created:

**[ai_model_mock/data/evaluations.js](ai_model_mock/data/evaluations.js)** — 13 pre-canned evaluation responses extracted from the attachment, covering categories: shopping, family visits, nature/weather, work/education, travel, and hobbies. Each entry has an `id`, `cefrLevel`, a `turn0Snippet` match key (the first `[USER turn 0]` text), and a clean JSON `response` string (no `<think>` block, no pipeline data).

**[ai_model_mock/index.js](ai_model_mock/index.js)** — Updated to use the new data: eval requests now check the pre-canned dataset first (matching on `[USER turn 0]` text) and only fall back to Claude if no match is found. Chat requests are unchanged.

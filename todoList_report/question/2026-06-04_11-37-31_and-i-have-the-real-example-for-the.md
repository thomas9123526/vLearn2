# and i have the real example for the evalution result from our custom model. From

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T02:37:31.941Z

## User

and i have the real example for the evalution result from our custom model.
From this response you can ignore <think> --------- </think>. 
On the evalution result screen on the application , you need to show session feed back first.
This content is below the '<think> --------- </think>' in the response. Like this.

"I am evaluating the provided dialogue transcript where the learner (He) is visiting his mother. The target CEFR level is A1. The learner demonstrates basic sentence structures and appropriate vocabulary for the topic of family and visiting parents. The learner uses simple present and future tenses correctly. The learner's turns are short and direct, fitting the A1 level.

The learner engages well with the tutor's prompts about food and location. The conversation flows naturally for a beginner. The learner correctly identifies the need for simple food for his mother's health. The interaction is supportive and focused on the assigned subtopics.

The learner's English is clear and understandable. The vocabulary used is appropriate for daily life in China. The learner follows the instructions to talk about health and family. The conversation remains on topic without drifting."

After this part, you can get scores like    
    \"fluency\": 5,
    \"accuracy\": 5,
    \"vocabulary\": 5,
    \"interaction\": 5,
    \"topic_adherence\": 5.

and overall_cefr_estimate.

Also turn specific result like this.

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

I want you visualize these evalution result and show on the application screen.\

## Assistant

The model actually outputs **prose text between `</think>` and the JSON object** — that's the session feedback paragraph. Our current parser discards it. I need to:

1. Capture that prose text in the backend
2. Save it to DB
3. Display it in Flutter

Let me explore what exists on the Flutter side first.

## Assistant

Let me read the key files to understand the current data flow before making changes.

## Assistant

Now let me read the conversations service to see how scores are saved and the score endpoint.

## Assistant

Now I have the full picture. Here's what needs to change:

1. **Backend parser**: extract the prose paragraph between `</think>` and `{` as `session_feedback`
2. **Backend storage**: save `session_feedback` to `ai_feedback`, keep `specific_feedback + suggested_practice` in `fluency_metrics` JSONB
3. **Backend response**: return `sessionFeedback`, `specificFeedback`, `suggestedPractice` from score endpoint
4. **Flutter UI**: show session feedback first, then scores, then turn-by-turn specific feedback

Starting with the backend:

## Assistant

Now update `conversations.service.ts` — save `session_feedback` to `ai_feedback`, keep `suggested_practice` inside the JSONB, and return all three from the score endpoint:

## Assistant

Now update the Flutter `session_report_screen.dart` to display session feedback first and add turn-specific feedback:

## Assistant

Need to add the `_TurnFeedbackItem` widget. Adding it after `_BulletLine`:

## Assistant

Now commit everything and save the story:

## Assistant

Done. Here's what changed:

**Backend:**
- `conversation.orchestrator.ts` — parser now captures the prose paragraph between `</think>` and `{` as `session_feedback` on the `EvaluationResult`
- `conversations.service.ts` — `ai_feedback` now stores the prose paragraph; `fluency_metrics` JSONB stores both `specific_feedback` and `suggested_practice`; `getSessionScore()` returns `sessionFeedback`, `specificFeedback`, and `suggestedPractice`

**Flutter (`session_report_screen.dart`):**
- Session feedback prose appears **first** in a bordered card
- Scores (fluency/accuracy/vocabulary/interaction/topic focus dots) follow
- New "Turn feedback" section shows `_TurnFeedbackItem` widgets — filtered to only turns where `issue != "None"`, with a colored left border by severity (red=major, orange=moderate, grey=minor), the quoted user text, the issue description, and a correction arrow

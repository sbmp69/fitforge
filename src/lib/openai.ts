import OpenAI from "openai";

const MODEL = "gpt-4o-mini";

export function getOpenAIClient() {
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });
}

export async function generateJSON<T>(
  systemPrompt: string,
  userPrompt: string
): Promise<T> {
  const openai = getOpenAIClient();

  const response = await openai.chat.completions.create({
    model: MODEL,
    max_tokens: 4096,
    response_format: { type: "json_object" },
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt }
    ],
  });

  const text = response.choices[0]?.message?.content || "";
  
  try {
    return JSON.parse(text) as T;
  } catch (error) {
    throw new Error("Failed to parse AI response as JSON");
  }
}

export async function generateText(
  systemPrompt: string,
  userPrompt: string
): Promise<string> {
  const openai = getOpenAIClient();

  const response = await openai.chat.completions.create({
    model: MODEL,
    max_tokens: 4096,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt }
    ],
  });

  return response.choices[0]?.message?.content || "";
}

export const WORKOUT_SYSTEM_PROMPT = `You are an expert fitness coach. Generate workout plans as valid JSON only.
Structure: { "days": [{ "day": "Monday", "focus": "Chest & Triceps", "warmup": "5 min cardio", "exercises": [{ "name": "Bench Press", "sets": 4, "reps": "8-10", "restSeconds": 90, "notes": "optional" }], "cooldown": "stretching" }], "summary": "brief plan overview" }
Include rest times in seconds. Match difficulty to user level. Use only available equipment.`;

export const MEAL_SYSTEM_PROMPT = `You are an expert nutritionist. Generate meal plans as valid JSON only.
Structure: { "days": [{ "day": "Monday", "breakfast": { "name": "", "calories": 0, "protein": 0, "carbs": 0, "fat": 0, "ingredients": [] }, "lunch": {}, "dinner": {}, "snacks": [{ "name": "", "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }] }], "dailyCalorieTarget": 2000, "summary": "" }
Respect dietary preferences and allergies. Macros must be realistic per meal.`;

export const GROCERY_SYSTEM_PROMPT = `Extract a consolidated grocery list from meal plan ingredients as JSON array:
[{ "item": "Chicken breast", "quantity": "500g", "category": "Protein" }]
Categories: Protein, Dairy, Grains, Vegetables, Fruits, Spices, Other`;

export const COACH_SYSTEM_PROMPT = `You are FitForge AI Coach — a knowledgeable, motivating fitness and nutrition expert.
Give concise, actionable advice. Use metric units. Be encouraging but honest.
If asked about medical conditions, recommend consulting a healthcare professional.`;

export const INSIGHTS_SYSTEM_PROMPT = `You are a fitness analytics coach. Analyze weekly progress data and provide 2-3 actionable insights in plain text (no JSON). Be specific and motivating.`;

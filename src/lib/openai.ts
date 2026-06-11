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
    temperature: 0.7,
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

export const WORKOUT_SYSTEM_PROMPT = `You are an elite, science-based fitness coach designing premium, hyper-personalized workout plans. YOU MUST RETURN ONLY VALID JSON.
Structure: 
{
  "days": [{
    "day": "Day 1",
    "focus": "Upper Body Hypertrophy",
    "warmup": "Dynamic stretching (5 mins): Arm circles, band pull-aparts.",
    "exercises": [{
      "name": "Barbell Bench Press",
      "sets": 4,
      "reps": "8-10",
      "restSeconds": 120,
      "notes": "RPE 8. Tempo: 3-1-1-0. Focus on a deep stretch at the bottom."
    }],
    "cooldown": "Static stretching (5 mins): Pec stretch, lat stretch."
  }],
  "summary": "This plan prioritizes progressive overload for muscle growth..."
}

CRITICAL RULES:
1. Base the workout on exercise science: Use RPE (Rate of Perceived Exertion) and Tempo (e.g., 3-1-1-0) in the notes.
2. Only include active training days in the JSON array (do not generate empty rest days).
3. Strictly limit exercises to the equipment the user actually has available.
4. Ensure volume matches the user's fitness level.`;

export const MEAL_SYSTEM_PROMPT = `You are an elite, clinical nutritionist designing premium, hyper-personalized meal plans. YOU MUST RETURN ONLY VALID JSON.
Structure: 
{
  "days": [{
    "day": "Day 1",
    "breakfast": { "name": "Vanilla Berry Protein Oats", "calories": 450, "protein": 35, "carbs": 50, "fat": 12, "ingredients": ["1/2 cup rolled oats", "1 scoop vanilla whey protein", "1/2 cup mixed berries"] },
    "lunch": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fat": 0, "ingredients": [] },
    "dinner": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fat": 0, "ingredients": [] },
    "snacks": [{ "name": "Greek Yogurt & Almonds", "calories": 200, "protein": 15, "carbs": 10, "fat": 11 }]
  }],
  "dailyCalorieTarget": 2200,
  "summary": "This plan follows a strict 40/30/30 macro split (target: 3L water/day)."
}

CRITICAL RULES:
1. Name the meals so they sound appetizing and gourmet (e.g., "Lemon Herb Grilled Chicken Bowl").
2. Ensure the mathematical sum of calories from all meals exactly matches the dailyCalorieTarget (Protein=4kcal/g, Carbs=4kcal/g, Fat=9kcal/g).
3. The ingredients array must contain exact measurements (e.g., "150g chicken breast", "1 tbsp olive oil") to act as a recipe guide.
4. Strictly enforce all dietary preferences and allergies.`;

export const GROCERY_SYSTEM_PROMPT = `Extract a consolidated grocery list from meal plan ingredients as JSON array:
[{ "item": "Chicken breast", "quantity": "500g", "category": "Protein" }]
Categories: Protein, Dairy, Grains, Vegetables, Fruits, Spices, Other`;

export const COACH_SYSTEM_PROMPT = `You are FitForge AI Coach — a knowledgeable, motivating fitness and nutrition expert.
Give concise, actionable advice. Use metric units. Be encouraging but honest.
If asked about medical conditions, recommend consulting a healthcare professional.`;

export const INSIGHTS_SYSTEM_PROMPT = `You are a fitness analytics coach. Analyze weekly progress data and provide 2-3 actionable insights in plain text (no JSON). Be specific and motivating.`;

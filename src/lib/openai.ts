import OpenAI from "openai";

const MODEL = "gpt-4o-mini";
const DEFAULT_OPENROUTER_KEY = Buffer.from('c2stb3ItdjEtZjljZGU0ODEzYWU2MWYzODA0ODdiN2Y1MTY5ZDBkMTkzNDkzY2ZjMzJhNDg0NTdjMGY1OTllMDk4NmNjNTc0Mg==', 'base64').toString('utf8');

export function getOpenAIClient() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (apiKey && apiKey.startsWith("sk-")) {
    return new OpenAI({ apiKey });
  }
  return new OpenAI({
    baseURL: "https://openrouter.ai/api/v1",
    apiKey: process.env.OPENROUTER_IMAGE_API_KEY || DEFAULT_OPENROUTER_KEY,
    defaultHeaders: {
      "HTTP-Referer": "https://fitforge.ai",
      "X-Title": "FitForge",
    },
  });
}

async function resilientChatCompletion(
  messages: Array<{ role: "system" | "user" | "assistant"; content: string }>,
  jsonMode = false
): Promise<string> {
  // 1. Try standard OpenAI if key is present
  if (process.env.OPENAI_API_KEY) {
    try {
      const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
      const response = await openai.chat.completions.create({
        model: MODEL,
        max_tokens: 4096,
        temperature: 0.7,
        ...(jsonMode ? { response_format: { type: "json_object" } } : {}),
        messages,
      });
      const text = response.choices[0]?.message?.content;
      if (text) return text;
    } catch (err: any) {
      console.warn("Primary OpenAI call failed, falling back to OpenRouter:", err?.message || err);
    }
  }

  // 2. Resilient OpenRouter fallback
  const openRouterKey = process.env.OPENROUTER_IMAGE_API_KEY || DEFAULT_OPENROUTER_KEY;
  const openrouter = new OpenAI({
    baseURL: "https://openrouter.ai/api/v1",
    apiKey: openRouterKey,
    defaultHeaders: {
      "HTTP-Referer": "https://fitforge.ai",
      "X-Title": "FitForge",
    },
  });

  const response = await openrouter.chat.completions.create({
    model: "openai/gpt-4o-mini",
    max_tokens: 4096,
    temperature: 0.7,
    ...(jsonMode ? { response_format: { type: "json_object" } } : {}),
    messages,
  });

  return response.choices[0]?.message?.content || "";
}

export async function generateJSON<T>(
  systemPrompt: string,
  userPrompt: string
): Promise<T> {
  const text = await resilientChatCompletion(
    [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt },
    ],
    true
  );

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
  return await resilientChatCompletion([
    { role: "system", content: systemPrompt },
    { role: "user", content: userPrompt },
  ]);
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
    "breakfast": { "name": "Vanilla Berry Protein Oats", "calories": 450, "protein": 35, "carbs": 50, "fat": 12 },
    "lunch": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fat": 0 },
    "dinner": { "name": "...", "calories": 0, "protein": 0, "carbs": 0, "fat": 0 },
    "snacks": [{ "name": "Greek Yogurt & Almonds", "calories": 200, "protein": 15, "carbs": 10, "fat": 11 }]
  }],
  "dailyCalorieTarget": 2200,
  "summary": "This plan follows a strict 40/30/30 macro split (target: 3L water/day)."
}

CRITICAL RULES:
1. Name the meals so they sound appetizing and gourmet.
2. Ensure the mathematical sum of calories from all meals exactly matches the dailyCalorieTarget (Protein=4kcal/g, Carbs=4kcal/g, Fat=9kcal/g).
3. Strictly enforce all dietary preferences and allergies.
4. CRITICAL: If a specific Country or Cuisine is requested, you MUST strictly generate authentic, everyday meals highly familiar to that region. COMPLETELY ELIMINATE generic western bodybuilding foods unless they are natively eaten there.`;

export const GROCERY_SYSTEM_PROMPT = `Extract a consolidated grocery list from meal plan ingredients as JSON array:
[{ "item": "Chicken breast", "quantity": "500g", "category": "Protein" }]
Categories: Protein, Dairy, Grains, Vegetables, Fruits, Spices, Other`;

export const COACH_SYSTEM_PROMPT = `You are FitForge AI Coach - an elite, hyper-personalized fitness, nutrition, and health expert.
Give concise, highly actionable advice. Use metric units. Be encouraging, empathetic, and scientifically rigorous.
If asked about serious medical conditions, recommend consulting a healthcare professional.

CRITICAL RULES:
1. HYPER-PERSONALIZATION: Always adapt your workout, dietary, and recovery advice to the user's specific Country, Cuisine/Meal Preference, Fitness Level, Body Fat %, Injuries, Equipment, and Goals provided in their profile context.
2. DIETARY & CULTURAL INTEGRITY: Never recommend ingredients, recipes, or eating habits that contradict their meal preference (e.g. Vegetarian, Traditional Indian, Keto) or regional availability in their country.
3. INJURY PREVENTION: Strictly protect any injured joints/areas (e.g. shoulders, knees, lower back) by prescribing safe exercise modifications and form cues.
4. SCOPE BOUNDARY: You are strictly a fitness, health, and nutrition coach. If the user asks about ANY topic unrelated to fitness, health, diet, or this app (e.g., coding, politics, general trivia), politely refuse and redirect back to their fitness goals.`;

export const INSIGHTS_SYSTEM_PROMPT = `You are a fitness analytics coach. Analyze weekly progress data and provide 2-3 actionable insights in plain text (no JSON). Be specific and motivating.`;

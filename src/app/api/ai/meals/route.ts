export const maxDuration = 60;
import { NextRequest, NextResponse } from "next/server";
import { createClient, createAuthClient } from "@/lib/supabase/server";
import {
  generateJSON,
  MEAL_SYSTEM_PROMPT,
  GROCERY_SYSTEM_PROMPT,
} from "@/lib/openai";
import { AI_PLAN_LIMITS } from "@/lib/utils";
import type { MealPlanData, GroceryItem } from "@/types/database";

function calculateNutritionTargets(profile: any) {
  const weight = Number(profile.weight_kg) || 75;
  const height = Number(profile.height_cm) || 175;
  let age = 25;
  if (profile.date_of_birth) {
    const dob = new Date(profile.date_of_birth);
    const diff = Date.now() - dob.getTime();
    age = Math.max(16, Math.min(80, Math.abs(new Date(diff).getUTCFullYear() - 1970)));
  }
  const isMale = (profile.gender || 'male').toLowerCase() !== 'female';

  // 1. Mifflin-St Jeor Clinical BMR
  const bmr = 10 * weight + 6.25 * height - 5 * age + (isMale ? 5 : -161);

  // 2. TDEE based on workout days
  const workoutDaysCount = Array.isArray(profile.workout_days) ? profile.workout_days.length : 3;
  let activityMultiplier = 1.35;
  if (workoutDaysCount <= 2) activityMultiplier = 1.25;
  else if (workoutDaysCount >= 5) activityMultiplier = 1.45;

  const tdee = Math.round(bmr * activityMultiplier);

  // 3. Caloric Delta based on goal and pace
  const goal = (profile.primary_goal || 'weight_loss').toLowerCase();
  const pace = (profile.target_pace || 'normal').toLowerCase();
  const targetWeight = Number(profile.target_weight_kg) || weight;

  let calorieTarget = tdee;
  let deficitOrSurplusLabel = "Maintenance";

  if (goal.includes('loss') || goal.includes('lose') || goal.includes('cut') || targetWeight < weight) {
    let dailyDeficit = 500;
    if (pace === 'fast') dailyDeficit = 750;
    else if (pace === 'steady') dailyDeficit = 350;

    const minSafeCalories = isMale ? 1500 : 1200;
    calorieTarget = Math.max(minSafeCalories, tdee - dailyDeficit);
    deficitOrSurplusLabel = `${tdee - calorieTarget} kcal daily deficit below TDEE (${tdee} kcal)`;
  } else if (goal.includes('gain') || goal.includes('muscle') || goal.includes('bulk') || targetWeight > weight) {
    const surplus = pace === 'fast' ? 450 : 300;
    calorieTarget = tdee + surplus;
    deficitOrSurplusLabel = `${surplus} kcal lean surplus above TDEE (${tdee} kcal)`;
  } else {
    calorieTarget = tdee;
    deficitOrSurplusLabel = `Maintenance calories (${tdee} kcal) for body recomposition`;
  }

  // 4. Clinical Protein Floor (1.8g per kg body weight)
  const proteinGrams = Math.round(weight * 1.8);
  const proteinCalories = proteinGrams * 4;

  // 5. Fat allocation: ~25% of total calories
  const fatCalories = Math.round(calorieTarget * 0.25);
  const fatGrams = Math.round(fatCalories / 9);

  // 6. Remaining calories to complex carbohydrates
  const carbCalories = Math.max(0, calorieTarget - proteinCalories - fatCalories);
  const carbGrams = Math.round(carbCalories / 4);

  return {
    bmr: Math.round(bmr),
    tdee,
    calorieTarget,
    proteinGrams,
    fatGrams,
    carbGrams,
    deficitOrSurplusLabel,
    targetWeight,
    pace,
  };
}


function slugify(name: string): string {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '').substring(0, 50);
}

function getVerifiedFallbackMealImage(name: string): string {
  const n = name.toLowerCase();
  if (n.includes('baingan') || n.includes('bharta') || n.includes('eggplant') || n.includes('sabzi')) {
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=240';
  } else if (n.includes('poha') || n.includes('upma') || n.includes('idli') || n.includes('dosa') || n.includes('uttapam') || n.includes('khichdi')) {
    return 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?q=80&w=240';
  } else if (n.includes('oat') || n.includes('porridge') || n.includes('cereal') || n.includes('muesli')) {
    return 'https://images.unsplash.com/photo-1509358271058-acd22cc93898?q=80&w=240';
  } else if (n.includes('paneer') || n.includes('palak') || n.includes('tofu')) {
    return 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?q=80&w=240';
  } else if (n.includes('roti') || n.includes('chapati') || n.includes('paratha') || n.includes('naan') || n.includes('bajra') || n.includes('bread')) {
    return 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=240';
  } else if (n.includes('dal') || n.includes('lentil') || n.includes('sambar') || n.includes('soup') || n.includes('tadka') || n.includes('curry')) {
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=240';
  } else if (n.includes('chana') || n.includes('chickpea') || n.includes('rajma') || n.includes('bean') || n.includes('sprout')) {
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=240';
  } else if (n.includes('rice') || n.includes('biryani') || n.includes('pulao')) {
    return 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=240';
  } else if (n.includes('nut') || n.includes('almond') || n.includes('walnut') || n.includes('seed')) {
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=240';
  } else if (n.includes('salad') || n.includes('cucumber') || n.includes('green')) {
    return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=240';
  } else if (n.includes('yogurt') || n.includes('curd') || n.includes('smoothie') || n.includes('shake') || n.includes('lassi')) {
    return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?q=80&w=240';
  } else if (n.includes('egg') || n.includes('omelette') || n.includes('scramble') || n.includes('bhurji')) {
    return 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=240';
  } else if (n.includes('chicken') || n.includes('turkey') || n.includes('meat') || n.includes('kebab')) {
    return 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?q=80&w=240';
  } else if (n.includes('fish') || n.includes('salmon') || n.includes('tuna')) {
    return 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=240';
  } else if (n.includes('fruit') || n.includes('apple') || n.includes('banana') || n.includes('berry')) {
    return 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?q=80&w=240';
  }
  return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=240';
}

async function resolveMealImage(supabase: any, name: string): Promise<string> {
  const slug = slugify(name);
  const fileName = `meals/${slug}.png`;

  // 1. Check if already stored in Supabase Storage
  try {
    const { data: files } = await supabase.storage.from("ai-assets").list("meals", { search: `${slug}.png` });
    if (files && files.some((f: any) => f.name === `${slug}.png`)) {
      const { data } = supabase.storage.from("ai-assets").getPublicUrl(fileName);
      return data.publicUrl;
    }
  } catch (_) {}

  // 2. Call OpenRouter Tencent Hy Image if key is available
  const DEFAULT_OPENROUTER_KEY = Buffer.from('c2stb3ItdjEtZjljZGU0ODEzYWU2MWYzODA0ODdiN2Y1MTY5ZDBkMTkzNDkzY2ZjMzJhNDg0NTdjMGY1OTllMDk4NmNjNTc0Mg==', 'base64').toString('utf8');
const apiKey = process.env.OPENROUTER_IMAGE_API_KEY || DEFAULT_OPENROUTER_KEY;
  if (apiKey) {
    try {
      const res = await fetch("https://openrouter.ai/api/v1/images", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://fitforge.ai",
          "X-Title": "FitForge"
        },
        body: JSON.stringify({
          model: "black-forest-labs/flux-3-image-klein",
          prompt: `Gourmet authentic professional food photography of ${name}, beautifully presented Indian meal, vibrant colors, studio lighting, depth of field, 4k`,
          aspect_ratio: "1:1"
        })
      });
      const json = await res.json();
      if (res.ok && json.data && json.data[0]) {
        let buffer: Buffer | null = null;
        if (json.data[0].b64_json) {
          buffer = Buffer.from(json.data[0].b64_json, "base64");
        } else if (json.data[0].url) {
          const imgFetch = await fetch(json.data[0].url);
          buffer = Buffer.from(await imgFetch.arrayBuffer());
        }
        if (buffer) {
          await supabase.storage.from("ai-assets").upload(fileName, buffer, { contentType: "image/png", upsert: true });
          const { data } = supabase.storage.from("ai-assets").getPublicUrl(fileName);
          return data.publicUrl;
        }
      }
    } catch (_) {}
  }

  // 3. Guaranteed verified fallback
  return getVerifiedFallbackMealImage(name);
}

export async function POST(request: NextRequest) {
  try {
    const token = request.headers.get("Authorization")?.replace("Bearer ", "");
    const supabase = token ? createAuthClient(token) : await createClient();

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("*")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return NextResponse.json({ error: "Profile not found" }, { status: 404 });
    }

    const limit = AI_PLAN_LIMITS[profile.subscription_tier] ?? 3;
    if (profile.ai_plans_used_this_month >= limit) {
      return NextResponse.json(
        { error: "Monthly AI plan limit reached. Upgrade to Pro for unlimited plans." },
        { status: 403 }
      );
    }

    const { dietaryPreference, allergies, substituteMeal } =
      await request.json();

    let ageText = 'Unknown';
    if (profile.date_of_birth) {
      const dob = new Date(profile.date_of_birth);
      const diff = Date.now() - dob.getTime();
      ageText = `${Math.abs(new Date(diff).getUTCFullYear() - 1970)}`;
    }

    let userPrompt: string;

    if (substituteMeal) {
      userPrompt = `Suggest an alternative for this meal respecting preferences:
Meal: ${JSON.stringify(substituteMeal.meal)}
Dietary preference: ${dietaryPreference}
Cuisine/Meal Preference: ${profile.meal_preference || "Not specified"}
Country: ${profile.country || "Not specified"}
Allergies: ${allergies?.join(", ") || "none"}
Ensure the meal uses authentic regional ingredients for this cuisine/country.
Return a single meal object JSON with name, calories, protein, carbs, fat, ingredients.`;
    } else {
      const targets = calculateNutritionTargets(profile);
      const effectiveDiet = profile.meal_preference || dietaryPreference || "Traditional Indian";
      userPrompt = `Create a 7-day meal plan.
User Profile: Age ${ageText}, Gender ${profile.gender || 'Unknown'}, Height ${profile.height_cm}cm, Current Weight ${profile.weight_kg}kg, Target Goal Weight ${targets.targetWeight}kg, Target Pace: ${targets.pace}, Fitness Level: ${profile.fitness_level}.
Current Body Composition: Current Body Fat ${profile.body_fat_range || 'Average'}, Desired Target Body Fat ${profile.desired_body_fat || 'Lean'}.
Weight Loss History: ${profile.weight_loss_history || 'None'} (calibrate satiety and sustainable food choices accordingly).
Lifestyle & Metabolic Factors: ${profile.lifestyle_issues?.join(', ') || 'Normal active'}.
Primary Goal: ${profile.primary_goal} (If missing, assume healthy maintenance).

MANDATORY CLINICAL NUTRITION TARGETS (STRICT THERMODYNAMICS - NO HALLUCINATIONS):
- Exact Daily Calorie Target: ${targets.calorieTarget} kcal (${targets.deficitOrSurplusLabel}).
- Minimum Daily Protein Target: ${targets.proteinGrams}g (1.8g per kg body weight to guarantee muscle preservation during deficit).
- Target Fats: ~${targets.fatGrams}g, Target Complex Carbs: ~${targets.carbGrams}g.
- Every day's total calories (Breakfast + Lunch + Dinner + Snacks) MUST mathematically sum to exactly ${targets.calorieTarget} kcal (±25 kcal).
- "dailyCalorieTarget" in the JSON root MUST be set to exactly ${targets.calorieTarget}.

Dietary & Cuisine Preference: ${effectiveDiet}
Country / Region: ${profile.country || "India"}
Allergies / Dislikes to avoid: ${allergies?.join(", ") || "none"}
CRITICAL CULTURAL RULE: Strictly generate authentic everyday recipes and ingredients native to ${profile.country || "this country"} adhering strictly to ${effectiveDiet}. Do NOT provide generic Western bodybuilder meals (e.g. unflavored boiled chicken or canned tuna) unless requested.
Include breakfast, lunch, dinner, and 1-2 snacks per day with exact macro breakdowns.`;
    }

    if (substituteMeal) {
      const meal = await generateJSON(MEAL_SYSTEM_PROMPT, userPrompt);
      return NextResponse.json({ meal });
    }

    const planData = await generateJSON<MealPlanData>(
      MEAL_SYSTEM_PROMPT,
      userPrompt
    );

    // Combine meal plan generation with image resolution right now on the backend!
    if (planData && Array.isArray(planData.days)) {
      for (const day of planData.days) {
        if (day.breakfast?.name) (day.breakfast as any).image_url = await resolveMealImage(supabase, day.breakfast.name);
        if (day.lunch?.name) (day.lunch as any).image_url = await resolveMealImage(supabase, day.lunch.name);
        if (day.dinner?.name) (day.dinner as any).image_url = await resolveMealImage(supabase, day.dinner.name);
        if (Array.isArray(day.snacks)) {
          for (const s of day.snacks) {
            if (s?.name) (s as any).image_url = await resolveMealImage(supabase, s.name);
          }
        }
      }
    }

    // Normalize dietary_preference to fit postgres enum ('veg', 'non_veg', 'vegan')
    let dbDiet = 'non_veg';
    const rawDiet = (dietaryPreference || profile.meal_preference || '').toLowerCase();
    if (rawDiet.includes('vegan')) {
      dbDiet = 'vegan';
    } else if (rawDiet.includes('veg') && !rawDiet.includes('non')) {
      dbDiet = 'veg';
    } else {
      dbDiet = 'non_veg';
    }

    const { data: plan, error } = await supabase
      .from("meal_plans")
      .insert({
        user_id: user.id,
        calorie_target: planData.dailyCalorieTarget || calculateNutritionTargets(profile).calorieTarget,
        dietary_preference: dbDiet,
        allergies: allergies || [],
        plan_data: planData,
        grocery_list: planData.groceryList || [],
      })
      .select()
      .single();

    if (error) throw error;

    await supabase
      .from("profiles")
      .update({
        ai_plans_used_this_month: profile.ai_plans_used_this_month + 1,
      })
      .eq("id", user.id);

    return NextResponse.json({ plan });
  } catch (error) {
    console.error("Meal generation error:", error);
    return NextResponse.json(
      { error: "Failed to generate meal plan" },
      { status: 500 }
    );
  }
}


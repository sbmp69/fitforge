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
      const effectiveDiet = profile.meal_preference || dietaryPreference || "Traditional Indian";
      userPrompt = `Create a 7-day meal plan.
User Profile: Age ${ageText}, Gender ${profile.gender || 'Unknown'}, Height ${profile.height_cm}cm, Current Weight ${profile.weight_kg}kg, Target Goal Weight ${profile.target_weight_kg || profile.weight_kg}kg, Target Pace: ${profile.target_pace || 'normal'}, Fitness Level: ${profile.fitness_level}.
Current Body Composition: Current Body Fat ${profile.body_fat_range || 'Average'}, Desired Target Body Fat ${profile.desired_body_fat || 'Lean'}.
Weight Loss History: ${profile.weight_loss_history || 'None'} (calibrate satiety and sustainable food choices accordingly).
Lifestyle & Metabolic Factors: ${profile.lifestyle_issues?.join(', ') || 'Normal active'}.
Primary Goal: ${profile.primary_goal} (If missing, assume healthy maintenance).
Instructions: First, calculate the required daily caloric intake for this specific user based on their metrics and goal (assume statistical average for age/gender if needed). Then, generate a meal plan that strictly matches those calculated daily calories and macros optimized for their body fat range and goal.
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

    const { data: plan, error } = await supabase
      .from("meal_plans")
      .insert({
        user_id: user.id,
        calorie_target: 0,
        dietary_preference: dietaryPreference,
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


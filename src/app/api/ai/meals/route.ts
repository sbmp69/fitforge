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

    let userPrompt: string;

    if (substituteMeal) {
      userPrompt = `Suggest an alternative for this meal respecting preferences:
Meal: ${JSON.stringify(substituteMeal.meal)}
Dietary preference: ${dietaryPreference}
Allergies: ${allergies?.join(", ") || "none"}
Return a single meal object JSON with name, calories, protein, carbs, fat, ingredients.`;
    } else {
      userPrompt = `Create a 7-day meal plan.
User Profile: Height ${profile.height_cm}cm, Weight ${profile.weight_kg}kg, Fitness Level: ${profile.fitness_level}.
Primary Goal: ${profile.primary_goal} (If missing, assume healthy maintenance).
Instructions: First, calculate the required daily caloric intake for this specific user based on their metrics and goal (assume statistical average for age/gender if needed). Then, generate a meal plan that strictly matches those calculated daily calories.
Dietary preference: ${dietaryPreference}
Allergies to avoid: ${allergies?.join(", ") || "none"}
Include breakfast, lunch, dinner, and 1-2 snacks per day with macro breakdowns.`;
    }

    if (substituteMeal) {
      const meal = await generateJSON(MEAL_SYSTEM_PROMPT, userPrompt);
      return NextResponse.json({ meal });
    }

    const planData = await generateJSON<MealPlanData>(
      MEAL_SYSTEM_PROMPT,
      userPrompt
    );

    const groceryList = await generateJSON<GroceryItem[]>(
      GROCERY_SYSTEM_PROMPT,
      `Generate grocery list from: ${JSON.stringify(planData)}`
    );

    const { data: plan, error } = await supabase
      .from("meal_plans")
      .insert({
        user_id: user.id,
        calorie_target: 0,
        dietary_preference: dietaryPreference,
        allergies: allergies || [],
        plan_data: planData,
        grocery_list: groceryList,
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

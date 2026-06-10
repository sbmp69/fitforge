import { NextRequest, NextResponse } from "next/server";
import { createClient, createAuthClient } from "@/lib/supabase/server";
import {
  generateJSON,
  WORKOUT_SYSTEM_PROMPT,
} from "@/lib/openai";
import { AI_PLAN_LIMITS } from "@/lib/utils";
import type { WorkoutPlanData } from "@/types/database";

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

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("*")
      .eq("id", user.id)
      .single();

    console.log("Supabase Auth User ID:", user.id);
    console.log("Profile Error:", profileError);
    console.log("Profile Data:", profile);

    if (!profile) {
      return NextResponse.json({ error: `Profile not found for user ${user.id}. DB Error: ${profileError?.message || 'none'}` }, { status: 404 });
    }

    const limit = AI_PLAN_LIMITS[profile.subscription_tier] ?? 3;
    if (profile.ai_plans_used_this_month >= limit) {
      return NextResponse.json(
        { error: "Monthly AI plan limit reached. Upgrade to Pro for unlimited plans." },
        { status: 403 }
      );
    }

    const body = await request.json();
    const { goal, level, daysPerWeek, equipment, regenerateDay, existingPlan } =
      body;

    let userPrompt: string;

    const physiqueContext = `Physique Data: Height: ${profile.height_cm || 'Not provided'}cm, Weight: ${profile.weight_kg || 'Not provided'}kg.`;

    if (regenerateDay && existingPlan) {
      userPrompt = `Regenerate only the "${regenerateDay}" workout in this plan. Keep other days unchanged.
Current plan: ${JSON.stringify(existingPlan)}
${physiqueContext}
Goal: ${goal}, Level: ${level}, Equipment: ${equipment?.join(", ") || "bodyweight only"}
Return the full updated plan JSON.`;
    } else {
      userPrompt = `Create a ${daysPerWeek}-day weekly workout plan.
${physiqueContext}
Goal: ${goal}
Level: ${level}
Equipment available: ${equipment?.join(", ") || "bodyweight only"}
Include ${daysPerWeek} workout days with appropriate rest days implied.`;
    }

    const planData = await generateJSON<WorkoutPlanData>(
      WORKOUT_SYSTEM_PROMPT,
      userPrompt
    );

    const { data: plan, error } = await supabase
      .from("workout_plans")
      .insert({
        user_id: user.id,
        goal,
        level,
        days_per_week: daysPerWeek,
        equipment: equipment || [],
        plan_data: planData,
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
    console.error("Workout generation error:", error);
    return NextResponse.json(
      { error: "Failed to generate workout plan" },
      { status: 500 }
    );
  }
}

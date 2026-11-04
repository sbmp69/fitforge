export const maxDuration = 60;
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

    let ageText = 'Unknown';
    if (profile.date_of_birth) {
      const dob = new Date(profile.date_of_birth);
      const diff = Date.now() - dob.getTime();
      ageText = `${Math.abs(new Date(diff).getUTCFullYear() - 1970)}`;
    }

    const effectiveGoal = goal || profile.primary_goal || 'build_muscle';
    const effectiveLevel = level || profile.fitness_level || 'beginner';
    const effectiveDays = daysPerWeek || (profile.workout_days && profile.workout_days.length > 0 ? profile.workout_days.length : 3);
    const effectiveEquipment = equipment || profile.equipment || ['bodyweight only'];

    let physiqueContext = `Physique Data: Age ${ageText}, Gender ${profile.gender || 'Unknown'}, Height: ${profile.height_cm || 'Not provided'}cm, Current Weight: ${profile.weight_kg || 'Not provided'}kg.`;
    if (profile.target_weight_kg) {
      physiqueContext += ` Target Goal Weight: ${profile.target_weight_kg}kg. Target Pace: ${profile.target_pace || 'normal'}.`;
    }
    if (profile.target_focus_areas && profile.target_focus_areas.length > 0) {
      physiqueContext += `\nPRIORITY FOCUS MUSCLE GROUPS: ${profile.target_focus_areas.join(', ')}. Dedicate extra volume and targeted exercises to these areas!`;
    }
    if (profile.injuries && profile.injuries.length > 0 && !profile.injuries.includes('No injuries')) {
      physiqueContext += `\nCRITICAL INJURY SAFETY: User has reported injuries/pain in: ${profile.injuries.join(', ')}. STRICTLY AVOID any exercises that heavily load, strain, or compromise these vulnerable joints/muscles! Suggest safe, pain-free alternatives.`;
    }
    if (profile.lifestyle_issues && profile.lifestyle_issues.length > 0 && !profile.lifestyle_issues.includes('None, I\'m healthy!')) {
      physiqueContext += `\nLifestyle Factors: ${profile.lifestyle_issues.join(', ')}. Include appropriate postural correction and mobility exercises.`;
    }

    if (regenerateDay && existingPlan) {
      userPrompt = `Regenerate only the "${regenerateDay}" workout in this plan. Keep other days unchanged.
Current plan: ${JSON.stringify(existingPlan)}
${physiqueContext}
Goal: ${effectiveGoal}, Level: ${effectiveLevel}, Equipment: ${Array.isArray(effectiveEquipment) ? effectiveEquipment.join(", ") : effectiveEquipment}
Return the full updated plan JSON.`;
    } else {
      userPrompt = `Create a ${effectiveDays}-day weekly workout plan.
${physiqueContext}
Goal: ${effectiveGoal}
Level: ${effectiveLevel}
Equipment available: ${Array.isArray(effectiveEquipment) ? effectiveEquipment.join(", ") : effectiveEquipment}
Include ${effectiveDays} workout days with appropriate rest days implied.`;
    }

    const planData = await generateJSON<WorkoutPlanData>(
      WORKOUT_SYSTEM_PROMPT,
      userPrompt
    );

    const { data: plan, error } = await supabase
      .from("workout_plans")
      .insert({
        user_id: user.id,
        goal: effectiveGoal,
        level: effectiveLevel,
        days_per_week: effectiveDays,
        equipment: Array.isArray(effectiveEquipment) ? effectiveEquipment : [effectiveEquipment],
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

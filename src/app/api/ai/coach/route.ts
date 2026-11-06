export const maxDuration = 60;
import { NextRequest, NextResponse } from "next/server";
import { createClient, createAuthClient } from "@/lib/supabase/server";
import { generateText, COACH_SYSTEM_PROMPT } from "@/lib/openai";

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

    const { message } = await request.json();
    if (!message?.trim()) {
      return NextResponse.json({ error: "Message required" }, { status: 400 });
    }

    const [
      { data: history },
      { data: profile },
      { data: workoutPlan },
      { data: mealPlan },
    ] = await Promise.all([
      supabase.from("ai_chat_messages").select("role, content").eq("user_id", user.id).order("created_at", { ascending: false }).limit(10),
      supabase.from("profiles").select("*").eq("id", user.id).single(),
      supabase.from("workout_plans").select("*").eq("user_id", user.id).eq("is_active", true).maybeSingle(),
      supabase.from("meal_plans").select("*").eq("user_id", user.id).eq("is_active", true).maybeSingle(),
    ]);

    const context = (history || [])
      .reverse()
      .map((m) => `${m.role}: ${m.content}`)
      .join("\n");

    let hyperContext = `--- USER PROFILE ---\n`;
    if (profile) {
      let ageText = 'Unknown';
      if (profile.date_of_birth) {
        const dob = new Date(profile.date_of_birth);
        const diff = Date.now() - dob.getTime();
        ageText = `${Math.abs(new Date(diff).getUTCFullYear() - 1970)}`;
      }
      hyperContext += `Age: ${ageText}, Gender: ${profile.gender ?? 'Unknown'}\n`;
      hyperContext += `Country / Location: ${profile.country ?? 'Unknown'}\n`;
      hyperContext += `Current Body Fat / Shape: ${profile.body_fat_range ?? 'Unknown'}, Desired Body Fat: ${profile.desired_body_fat ?? 'Unknown'}\n`;
      hyperContext += `Height: ${profile.height_cm ?? 'Unknown'}cm, Weight: ${profile.weight_kg ?? 'Unknown'}kg\n`;
            hyperContext += `Goal: ${profile.primary_goal ?? 'Unknown'}, Level: ${profile.fitness_level ?? 'Unknown'}\n`;
      if (profile.target_weight_kg) hyperContext += `Target Weight: ${profile.target_weight_kg}kg, Pace: ${profile.target_pace || 'normal'}\n`;
      if (profile.weight_loss_history) hyperContext += `Weight Loss History: ${profile.weight_loss_history}\n`;
      if (profile.meal_preference) hyperContext += `Cuisine / Meal Preference: ${profile.meal_preference}\n`;
      if (profile.target_focus_areas?.length) hyperContext += `Focus Muscle Groups: ${profile.target_focus_areas.join(', ')}\n`;
      if (profile.injuries?.length) hyperContext += `Injuries / Restrictions: ${profile.injuries.join(', ')}\n`;
      if (profile.equipment?.length) hyperContext += `Available Equipment: ${profile.equipment.join(', ')}\n`;
      if (profile.workout_days?.length) hyperContext += `Training Days: ${profile.workout_days.join(', ')}\n`;
      if (profile.lifestyle_issues?.length) hyperContext += `Lifestyle / Issues: ${profile.lifestyle_issues.join(', ')}\n`;
      const weight = Number(profile.weight_kg) || 75;
      const height = Number(profile.height_cm) || 175;
      const ageNum = parseInt(ageText, 10) || 25;
      const isMale = (profile.gender || 'male').toLowerCase() !== 'female';
      const bmr = Math.round(10 * weight + 6.25 * height - 5 * ageNum + (isMale ? 5 : -161));
      const workoutDaysCount = Array.isArray(profile.workout_days) ? profile.workout_days.length : 3;
      const tdee = Math.round(bmr * (workoutDaysCount <= 2 ? 1.25 : workoutDaysCount >= 5 ? 1.45 : 1.35));
      const deficit = profile.target_pace === 'fast' ? 750 : profile.target_pace === 'steady' ? 350 : 500;
      const dailyCalorieBudget = Math.max(isMale ? 1500 : 1200, tdee - deficit);
      const dailyProteinFloor = Math.round(weight * 1.8);

      hyperContext += `\n--- SCIENTIFIC METABOLIC TARGETS (7,700 kcal / kg FAT LOSS EQUATION) ---
BMR: ${bmr} kcal | TDEE (Maintenance): ${tdee} kcal
Daily Calorie Budget: ${dailyCalorieBudget} kcal (${tdee - dailyCalorieBudget} kcal daily deficit)
Daily Protein Target: ${dailyProteinFloor}g / day (1.8g/kg body weight to preserve 100% lean muscle mass)
Expected Fat Loss Rate: ${(deficit * 7 / 7700).toFixed(2)} kg / week
When discussing calories, macros, or their target date, reference these exact mathematical numbers with absolute consistency.\n`;

      hyperContext += `\nCRITICAL CONSTRAINTS:
- Respect the user's Country (${profile.country || 'their region'}) and Cuisine/Meal Preference (${profile.meal_preference || 'stated diet'}). Never suggest recipes, proteins, or ingredients alien to or forbidden in their dietary preference.
- Strictly avoid exercises straining their injuries (${profile.injuries?.join(', ') || 'none'}).
- Respect their available equipment (${profile.equipment?.join(', ') || 'bodyweight'}).\n`;
    }
    if (workoutPlan) {
      hyperContext += `\n--- ACTIVE WORKOUT PLAN ---\nTitle: ${workoutPlan.title}\n`;
      try {
        hyperContext += `Schedule: ${JSON.stringify(workoutPlan.plan_data.days.map((d: any) => ({ day: d.day, focus: d.focus })))}\n`;
      } catch (e) {}
    }
    if (mealPlan) {
      try {
        hyperContext += `\n--- ACTIVE MEAL PLAN ---\nCalories: ${mealPlan.plan_data.dailyCalorieTarget}\nSample Day: ${JSON.stringify(mealPlan.plan_data.days[0])}\n`;
      } catch (e) {}
    }
    hyperContext += `\n------------------\n`;

    const fullSystemPrompt = `${COACH_SYSTEM_PROMPT}\n\nYou have access to the user's real-time data below. Use this context to give highly personalized advice. DO NOT mention that you are reading this data unless necessary. Keep responses very concise.\n\n${hyperContext}`;

    const userPrompt = context
      ? `Previous conversation:\n${context}\n\nUser: ${message}`
      : message;

    const reply = await generateText(fullSystemPrompt, userPrompt);

    await supabase.from("ai_chat_messages").insert([
      { user_id: user.id, role: "user", content: message },
      { user_id: user.id, role: "assistant", content: reply },
    ]);

    return NextResponse.json({ reply });
  } catch (error) {
    console.error("Coach chat error:", error);
    return NextResponse.json(
      { error: "Failed to get coach response" },
      { status: 500 }
    );
  }
}


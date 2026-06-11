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
      hyperContext += `Height: ${profile.height_cm ?? 'Unknown'}cm, Weight: ${profile.weight_kg ?? 'Unknown'}kg\n`;
      hyperContext += `Goal: ${profile.primary_goal ?? 'Unknown'}, Level: ${profile.fitness_level ?? 'Unknown'}\n`;
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

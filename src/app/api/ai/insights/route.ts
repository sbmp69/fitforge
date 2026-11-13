export const maxDuration = 60;
import { NextResponse, NextRequest } from "next/server";
import { createClient, createAuthClient } from "@/lib/supabase/server";
import { generateText, INSIGHTS_SYSTEM_PROMPT } from "@/lib/openai";
import { startOfWeek, format } from "date-fns";

async function handleInsights(request: NextRequest) {
  try {
    const token = request.headers.get("Authorization")?.replace("Bearer ", "");
    const supabase = token ? createAuthClient(token) : await createClient();

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const weekStart = format(startOfWeek(new Date(), { weekStartsOn: 1 }), "yyyy-MM-dd");

    const url = new URL(request.url);
    const forceRefresh = url.searchParams.get("refresh") === "true" || url.searchParams.get("force") === "true";

    // 1. If not forcing a refresh, return existing cached insight for this week
    if (!forceRefresh) {
      const { data: existing } = await supabase
        .from("weekly_insights")
        .select("*")
        .eq("user_id", user.id)
        .eq("week_start", weekStart)
        .maybeSingle();

      if (existing?.insight_text) {
        return NextResponse.json({ insight: existing });
      }
    }

    // 2. Fetch profile context for hyper-personalized insights
    const { data: profile } = await supabase
      .from("profiles")
      .select("full_name, primary_goal, fitness_level, weight_kg, height_cm, target_weight_kg")
      .eq("id", user.id)
      .maybeSingle();

    // 3. Query progress logs for this week
    let { data: logs } = await supabase
      .from("progress_logs")
      .select("*")
      .eq("user_id", user.id)
      .gte("log_date", weekStart)
      .order("log_date", { ascending: false });

    // If no logs found this week, check the last 14 days so we can give meaningful insights
    if (!logs || logs.length === 0) {
      const twoWeeksAgo = format(new Date(Date.now() - 14 * 24 * 60 * 60 * 1000), "yyyy-MM-dd");
      const { data: recentLogs } = await supabase
        .from("progress_logs")
        .select("*")
        .eq("user_id", user.id)
        .gte("log_date", twoWeeksAgo)
        .order("log_date", { ascending: false })
        .limit(10);
      if (recentLogs && recentLogs.length > 0) {
        logs = recentLogs;
      }
    }

    let insightText = "";
    if (logs && logs.length > 0) {
      const userSummary = profile
        ? `Name: ${profile.full_name || 'Athlete'}, Goal: ${profile.primary_goal || 'Fitness'}, Current Weight: ${profile.weight_kg || 'N/A'}kg, Target: ${profile.target_weight_kg || 'N/A'}kg`
        : 'Athlete';

      insightText = await generateText(
        INSIGHTS_SYSTEM_PROMPT,
        `User Profile: ${userSummary}\nRecent Progress Data (Weight, Water ml, Sleep hrs, Workout done):\n${JSON.stringify(logs, null, 2)}\n\nAnalyze their consistency, hydration, recovery, and workout streaks. Provide motivating feedback and 2-3 specific, actionable recommendations for the upcoming week.`
      );
    } else {
      // Motivating starter insight based on their profile
      const goal = profile?.primary_goal ? profile.primary_goal.replace(/_/g, " ") : "general fitness";
      insightText = `Welcome to your weekly progress journey! 🚀\n\n` +
        `We haven't recorded any metrics for this week yet. Once you log your daily weight, water intake, or workouts above, you'll receive a detailed AI breakdown of your trends and habits here!\n\n` +
        `💡 **Coach Kickoff for ${goal.toUpperCase()}:**\n` +
        `• **Hydration**: Target 2.5L – 3L of water daily to maintain peak workout energy.\n` +
        `• **Consistency**: Aim to log at least 3 completed workouts this week.\n` +
        `• **Recovery**: Target 7–8 hours of quality sleep to fuel muscle recovery.\n\n` +
        `Log today's entry above, then tap Generate to get your updated weekly review!`;
    }

    let insightRecord = {
      user_id: user.id,
      week_start: weekStart,
      insight_text: insightText,
    };

    try {
      const { data: upserted, error: upsertErr } = await supabase
        .from("weekly_insights")
        .upsert(
          {
            user_id: user.id,
            week_start: weekStart,
            insight_text: insightText,
          },
          { onConflict: "user_id,week_start" }
        )
        .select()
        .maybeSingle();

      if (!upsertErr && upserted) {
        insightRecord = upserted;
      }
    } catch (dbErr) {
      console.warn("Could not upsert insight into weekly_insights table:", dbErr);
    }

    return NextResponse.json({ insight: insightRecord });
  } catch (error: any) {
    console.error("Insights error:", error);
    return NextResponse.json(
      {
        insight: {
          insight_text:
            "Our AI Coach recommends focusing on daily hydration (2.5L+), 7-8 hours of sleep, and consistent training this week. Keep up the dedication!",
        },
      },
      { status: 200 }
    );
  }
}

export async function GET(request: NextRequest) {
  return handleInsights(request);
}

export async function POST(request: NextRequest) {
  return handleInsights(request);
}

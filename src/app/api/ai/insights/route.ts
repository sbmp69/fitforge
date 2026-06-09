import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { generateText, INSIGHTS_SYSTEM_PROMPT } from "@/lib/anthropic";
import { startOfWeek, format } from "date-fns";

export async function POST() {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const weekStart = format(startOfWeek(new Date(), { weekStartsOn: 1 }), "yyyy-MM-dd");

    const { data: existing } = await supabase
      .from("weekly_insights")
      .select("*")
      .eq("user_id", user.id)
      .eq("week_start", weekStart)
      .single();

    if (existing) {
      return NextResponse.json({ insight: existing });
    }

    const { data: logs } = await supabase
      .from("progress_logs")
      .select("*")
      .eq("user_id", user.id)
      .gte("log_date", weekStart)
      .order("log_date");

    if (!logs?.length) {
      return NextResponse.json({
        insight: {
          insight_text:
            "Start logging your daily progress to receive personalized weekly insights!",
        },
      });
    }

    const insightText = await generateText(
      INSIGHTS_SYSTEM_PROMPT,
      `Weekly progress data: ${JSON.stringify(logs)}`
    );

    const { data: insight } = await supabase
      .from("weekly_insights")
      .insert({
        user_id: user.id,
        week_start: weekStart,
        insight_text: insightText,
      })
      .select()
      .single();

    return NextResponse.json({ insight });
  } catch (error) {
    console.error("Insights error:", error);
    return NextResponse.json(
      { error: "Failed to generate insights" },
      { status: 500 }
    );
  }
}

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ logs: [] });
  }

  const { data: logs } = await supabase
    .from("progress_logs")
    .select("*")
    .eq("user_id", user.id)
    .order("log_date", { ascending: false })
    .limit(365);

  return NextResponse.json({ logs: logs || [] });
}

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();

  const { data: log, error } = await supabase
    .from("progress_logs")
    .upsert(
      {
        user_id: user.id,
        log_date: body.log_date,
        weight_kg: body.weight_kg,
        workout_completed: body.workout_completed,
        water_ml: body.water_ml,
        sleep_hours: body.sleep_hours,
      },
      { onConflict: "user_id,log_date" }
    )
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ log });
}

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { data: programs } = await supabase
    .from("programs")
    .select("*")
    .eq("trainer_id", user.id)
    .order("created_at", { ascending: false });

  const { data: purchases } = await supabase
    .from("program_purchases")
    .select("amount_inr, commission_inr")
    .in("program_id", (programs || []).map((p) => p.id));

  const revenue = (purchases || []).reduce(
    (sum, p) => sum + (p.amount_inr - p.commission_inr),
    0
  );

  const { data: profile } = await supabase
    .from("profiles")
    .select("follower_count")
    .eq("id", user.id)
    .single();

  return NextResponse.json({
    programs: programs || [],
    stats: {
      revenue,
      sales: purchases?.length || 0,
      followers: profile?.follower_count || 0,
    },
  });
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

  const { data: program, error } = await supabase
    .from("programs")
    .insert({
      trainer_id: user.id,
      name: body.name,
      description: body.description,
      duration_weeks: body.duration_weeks,
      price_inr: body.price_inr,
      cover_image_url: body.cover_image_url || null,
    })
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ program });
}

export async function PATCH(request: NextRequest) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id, is_published } = await request.json();

  const { error } = await supabase
    .from("programs")
    .update({ is_published })
    .eq("id", id)
    .eq("trainer_id", user.id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}

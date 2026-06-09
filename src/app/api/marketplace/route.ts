import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();

  const { data: programs } = await supabase
    .from("programs")
    .select("*, profiles!programs_trainer_id_fkey(full_name, avatar_url, follower_count)")
    .eq("is_published", true)
    .order("purchase_count", { ascending: false });

  return NextResponse.json({ programs: programs || [] });
}

import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ purchased: [] });
  }

  const { data } = await supabase
    .from("program_purchases")
    .select("program_id")
    .eq("buyer_id", user.id);

  return NextResponse.json({
    purchased: data?.map((p) => p.program_id) || [],
  });
}

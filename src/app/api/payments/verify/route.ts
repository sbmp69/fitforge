import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import crypto from "crypto";
import { calculateSplit } from "@/lib/razorpay";

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { type } = body;

    if (type === "subscription") {
      const { razorpay_payment_id, razorpay_subscription_id, razorpay_signature, tier } = body;

      const expected = crypto
        .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET!)
        .update(`${razorpay_payment_id}|${razorpay_subscription_id}`)
        .digest("hex");

      if (expected !== razorpay_signature) {
        return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
      }

      await supabase
        .from("profiles")
        .update({
          subscription_tier: tier,
          razorpay_subscription_id: razorpay_subscription_id,
          role: tier === "trainer" ? "trainer" : undefined,
        })
        .eq("id", user.id);

      return NextResponse.json({ success: true });
    }

    if (type === "marketplace") {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature, programId } = body;

      const expected = crypto
        .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET!)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest("hex");

      if (expected !== razorpay_signature) {
        return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
      }

      const { data: program } = await supabase
        .from("programs")
        .select("price_inr")
        .eq("id", programId)
        .single();

      if (!program) {
        return NextResponse.json({ error: "Program not found" }, { status: 404 });
      }

      const { commission } = calculateSplit(program.price_inr);

      await supabase.from("program_purchases").insert({
        program_id: programId,
        buyer_id: user.id,
        amount_inr: program.price_inr,
        commission_inr: commission,
        razorpay_payment_id,
        razorpay_order_id,
      });

      const { data: currentProgram } = await supabase
        .from("programs")
        .select("purchase_count")
        .eq("id", programId)
        .single();

      await supabase
        .from("programs")
        .update({ purchase_count: (currentProgram?.purchase_count || 0) + 1 })
        .eq("id", programId);

      return NextResponse.json({ success: true });
    }

    return NextResponse.json({ error: "Invalid type" }, { status: 400 });
  } catch (error) {
    console.error("Payment verify error:", error);
    return NextResponse.json({ error: "Verification failed" }, { status: 500 });
  }
}

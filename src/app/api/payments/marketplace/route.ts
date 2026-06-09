import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getRazorpayInstance, calculateSplit } from "@/lib/razorpay";

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { programId } = await request.json();

    const { data: program } = await supabase
      .from("programs")
      .select("*, profiles!programs_trainer_id_fkey(id)")
      .eq("id", programId)
      .single();

    if (!program) {
      return NextResponse.json({ error: "Program not found" }, { status: 404 });
    }

    const { data: existing } = await supabase
      .from("program_purchases")
      .select("id")
      .eq("program_id", programId)
      .eq("buyer_id", user.id)
      .single();

    if (existing) {
      return NextResponse.json({ error: "Already purchased" }, { status: 400 });
    }

    const { commission, trainerAmount } = calculateSplit(program.price_inr);
    const razorpay = getRazorpayInstance();

    const order = await razorpay.orders.create({
      amount: program.price_inr * 100,
      currency: "INR",
      notes: {
        program_id: programId,
        buyer_id: user.id,
        trainer_id: program.trainer_id,
        commission: commission.toString(),
        trainer_amount: trainerAmount.toString(),
      },
    });

    return NextResponse.json({
      orderId: order.id,
      amount: program.price_inr,
      keyId: process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID,
      programName: program.name,
    });
  } catch (error) {
    console.error("Marketplace payment error:", error);
    return NextResponse.json(
      { error: "Failed to create order" },
      { status: 500 }
    );
  }
}

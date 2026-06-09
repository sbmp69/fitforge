import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { generateText, COACH_SYSTEM_PROMPT } from "@/lib/anthropic";

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();
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

    const { data: history } = await supabase
      .from("ai_chat_messages")
      .select("role, content")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(10);

    const context = (history || [])
      .reverse()
      .map((m) => `${m.role}: ${m.content}`)
      .join("\n");

    const userPrompt = context
      ? `Previous conversation:\n${context}\n\nUser: ${message}`
      : message;

    const reply = await generateText(COACH_SYSTEM_PROMPT, userPrompt);

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

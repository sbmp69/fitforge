import { createClient } from "@/lib/supabase/server";
import { AiCoachChat } from "@/components/coach/ai-coach-chat";

export default async function CoachPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  let initialMessages: { id: string; role: "user" | "assistant"; content: string; created_at: string }[] = [];

  if (user) {
    const { data } = await supabase
      .from("ai_chat_messages")
      .select("*")
      .eq("user_id", user.id)
      .order("created_at", { ascending: true })
      .limit(50);

    initialMessages = data || [];
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white">AI Coach</h1>
        <p className="mt-1 text-slate-400">
          Your personal fitness & nutrition advisor, powered by Claude
        </p>
      </div>
      <AiCoachChat initialMessages={initialMessages} />
    </div>
  );
}

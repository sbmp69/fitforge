import Link from "next/link";
import { Dumbbell, UtensilsCrossed, TrendingUp, MessageCircle, Crown } from "lucide-react";
import { getProfile } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { ProgressRing } from "@/components/ui/progress-ring";
import { StreakFire } from "@/components/ui/streak-fire";
import { AI_PLAN_LIMITS, TIER_LABELS } from "@/lib/utils";
import { format, subDays } from "date-fns";

export default async function DashboardPage() {
  const profile = await getProfile();
  const supabase = await createClient();

  const { data: recentLogs } = await supabase
    .from("progress_logs")
    .select("*")
    .eq("user_id", profile!.id)
    .order("log_date", { ascending: false })
    .limit(30);

  const { data: activeWorkout } = await supabase
    .from("workout_plans")
    .select("*")
    .eq("user_id", profile!.id)
    .eq("is_active", true)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  const { data: activeMeal } = await supabase
    .from("meal_plans")
    .select("*")
    .eq("user_id", profile!.id)
    .eq("is_active", true)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  let streak = 0;
  const today = new Date();
  for (let i = 0; i < 365; i++) {
    const date = format(subDays(today, i), "yyyy-MM-dd");
    const log = recentLogs?.find((l) => l.log_date === date);
    if (log?.workout_completed) streak++;
    else if (i > 0) break;
  }

  const weekLogs = recentLogs?.filter((l) => {
    const d = new Date(l.log_date);
    const weekAgo = subDays(today, 7);
    return d >= weekAgo;
  });

  const workoutDays = weekLogs?.filter((l) => l.workout_completed).length ?? 0;
  const weeklyProgress = Math.round((workoutDays / 7) * 100);

  const aiLimit = AI_PLAN_LIMITS[profile!.subscription_tier] ?? 3;
  const aiUsed = profile!.ai_plans_used_this_month;
  const aiRemaining =
    aiLimit === Infinity ? "∞" : Math.max(0, aiLimit - aiUsed);

  const quickActions = [
    { href: "/workout", icon: Dumbbell, label: "Today's Workout", color: "text-primary" },
    { href: "/meals", icon: UtensilsCrossed, label: "Meal Plan", color: "text-amber-400" },
    { href: "/progress", icon: TrendingUp, label: "Log Progress", color: "text-blue-400" },
    { href: "/coach", icon: MessageCircle, label: "AI Coach", color: "text-purple-400" },
  ];

  return (
    <div className="space-y-8">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">
            Hey, {profile?.full_name?.split(" ")[0] || "Athlete"} 👋
          </h1>
          <p className="mt-1 text-slate-400">
            {format(today, "EEEE, MMMM d")} — Let&apos;s crush it today
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="badge-primary">
            <Crown className="mr-1 h-3 w-3" />
            {TIER_LABELS[profile!.subscription_tier]}
          </span>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <div className="card flex items-center justify-center">
          <StreakFire streak={streak} />
        </div>
        <div className="card flex items-center justify-center">
          <ProgressRing progress={weeklyProgress} label="This week" />
        </div>
        <div className="card">
          <p className="text-sm text-slate-400">AI Plans Left</p>
          <p className="mt-1 text-3xl font-bold text-white">{aiRemaining}</p>
          <p className="text-xs text-slate-500">of {aiLimit === Infinity ? "∞" : aiLimit} this month</p>
        </div>
        <div className="card">
          <p className="text-sm text-slate-400">Workouts This Week</p>
          <p className="mt-1 text-3xl font-bold text-primary">{workoutDays}/7</p>
          <p className="text-xs text-slate-500">days completed</p>
        </div>
      </div>

      <div>
        <h2 className="mb-4 text-lg font-semibold text-white">Quick Actions</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {quickActions.map(({ href, icon: Icon, label, color }) => (
            <Link
              key={href}
              href={href}
              className="card flex items-center gap-4 transition-colors hover:border-primary/30"
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-navy-700">
                <Icon className={`h-6 w-6 ${color}`} />
              </div>
              <span className="font-medium text-white">{label}</span>
            </Link>
          ))}
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="card">
          <h3 className="mb-3 font-semibold text-white">Active Workout Plan</h3>
          {activeWorkout ? (
            <div>
              <p className="text-primary">{activeWorkout.title}</p>
              <p className="mt-1 text-sm text-slate-400">
                {activeWorkout.days_per_week} days/week · {activeWorkout.goal.replace("_", " ")}
              </p>
              <Link href="/workout" className="mt-3 inline-block text-sm text-primary hover:underline">
                View plan →
              </Link>
            </div>
          ) : (
            <div>
              <p className="text-slate-500">No active workout plan</p>
              <Link href="/workout" className="mt-2 inline-block text-sm text-primary hover:underline">
                Generate one with AI →
              </Link>
            </div>
          )}
        </div>
        <div className="card">
          <h3 className="mb-3 font-semibold text-white">Active Meal Plan</h3>
          {activeMeal ? (
            <div>
              <p className="text-amber-400">{activeMeal.title}</p>
              <p className="mt-1 text-sm text-slate-400">
                {activeMeal.calorie_target} kcal/day · {activeMeal.dietary_preference}
              </p>
              <Link href="/meals" className="mt-3 inline-block text-sm text-primary hover:underline">
                View plan →
              </Link>
            </div>
          ) : (
            <div>
              <p className="text-slate-500">No active meal plan</p>
              <Link href="/meals" className="mt-2 inline-block text-sm text-primary hover:underline">
                Generate one with AI →
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

"use client";

import { useState, useEffect } from "react";
import { RefreshCw, ChevronDown, ChevronUp, Timer } from "lucide-react";
import { Button } from "@/components/ui/button";
import { WorkoutTimer } from "@/components/workout/workout-timer";
import { GOAL_LABELS, LEVEL_LABELS } from "@/lib/utils";
import type { WorkoutPlan, WorkoutDay, FitnessGoal, FitnessLevel } from "@/types/database";

const EQUIPMENT_OPTIONS = [
  "Dumbbells",
  "Barbell",
  "Resistance Bands",
  "Pull-up Bar",
  "Kettlebell",
  "Cable Machine",
  "Bench",
  "Bodyweight Only",
];

export default function WorkoutPage() {
  const [plan, setPlan] = useState<WorkoutPlan | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [expandedDay, setExpandedDay] = useState<string | null>(null);
  const [activeRest, setActiveRest] = useState<number | null>(null);
  const [showForm, setShowForm] = useState(false);

  const [goal, setGoal] = useState<FitnessGoal>("build_muscle");
  const [level, setLevel] = useState<FitnessLevel>("intermediate");
  const [daysPerWeek, setDaysPerWeek] = useState(4);
  const [equipment, setEquipment] = useState<string[]>(["Dumbbells", "Bodyweight Only"]);

  useEffect(() => {
    fetch("/api/workout/active")
      .then((r) => r.json())
      .then((d) => d.plan && setPlan(d.plan))
      .catch(() => {});
  }, []);

  const toggleEquipment = (item: string) => {
    setEquipment((prev) =>
      prev.includes(item) ? prev.filter((e) => e !== item) : [...prev, item]
    );
  };

  const generatePlan = async (regenerateDay?: string) => {
    setLoading(true);
    setError("");

    try {
      const res = await fetch("/api/ai/workout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          goal,
          level,
          daysPerWeek,
          equipment,
          regenerateDay,
          existingPlan: plan?.plan_data,
        }),
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setPlan(data.plan);
      setShowForm(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Generation failed");
    } finally {
      setLoading(false);
    }
  };

  const days: WorkoutDay[] = plan?.plan_data?.days || [];

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">Workout Planner</h1>
          <p className="mt-1 text-slate-400">AI-generated personalized training plans</p>
        </div>
        <Button onClick={() => setShowForm(!showForm)} variant="secondary">
          {plan ? "New Plan" : "Generate Plan"}
        </Button>
      </div>

      {error && (
        <div className="rounded-xl bg-red-500/10 px-4 py-3 text-sm text-red-400">{error}</div>
      )}

      {showForm && (
        <div className="card space-y-5">
          <h2 className="text-lg font-semibold text-white">Plan Preferences</h2>
          <div className="grid gap-5 md:grid-cols-2">
            <div>
              <label className="label">Goal</label>
              <select className="input" value={goal} onChange={(e) => setGoal(e.target.value as FitnessGoal)}>
                {Object.entries(GOAL_LABELS).map(([k, v]) => (
                  <option key={k} value={k}>{v}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="label">Level</label>
              <select className="input" value={level} onChange={(e) => setLevel(e.target.value as FitnessLevel)}>
                {Object.entries(LEVEL_LABELS).map(([k, v]) => (
                  <option key={k} value={k}>{v}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="label">Days per Week: {daysPerWeek}</label>
              <input
                type="range"
                min={1}
                max={7}
                value={daysPerWeek}
                onChange={(e) => setDaysPerWeek(Number(e.target.value))}
                className="w-full accent-primary"
              />
            </div>
          </div>
          <div>
            <label className="label">Equipment Available</label>
            <div className="flex flex-wrap gap-2">
              {EQUIPMENT_OPTIONS.map((item) => (
                <button
                  key={item}
                  type="button"
                  onClick={() => toggleEquipment(item)}
                  className={`rounded-full px-3 py-1.5 text-sm transition-colors ${
                    equipment.includes(item)
                      ? "bg-primary text-white"
                      : "bg-navy-700 text-slate-400 hover:bg-navy-600"
                  }`}
                >
                  {item}
                </button>
              ))}
            </div>
          </div>
          <Button onClick={() => generatePlan()} loading={loading}>
            Generate Workout Plan
          </Button>
        </div>
      )}

      {activeRest !== null && (
        <WorkoutTimer
          restSeconds={activeRest}
          onComplete={() => setActiveRest(null)}
        />
      )}

      {plan && (
        <div className="space-y-4">
          {plan.plan_data?.summary && (
            <div className="card border-primary/20 bg-primary/5">
              <p className="text-sm text-slate-300">{plan.plan_data.summary}</p>
            </div>
          )}
          {days.map((day) => (
            <div key={day.day} className="card">
              <button
                className="flex w-full items-center justify-between"
                onClick={() => setExpandedDay(expandedDay === day.day ? null : day.day)}
              >
                <div className="text-left">
                  <h3 className="font-semibold text-white">{day.day}</h3>
                  <p className="text-sm text-primary">{day.focus}</p>
                </div>
                <div className="flex items-center gap-2">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={(e) => {
                      e.stopPropagation();
                      generatePlan(day.day);
                    }}
                  >
                    <RefreshCw className="h-4 w-4" />
                  </Button>
                  {expandedDay === day.day ? (
                    <ChevronUp className="h-5 w-5 text-slate-400" />
                  ) : (
                    <ChevronDown className="h-5 w-5 text-slate-400" />
                  )}
                </div>
              </button>

              {expandedDay === day.day && (
                <div className="mt-4 space-y-4 border-t border-slate-700/50 pt-4">
                  {day.warmup && (
                    <p className="text-sm text-slate-400">
                      <span className="text-slate-300">Warm-up:</span> {day.warmup}
                    </p>
                  )}
                  <div className="space-y-3">
                    {day.exercises.map((ex, i) => (
                      <div
                        key={i}
                        className="flex items-center justify-between rounded-xl bg-navy-700/50 px-4 py-3"
                      >
                        <div>
                          <p className="font-medium text-white">{ex.name}</p>
                          <p className="text-sm text-slate-400">
                            {ex.sets} sets × {ex.reps} reps
                          </p>
                          {ex.notes && (
                            <p className="text-xs text-slate-500">{ex.notes}</p>
                          )}
                        </div>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setActiveRest(ex.restSeconds)}
                        >
                          <Timer className="h-4 w-4" />
                          {ex.restSeconds}s
                        </Button>
                      </div>
                    ))}
                  </div>
                  {day.cooldown && (
                    <p className="text-sm text-slate-400">
                      <span className="text-slate-300">Cool-down:</span> {day.cooldown}
                    </p>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {!plan && !showForm && (
        <div className="card flex flex-col items-center justify-center py-16 text-center">
          <p className="text-slate-400">No workout plan yet</p>
          <Button className="mt-4" onClick={() => setShowForm(true)}>
            Generate Your First Plan
          </Button>
        </div>
      )}
    </div>
  );
}

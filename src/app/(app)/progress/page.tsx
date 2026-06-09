"use client";

import { useState, useEffect } from "react";
import { format } from "date-fns";
import { Button } from "@/components/ui/button";
import { WeightChart } from "@/components/progress/weight-chart";
import { WorkoutHeatmap } from "@/components/progress/workout-heatmap";
import { Sparkles } from "lucide-react";

interface ProgressLog {
  id: string;
  log_date: string;
  weight_kg: number | null;
  workout_completed: boolean;
  water_ml: number;
  sleep_hours: number | null;
}

export default function ProgressPage() {
  const [logs, setLogs] = useState<ProgressLog[]>([]);
  const [insight, setInsight] = useState("");
  const [loadingInsight, setLoadingInsight] = useState(false);
  const [saving, setSaving] = useState(false);
  const today = format(new Date(), "yyyy-MM-dd");

  const [form, setForm] = useState({
    weight_kg: "",
    workout_completed: false,
    water_ml: "2000",
    sleep_hours: "7",
  });

  useEffect(() => {
    fetch("/api/progress")
      .then((r) => r.json())
      .then((d) => setLogs(d.logs || []))
      .catch(() => {});
  }, []);

  const saveLog = async () => {
    setSaving(true);
    try {
      const res = await fetch("/api/progress", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          log_date: today,
          weight_kg: form.weight_kg ? parseFloat(form.weight_kg) : null,
          workout_completed: form.workout_completed,
          water_ml: parseInt(form.water_ml) || 0,
          sleep_hours: form.sleep_hours ? parseFloat(form.sleep_hours) : null,
        }),
      });
      const data = await res.json();
      if (data.log) {
        setLogs((prev) => {
          const filtered = prev.filter((l) => l.log_date !== today);
          return [data.log, ...filtered];
        });
      }
    } finally {
      setSaving(false);
    }
  };

  const getInsight = async () => {
    setLoadingInsight(true);
    try {
      const res = await fetch("/api/ai/insights", { method: "POST" });
      const data = await res.json();
      setInsight(data.insight?.insight_text || "");
    } finally {
      setLoadingInsight(false);
    }
  };

  const weightData = logs
    .filter((l) => l.weight_kg)
    .map((l) => ({ log_date: l.log_date, weight_kg: l.weight_kg! }))
    .reverse();

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white">Progress Tracker</h1>
        <p className="mt-1 text-slate-400">Log daily metrics and track your transformation</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="card space-y-4 lg:col-span-1">
          <h3 className="font-semibold text-white">Today&apos;s Log</h3>
          <div>
            <label className="label">Weight (kg)</label>
            <input
              type="number"
              step="0.1"
              className="input"
              value={form.weight_kg}
              onChange={(e) => setForm({ ...form, weight_kg: e.target.value })}
              placeholder="75.5"
            />
          </div>
          <div>
            <label className="label">Water Intake (ml)</label>
            <input
              type="number"
              className="input"
              value={form.water_ml}
              onChange={(e) => setForm({ ...form, water_ml: e.target.value })}
            />
          </div>
          <div>
            <label className="label">Sleep (hours)</label>
            <input
              type="number"
              step="0.5"
              className="input"
              value={form.sleep_hours}
              onChange={(e) => setForm({ ...form, sleep_hours: e.target.value })}
            />
          </div>
          <label className="flex cursor-pointer items-center gap-3">
            <input
              type="checkbox"
              checked={form.workout_completed}
              onChange={(e) => setForm({ ...form, workout_completed: e.target.checked })}
              className="h-5 w-5 rounded accent-primary"
            />
            <span className="text-sm text-slate-300">Workout completed today</span>
          </label>
          <Button onClick={saveLog} loading={saving} className="w-full">
            Save Today&apos;s Log
          </Button>
        </div>

        <div className="lg:col-span-2">
          <WeightChart data={weightData} />
        </div>
      </div>

      <WorkoutHeatmap logs={logs} />

      <div className="card">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-primary" />
            <h3 className="font-semibold text-white">Weekly AI Insights</h3>
          </div>
          <Button variant="secondary" size="sm" onClick={getInsight} loading={loadingInsight}>
            Generate Insights
          </Button>
        </div>
        {insight ? (
          <p className="text-sm leading-relaxed text-slate-300">{insight}</p>
        ) : (
          <p className="text-sm text-slate-500">
            Log your progress throughout the week, then generate AI-powered insights.
          </p>
        )}
      </div>

      <div className="card">
        <h3 className="mb-4 font-semibold text-white">Before & After Photos</h3>
        <div className="grid gap-4 sm:grid-cols-2">
          {["before", "after"].map((type) => (
            <div
              key={type}
              className="flex h-48 flex-col items-center justify-center rounded-xl border-2 border-dashed border-slate-600 bg-navy-700/30"
            >
              <p className="mb-2 text-sm font-medium capitalize text-slate-400">{type} Photo</p>
              <label className="btn-secondary cursor-pointer text-xs">
                Upload
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={async (e) => {
                    const file = e.target.files?.[0];
                    if (!file) return;
                    const fd = new FormData();
                    fd.append("file", file);
                    fd.append("type", type);
                    await fetch("/api/progress/photos", { method: "POST", body: fd });
                  }}
                />
              </label>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

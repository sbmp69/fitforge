"use client";

import { cn } from "@/lib/utils";
import { format, subDays, eachDayOfInterval } from "date-fns";

interface WorkoutHeatmapProps {
  logs: { log_date: string; workout_completed: boolean }[];
}

export function WorkoutHeatmap({ logs }: WorkoutHeatmapProps) {
  const today = new Date();
  const start = subDays(today, 90);
  const days = eachDayOfInterval({ start, end: today });

  const logMap = new Map(
    logs.map((l) => [l.log_date, l.workout_completed])
  );

  const weeks: Date[][] = [];
  let currentWeek: Date[] = [];

  days.forEach((day, i) => {
    currentWeek.push(day);
    if (day.getDay() === 6 || i === days.length - 1) {
      weeks.push(currentWeek);
      currentWeek = [];
    }
  });

  return (
    <div className="card">
      <h3 className="mb-4 text-lg font-semibold text-white">Workout Activity</h3>
      <div className="flex gap-1 overflow-x-auto">
        {weeks.map((week, wi) => (
          <div key={wi} className="flex flex-col gap-1">
            {week.map((day) => {
              const key = format(day, "yyyy-MM-dd");
              const completed = logMap.get(key);
              return (
                <div
                  key={key}
                  title={`${format(day, "MMM d")}: ${completed ? "Workout done" : "No workout"}`}
                  className={cn(
                    "h-3 w-3 rounded-sm",
                    completed === true
                      ? "bg-primary"
                      : completed === false
                        ? "bg-slate-700"
                        : "bg-slate-800"
                  )}
                />
              );
            })}
          </div>
        ))}
      </div>
      <div className="mt-3 flex items-center gap-2 text-xs text-slate-500">
        <span>Less</span>
        <div className="h-3 w-3 rounded-sm bg-slate-800" />
        <div className="h-3 w-3 rounded-sm bg-slate-700" />
        <div className="h-3 w-3 rounded-sm bg-primary" />
        <span>More</span>
      </div>
    </div>
  );
}

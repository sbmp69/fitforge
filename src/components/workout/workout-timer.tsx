"use client";

import { useState, useEffect, useCallback } from "react";
import { Play, Pause, RotateCcw, SkipForward } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface WorkoutTimerProps {
  restSeconds: number;
  onComplete?: () => void;
}

export function WorkoutTimer({ restSeconds, onComplete }: WorkoutTimerProps) {
  const [seconds, setSeconds] = useState(restSeconds);
  const [running, setRunning] = useState(false);
  const [totalRest] = useState(restSeconds);

  const reset = useCallback(() => {
    setSeconds(restSeconds);
    setRunning(false);
  }, [restSeconds]);

  useEffect(() => {
    if (!running || seconds <= 0) return;
    const id = setInterval(() => setSeconds((s) => s - 1), 1000);
    return () => clearInterval(id);
  }, [running, seconds]);

  useEffect(() => {
    if (seconds === 0 && running) {
      setRunning(false);
      onComplete?.();
    }
  }, [seconds, running, onComplete]);

  const progress = ((totalRest - seconds) / totalRest) * 100;
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;

  return (
    <div className="card flex flex-col items-center gap-4">
      <p className="text-sm font-medium text-slate-400">Rest Timer</p>
      <div className="relative flex h-32 w-32 items-center justify-center">
        <svg className="absolute h-full w-full -rotate-90" viewBox="0 0 100 100">
          <circle
            cx="50"
            cy="50"
            r="45"
            fill="none"
            stroke="currentColor"
            strokeWidth="6"
            className="text-slate-700"
          />
          <circle
            cx="50"
            cy="50"
            r="45"
            fill="none"
            stroke="currentColor"
            strokeWidth="6"
            strokeLinecap="round"
            className={cn(
              "transition-all duration-1000",
              seconds <= 5 ? "text-red-400" : "text-primary"
            )}
            strokeDasharray={`${progress * 2.827} 283`}
          />
        </svg>
        <span
          className={cn(
            "text-3xl font-bold tabular-nums",
            seconds <= 5 ? "text-red-400" : "text-white"
          )}
        >
          {mins}:{secs.toString().padStart(2, "0")}
        </span>
      </div>
      <div className="flex gap-2">
        <Button
          variant="secondary"
          size="sm"
          onClick={() => setRunning(!running)}
        >
          {running ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
          {running ? "Pause" : "Start"}
        </Button>
        <Button variant="ghost" size="sm" onClick={reset}>
          <RotateCcw className="h-4 w-4" />
        </Button>
        <Button variant="ghost" size="sm" onClick={() => setSeconds(0)}>
          <SkipForward className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
